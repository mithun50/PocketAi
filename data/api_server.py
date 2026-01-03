#!/usr/bin/env python3
import http.server
import socketserver
import json
import subprocess
import os
import sys
import time
import signal
import traceback
import threading
from urllib.parse import urlparse, parse_qs
from datetime import datetime

PORT = int(os.environ.get('API_PORT', 8081))
POCKETAI_ROOT = os.environ.get('POCKETAI_ROOT', '/data/data/com.termux/files/home/ALLM/pocketai')

# =============================================================================
# Logging
# =============================================================================
def log(level, msg):
    """Thread-safe logging with timestamp"""
    ts = datetime.now().strftime('%H:%M:%S')
    print(f"[{ts}] [{level}] {msg}", flush=True)

def log_info(msg): log("INFO", msg)
def log_warn(msg): log("WARN", msg)
def log_error(msg): log("ERROR", msg)
def log_debug(msg): log("DEBUG", msg)

# =============================================================================
# Request tracking
# =============================================================================
_request_count = 0
_active_streams = 0
_lock = threading.Lock()
_server_start_time = time.time()

def get_request_id():
    global _request_count
    with _lock:
        _request_count += 1
        return _request_count

# =============================================================================
# Cache for expensive operations
# =============================================================================
_status_cache = {
    'model': None,
    'version': None,
    'last_update': 0,
    'cache_ttl': 30
}

_models_cache = {
    'catalog': None,
    'installed': None,
    'installed_time': 0,
    'catalog_ttl': 300,  # 5 min for catalog (rarely changes)
    'installed_ttl': 10  # 10 sec for installed (can change)
}

# Model catalog - hardcoded for instant access
MODEL_CATALOG = {
    'qwen3': {'desc': 'Qwen3 0.6B ⭐NEW 2025', 'size': '400MB', 'ram': '512MB'},
    'llama3.2': {'desc': 'Llama 3.2 1B (Latest)', 'size': '700MB', 'ram': '1GB'},
    'qwen2': {'desc': 'Qwen2.5 0.5B (Smart)', 'size': '400MB', 'ram': '512MB'},
    'qwen': {'desc': 'Qwen 0.5B Chat', 'size': '395MB', 'ram': '512MB'},
    'smollm2': {'desc': 'SmolLM2 360M (Tiny)', 'size': '270MB', 'ram': '400MB'},
    'smollm2-1b': {'desc': 'SmolLM2 1.7B (Better)', 'size': '1.0GB', 'ram': '1.5GB'},
    'qwen2-1b': {'desc': 'Qwen2.5 1.5B (Smartest)', 'size': '1.0GB', 'ram': '1.2GB'},
    'tinyllama': {'desc': 'TinyLlama 1.1B Chat', 'size': '670MB', 'ram': '1GB'},
    'llama3.2-3b': {'desc': 'Llama 3.2 3B (Best)', 'size': '2.0GB', 'ram': '2.5GB'},
    'gemma2b': {'desc': 'Gemma 2B (Google)', 'size': '1.4GB', 'ram': '2GB'},
    'phi2': {'desc': 'Phi-2 2.7B (Microsoft)', 'size': '1.6GB', 'ram': '3GB'},
    'qwen2-3b': {'desc': 'Qwen2.5 3B (Best)', 'size': '2.0GB', 'ram': '3GB'},
}

def get_models_dir():
    """Get models directory path"""
    return os.path.join(POCKETAI_ROOT, 'models')

def get_config_file():
    """Get config file path"""
    return os.path.join(POCKETAI_ROOT, 'data', 'config')

def get_active_model_fast():
    """Get active model from config file directly (no shell)"""
    try:
        config_file = get_config_file()
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                for line in f:
                    if line.startswith('active_model='):
                        return line.strip().split('=', 1)[1]
    except:
        pass
    return ''

def set_active_model_fast(model_path):
    """Set active model in config file directly (no shell)"""
    try:
        config_file = get_config_file()
        lines = []
        found = False

        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                for line in f:
                    if line.startswith('active_model='):
                        lines.append(f'active_model={model_path}\n')
                        found = True
                    else:
                        lines.append(line)

        if not found:
            lines.append(f'active_model={model_path}\n')

        with open(config_file, 'w') as f:
            f.writelines(lines)
        return True
    except Exception as e:
        log_error(f"set_active_model_fast failed: {e}")
        return False

