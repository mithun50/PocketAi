#!/usr/bin/env python3
import http.server
import socketserver
import json
import subprocess
import os
import re
from urllib.parse import urlparse, parse_qs

PORT = int(os.environ.get('API_PORT', 8081))
POCKETAI_ROOT = os.environ.get('POCKETAI_ROOT', '/data/data/com.termux/files/home/ALLM/pocketai')

def run_cmd(cmd):
    """Run shell command and return output"""
    try:
        result = subprocess.run(
            f'source {POCKETAI_ROOT}/core/engine.sh && {cmd}',
            shell=True, capture_output=True, text=True,
            executable='/data/data/com.termux/files/usr/bin/bash'
        )
        return result.stdout.strip(), result.returncode == 0
    except Exception as e:
        return str(e), False

class APIHandler(http.server.BaseHTTPRequestHandler):
    def send_json(self, data, status=200):
        try:
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        except BrokenPipeError:
            pass  # Client disconnected, ignore
        except ConnectionResetError:
            pass  # Connection reset, ignore

    def do_OPTIONS(self):
        self.send_json({})

    def do_GET(self):
        path = urlparse(self.path).path

        if path == '/api/health':
            self.send_json({'healthy': True})

        elif path == '/api/status':
            model, _ = run_cmd('config_get active_model')
            version, _ = run_cmd('echo $VERSION')
            model_name = os.path.basename(model) if model else ''
            self.send_json({'status': 'ok', 'version': version, 'model': model_name})

        elif path == '/api/models':
            out, _ = run_cmd('for n in "${!MODEL_CATALOG[@]}"; do echo "$n|${MODEL_CATALOG[$n]}"; done')
            models = []
            for line in out.split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    name = parts[0]
                    info = parts[1].split('|') if len(parts) > 1 else ['', '', '', '']
                    models.append({
                        'name': name,
                        'description': info[0] if len(info) > 0 else '',
                        'size': info[1] if len(info) > 1 else '',
                        'ram': info[2] if len(info) > 2 else ''
                    })
            self.send_json({'models': models})

        elif path == '/api/models/installed':
            out, _ = run_cmd('for f in "$MODELS_DIR"/*.gguf; do [ -f "$f" ] && echo "$f"; done')
            active, _ = run_cmd('config_get active_model')
            models = []
            for f in out.split('\n'):
                if f and f.endswith('.gguf'):
                    size_out, _ = run_cmd(f'du -h "{f}" | cut -f1')
                    models.append({
                        'name': os.path.basename(f),
                        'size': size_out,
                        'active': f == active
                    })
            self.send_json({'models': models})

        elif path == '/api/config':
            out, _ = run_cmd('cat "$CONFIG_FILE" 2>/dev/null || echo ""')
            config = {}
            for line in out.split('\n'):
                if '=' in line and not line.startswith('#'):
                    k, v = line.split('=', 1)
                    config[k] = v
            self.send_json(config)

        else:
            self.send_json({'error': 'Not found'}, 404)

    def do_POST(self):
        path = urlparse(self.path).path
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode() if content_length > 0 else '{}'

        try:
            data = json.loads(body)
        except:
            data = {}

        if path == '/api/models/install':
            model = data.get('model', '')
            out, ok = run_cmd(f'model_install "{model}"')
            self.send_json({'success': ok, 'message': out or f'Model {model} installed'})

        elif path == '/api/models/remove':
            model = data.get('model', '')
            out, ok = run_cmd(f'model_remove "{model}"')
            self.send_json({'success': ok, 'message': out or f'Model {model} removed'})

        elif path == '/api/models/use':
            model = data.get('model', '')
            out, ok = run_cmd(f'model_activate "{model}"')
            self.send_json({'success': ok, 'message': out or f'Model {model} activated'})

        elif path == '/api/chat':
            message = data.get('message', '')
            out, ok = run_cmd(f'infer "{message}"')
            self.send_json({'response': out})

        elif path == '/api/config':
            key = data.get('key', '')
            value = data.get('value', '')
            run_cmd(f'config_set "{key}" "{value}"')
            self.send_json({'success': True})

        else:
            self.send_json({'error': 'Not found'}, 404)

    def log_message(self, format, *args):
        pass  # Suppress logging

class CombinedHandler(APIHandler):
    """Serve both API and static web files"""
    def do_GET(self):
        path = urlparse(self.path).path

        # API routes
        if path.startswith('/api/'):
            return super().do_GET()

        # Static files
        web_dir = os.path.join(POCKETAI_ROOT, 'web')
        if path == '/' or path == '':
            path = '/index.html'

        file_path = os.path.join(web_dir, path.lstrip('/'))

        if os.path.isfile(file_path):
            try:
                self.send_response(200)
                if file_path.endswith('.html'):
                    self.send_header('Content-Type', 'text/html')
                elif file_path.endswith('.js'):
                    self.send_header('Content-Type', 'application/javascript')
                elif file_path.endswith('.css'):
                    self.send_header('Content-Type', 'text/css')
                self.end_headers()
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            except (BrokenPipeError, ConnectionResetError):
                pass  # Client disconnected, ignore
        else:
            self.send_json({'error': 'Not found'}, 404)

if __name__ == '__main__':
    Handler = CombinedHandler if os.environ.get('SERVE_WEB') else APIHandler
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(('', PORT), Handler) as httpd:
        mode = 'API + Web' if os.environ.get('SERVE_WEB') else 'API only'
        print(f'Server running on port {PORT} ({mode})')
        httpd.serve_forever()
