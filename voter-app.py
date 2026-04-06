from flask import Flask, jsonify, request
import os, sys, redis

app = Flask(__name__)

# --- Redis config ---
REDIS_HOST = os.getenv('REDIS_HOST', 'host.docker.internal')
REDIS_PORT = int(os.getenv('REDIS_PORT', '7001'))
POLL_KEY = 'poll_votes'
VALID_OPTIONS = ['Python', 'JavaScript', 'Go', 'Rust']

# Cache the connection to the correct cluster node
_redis = None

def get_redis():
    """Connect to the Redis cluster node that owns our POLL_KEY.
    Handles MOVED redirects since cluster nodes advertise 127.0.0.1
    but we need to connect via host.docker.internal."""
    global _redis
    if _redis:
        try:
            _redis.ping()
            return _redis
        except Exception:
            _redis = None
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    try:
        r.hgetall(POLL_KEY)
        _redis = r
        return r
    except redis.exceptions.ResponseError as e:
        if 'MOVED' in str(e):
            # MOVED 12345 127.0.0.1:7003 -> reconnect to host.docker.internal:7003
            target_port = int(str(e).split(':')[-1])
            r = redis.Redis(host=REDIS_HOST, port=target_port, decode_responses=True)
            _redis = r
            return r
        raise

def init_poll():
    """Seed default poll options in Redis if they don't exist yet."""
    r = get_redis()
    for opt in VALID_OPTIONS:
        if not r.hexists(POLL_KEY, opt):
            r.hset(POLL_KEY, opt, 0)
    print(f"Redis connected at {REDIS_HOST}:{r.connection_pool.connection_kwargs['port']}")

# --- Routes ---
@app.route('/')
def status():
    return f"Voter DB is LIVE on pod: {os.getenv('HOSTNAME')}"

@app.route('/poll', methods=['GET', 'POST'])
def poll():
    pod = os.getenv('HOSTNAME', 'unknown')
    r = get_redis()
    if request.method == 'POST':
        vote = request.args.get('vote') or request.form.get('vote', '')
        if vote in VALID_OPTIONS:
            r.hincrby(POLL_KEY, vote, 1)
            results = {k: int(v) for k, v in r.hgetall(POLL_KEY).items()}
            return jsonify(pod=pod, voted_for=vote, poll=results)
        return jsonify(pod=pod, error=f"Invalid option: {vote}", options=VALID_OPTIONS), 400
    # GET — return shared results from Redis
    results = {k: int(v) for k, v in r.hgetall(POLL_KEY).items()}
    return jsonify(pod=pod, poll=results)

@app.route('/crash')
def crash():
    print("Simulating a fatal error...")
    sys.exit(1)  # This kills the process, triggering K8s to restart it

if __name__ == "__main__":
    init_poll()
    app.run(host='0.0.0.0', port=5000)