def get_installed_models_fast():
    """Get installed models using Python (no shell)"""
    now = time.time()

    # Return cache if fresh
    if (_models_cache['installed'] is not None and
        now - _models_cache['installed_time'] < _models_cache['installed_ttl']):
        return _models_cache['installed']

    models = []
    models_dir = get_models_dir()
    active = get_active_model_fast()

    try:
        if os.path.isdir(models_dir):
            for f in os.listdir(models_dir):
                if f.endswith('.gguf'):
                    filepath = os.path.join(models_dir, f)
                    try:
                        size_bytes = os.path.getsize(filepath)
                        if size_bytes >= 1024 * 1024 * 1024:
                            size_str = f"{size_bytes / (1024*1024*1024):.1f}GB"
                        else:
                            size_str = f"{size_bytes / (1024*1024):.0f}MB"
                    except:
                        size_str = "?"

                    models.append({
                        'name': f,
                        'size': size_str,
                        'active': filepath == active or f in active
                    })
    except Exception as e:
        log_error(f"get_installed_models_fast failed: {e}")

    _models_cache['installed'] = models
    _models_cache['installed_time'] = now
    return models

def activate_model_fast(model_name):
    """Activate model using Python (no shell)"""
    models_dir = get_models_dir()

    try:
        if os.path.isdir(models_dir):
            for f in os.listdir(models_dir):
                if f.endswith('.gguf') and model_name.lower() in f.lower():
                    filepath = os.path.join(models_dir, f)
                    if set_active_model_fast(filepath):
                        # Invalidate caches
                        _status_cache['last_update'] = 0
                        _models_cache['installed_time'] = 0
                        return True, f"Activated: {f}"
                    else:
                        return False, "Failed to update config"
        return False, f"Model not found: {model_name}"
    except Exception as e:
        return False, str(e)

def get_cached_status():
    """Get cached status or refresh if stale - uses fast Python methods"""
    try:
        now = time.time()
        if now - _status_cache['last_update'] > _status_cache['cache_ttl']:
            # Use fast Python method instead of shell
            model = get_active_model_fast()
            _status_cache['model'] = os.path.basename(model) if model else ''
            _status_cache['version'] = os.environ.get('VERSION', '2.0')
            _status_cache['last_update'] = now
        return _status_cache['model'], _status_cache['version']
    except Exception as e:
        log_error(f"get_cached_status failed: {e}")
        return _status_cache.get('model', ''), _status_cache.get('version', '')

# =============================================================================
# Command execution
# =============================================================================
def run_cmd(cmd, timeout=30):
    """Run shell command with optional timeout and error handling"""
    process = None
    try:
        process = subprocess.Popen(
            f'source {POCKETAI_ROOT}/core/engine.sh && {cmd}',
            shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, executable='/data/data/com.termux/files/usr/bin/bash',
            preexec_fn=os.setsid  # Create new process group for clean kill
        )
        # timeout=None means wait forever
        stdout, stderr = process.communicate(timeout=timeout)
        return stdout.strip(), process.returncode == 0
    except subprocess.TimeoutExpired:
        log_error(f"Command timed out after {timeout}s: {cmd[:50]}...")
        if process:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except:
                pass
            try:
                process.kill()
                process.wait(timeout=1)
            except:
                pass
        return f"Command timed out after {timeout}s", False
    except Exception as e:
        log_error(f"run_cmd failed: {e}")
        if process:
            try:
                process.kill()
            except:
                pass
        return str(e), False

def run_cmd_async(cmd, timeout=30, callback=None):
    """Run command in background thread with timeout"""
    result = {'output': '', 'success': False, 'done': False}

    def worker():
        try:
            out, ok = run_cmd(cmd, timeout=timeout)
            result['output'] = out
            result['success'] = ok
        except Exception as e:
            result['output'] = str(e)
            result['success'] = False
        finally:
            result['done'] = True
            if callback:
                callback(result)

    thread = threading.Thread(target=worker, daemon=True)
    thread.start()
    return result, thread

def kill_process_tree(pid):
    """Kill process and all its children"""
    try:
        # Kill entire process group
        os.killpg(pid, signal.SIGTERM)
        time.sleep(0.5)
        os.killpg(pid, signal.SIGKILL)
    except (OSError, ProcessLookupError):
        pass

    # Also try to kill any leftover llamafile processes
    try:
        subprocess.run(['pkill', '-f', 'llamafile.*-m'], timeout=2, capture_output=True)
    except:
        pass

def run_cmd_stream(cmd, timeout=300):
    """Run shell command and yield output in real-time using PTY"""
    import pty
    import select

    global _active_streams
    master_fd = None
    slave_fd = None
    process = None
    start_time = time.time()

    try:
        with _lock:
            _active_streams += 1
        log_info(f"Stream started (active: {_active_streams})")

        master_fd, slave_fd = pty.openpty()

        # Use process group so we can kill all children
        process = subprocess.Popen(
            f'source {POCKETAI_ROOT}/core/engine.sh && {cmd}',
            shell=True,
            stdout=slave_fd,
            stderr=slave_fd,  # Merge stderr to stdout
            executable='/data/data/com.termux/files/usr/bin/bash',
            preexec_fn=os.setsid  # Create new process group
        )
        os.close(slave_fd)
        slave_fd = None

        token_count = 0
        last_data_time = time.time()

        while True:
            now = time.time()

            # Check overall timeout
            if now - start_time > timeout:
                log_warn(f"Stream timeout after {timeout}s")
                break

            # Check idle timeout (no data for 60s)
            if now - last_data_time > 60:
                log_warn(f"Stream idle timeout (no data for 60s)")
                break

            ready, _, _ = select.select([master_fd], [], [], 0.5)
            if ready:
                try:
                    data = os.read(master_fd, 4096)  # Read larger chunks
                    if data:
                        token_count += len(data)
                        last_data_time = now
                        yield data.decode('utf-8', errors='replace')
                    else:
                        log_debug("EOF on master_fd")
                        break
                except OSError as e:
                    log_debug(f"OSError in stream read: {e}")
                    break
            else:
                # Check if process exited
                if process.poll() is not None:
                    # Drain any remaining data
                    try:
                        while True:
                            ready, _, _ = select.select([master_fd], [], [], 0.1)
                            if ready:
                                data = os.read(master_fd, 4096)
                                if data:
                                    yield data.decode('utf-8', errors='replace')
                                else:
                                    break
                            else:
                                break
                    except OSError:
                        pass
                    break

        duration = time.time() - start_time
        log_info(f"Stream complete: {token_count} chars in {duration:.1f}s")

    except GeneratorExit:
        log_warn("Stream generator closed by client")
    except Exception as e:
        log_error(f"Stream error: {e}\n{traceback.format_exc()}")
        yield f"[Error: {str(e)}]"
    finally:
        # Aggressive cleanup
        log_debug("Stream cleanup starting")
        with _lock:
            _active_streams -= 1

        # Close file descriptors first
        if slave_fd is not None:
            try:
                os.close(slave_fd)
            except:
                pass
        if master_fd is not None:
            try:
                os.close(master_fd)
            except:
                pass

        # Kill process tree
        if process is not None:
            try:
                if process.poll() is None:
                    log_debug(f"Killing process tree {process.pid}")
                    kill_process_tree(process.pid)
                process.wait(timeout=1)
            except:
                pass

        log_debug("Stream cleanup complete")

class APIHandler(http.server.BaseHTTPRequestHandler):
    # Suppress default logging
    def log_message(self, format, *args):
        pass

    # Socket-level timeout for all requests
    timeout = 30

    def send_json(self, data, status=200):
        try:
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        except (BrokenPipeError, ConnectionResetError) as e:
            log_debug(f"Client disconnected during JSON response: {e}")
        except Exception as e:
            log_error(f"send_json error: {e}")

    def send_error_json(self, message, status=500):
        """Send error response as JSON"""
        log_error(f"HTTP {status}: {message}")
        self.send_json({'error': message, 'status': status}, status)

    def send_sse_stream(self, generator):
        """Send Server-Sent Events stream with robust error handling"""
        req_id = get_request_id()
        log_info(f"[REQ-{req_id}] SSE stream started")
        buffer = ""
        token_count = 0

        try:
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('Connection', 'keep-alive')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('X-Request-ID', str(req_id))
            self.end_headers()

            for char in generator:
                buffer += char
                token_count += 1
                try:
                    self.wfile.write(f"data: {json.dumps({'token': char})}\n\n".encode())
                    self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError):
                    log_warn(f"[REQ-{req_id}] Client disconnected during stream")
                    return

            # Send completion event
            self.wfile.write(f"data: {json.dumps({'done': True, 'full_response': buffer})}\n\n".encode())
            self.wfile.flush()
            log_info(f"[REQ-{req_id}] SSE complete: {token_count} tokens")

        except (BrokenPipeError, ConnectionResetError) as e:
            log_warn(f"[REQ-{req_id}] Client disconnected: {e}")
        except Exception as e:
            log_error(f"[REQ-{req_id}] SSE error: {e}\n{traceback.format_exc()}")
            try:
                self.wfile.write(f"data: {json.dumps({'error': str(e)})}\n\n".encode())
                self.wfile.flush()
            except:
                pass

    def do_OPTIONS(self):
        self.send_json({})

    def do_GET(self):
        global _active_streams
        req_id = get_request_id()
        path = urlparse(self.path).path

        try:
            if path == '/api/health':
                self.send_json({'healthy': True, 'active_streams': _active_streams, 'uptime': time.time() - _server_start_time})

            elif path == '/api/reset':
                # Kill any stuck llamafile processes
                log_warn(f"[REQ-{req_id}] Reset requested - killing stuck processes")
                try:
                    subprocess.run(['pkill', '-9', '-f', 'llamafile'], timeout=5, capture_output=True)
                except:
                    pass
                # Reset counters
                with _lock:
                    _active_streams = 0
                _status_cache['last_update'] = 0
                self.send_json({'reset': True, 'message': 'Killed stuck processes'})

            elif path == '/api/status':
                model_name, version = get_cached_status()
                self.send_json({'status': 'ok', 'version': version, 'model': model_name})

            elif path == '/api/models':
                # Instant - uses hardcoded catalog
                models = [
                    {'name': name, 'description': info['desc'], 'size': info['size'], 'ram': info['ram']}
                    for name, info in MODEL_CATALOG.items()
                ]
                self.send_json({'models': models})

            elif path == '/api/models/installed':
                # Fast - uses Python file operations with caching
                models = get_installed_models_fast()
                self.send_json({'models': models})

            elif path == '/api/config':
                # Fast: read config file directly with Python
                config = {}
                try:
                    config_file = get_config_file()
                    if os.path.exists(config_file):
                        with open(config_file, 'r') as f:
                            for line in f:
                                line = line.strip()
                                if '=' in line and not line.startswith('#'):
                                    k, v = line.split('=', 1)
                                    config[k] = v
                except Exception as e:
                    log_error(f"Config read failed: {e}")
                self.send_json(config)

            else:
                self.send_json({'error': 'Not found'}, 404)

        except Exception as e:
            log_error(f"[REQ-{req_id}] GET {path} error: {e}\n{traceback.format_exc()}")
            self.send_error_json(str(e), 500)

    def do_POST(self):
        req_id = get_request_id()
        path = urlparse(self.path).path

        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode() if content_length > 0 else '{}'

            try:
                data = json.loads(body)
            except json.JSONDecodeError as e:
                log_warn(f"[REQ-{req_id}] Invalid JSON: {e}")
                data = {}

            if path == '/api/models/install':
                model = data.get('model', '')
                log_info(f"[REQ-{req_id}] Installing model: {model}")
                # No timeout - let it complete
                out, ok = run_cmd(f'model_install "{model}"', timeout=None)
                self.send_json({'success': ok, 'message': out or f'Model {model} installed'})

            elif path == '/api/models/remove':
                model = data.get('model', '')
                log_info(f"[REQ-{req_id}] Removing model: {model}")
                # No timeout - let it complete
                out, ok = run_cmd(f'model_remove "{model}"', timeout=None)
                self.send_json({'success': ok, 'message': out or f'Model {model} removed'})

            elif path == '/api/models/use':
                model = data.get('model', '')
                log_info(f"[REQ-{req_id}] Activating model: {model}")
                # Fast activation using Python (no shell) - instant!
                ok, msg = activate_model_fast(model)
                log_info(f"[REQ-{req_id}] Activation result: {ok} - {msg}")
                self.send_json({'success': ok, 'message': msg})

            elif path == '/api/chat':
                message = data.get('message', '')
                max_tokens = data.get('max_tokens', '')
                log_info(f"[REQ-{req_id}] Chat request (blocking): {len(message)} chars")
                # Escape message for shell
                message = message.replace('"', '\\"').replace('$', '\\$')
                if max_tokens:
                    out, ok = run_cmd(f'infer "{message}" "{max_tokens}"', timeout=120)
                else:
                    out, ok = run_cmd(f'infer "{message}"', timeout=120)
                log_info(f"[REQ-{req_id}] Chat complete: {len(out)} chars")
                self.send_json({'response': out})

            elif path == '/api/chat/stream':
                message = data.get('message', '')
                log_info(f"[REQ-{req_id}] Chat request (streaming): {len(message)} chars")
                # Escape message for shell
                message = message.replace('"', '\\"').replace('$', '\\$').replace('`', '\\`')
                self.send_sse_stream(run_cmd_stream(f'infer_stream "{message}"'))

            elif path == '/api/config':
                key = data.get('key', '')
                value = data.get('value', '')
                log_info(f"[REQ-{req_id}] Config set: {key}={value}")
                # Fast: use Python file operations
                try:
                    config_file = get_config_file()
                    lines = []
                    found = False
                    if os.path.exists(config_file):
                        with open(config_file, 'r') as f:
                            for line in f:
                                if line.startswith(f'{key}='):
                                    lines.append(f'{key}={value}\n')
                                    found = True
                                else:
                                    lines.append(line)
                    if not found:
                        lines.append(f'{key}={value}\n')
                    with open(config_file, 'w') as f:
                        f.writelines(lines)
                    self.send_json({'success': True})
                except Exception as e:
                    log_error(f"Config set failed: {e}")
                    self.send_json({'success': False, 'error': str(e)})

            else:
                self.send_json({'error': 'Not found'}, 404)

        except Exception as e:
            log_error(f"[REQ-{req_id}] POST {path} error: {e}\n{traceback.format_exc()}")
            self.send_error_json(str(e), 500)

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
                pass
        else:
            self.send_json({'error': 'Not found'}, 404)

class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    """Handle each request in a new thread for better concurrency"""
    daemon_threads = True
    allow_reuse_address = True
    request_queue_size = 20  # Limit pending connections
    block_on_close = False   # Don't block when closing

def shutdown_handler(signum, frame):
    """Graceful shutdown on SIGINT/SIGTERM"""
    log_info(f"Received signal {signum}, shutting down...")
    sys.exit(0)

if __name__ == '__main__':
    # Register signal handlers
    signal.signal(signal.SIGINT, shutdown_handler)
    signal.signal(signal.SIGTERM, shutdown_handler)

    Handler = CombinedHandler if os.environ.get('SERVE_WEB') else APIHandler
    mode = 'API + Web' if os.environ.get('SERVE_WEB') else 'API only'

    log_info("=" * 50)
    log_info(f"PocketAI API Server v2.0")
    log_info(f"Port: {PORT} | Mode: {mode}")
    log_info("=" * 50)

    try:
        with ThreadedTCPServer(('', PORT), Handler) as httpd:
            log_info(f"Server ready - listening on port {PORT}")
            httpd.serve_forever()
    except OSError as e:
        log_error(f"Failed to start server: {e}")
        sys.exit(1)
    except Exception as e:
        log_error(f"Server error: {e}\n{traceback.format_exc()}")
        sys.exit(1)
