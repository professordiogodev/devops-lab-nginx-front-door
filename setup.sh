#!/usr/bin/env bash
# Installs Nginx and starts two Clippy instances (ports 8001 and 8002). Run with: sudo ./setup.sh (safe to re-run)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./setup.sh" >&2; exit 1; }
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq nginx python3-venv git curl >/dev/null
./teardown.sh >/dev/null 2>&1 || true

id clippy >/dev/null 2>&1 || useradd --system --home /opt/clippy --shell /usr/sbin/nologin clippy
if [ ! -d /opt/clippy/.git ]; then rm -rf /opt/clippy; git clone -q https://github.com/professordiogodev/clippy /opt/clippy; fi
if [ ! -x /opt/clippy/venv/bin/uvicorn ]; then python3 -m venv /opt/clippy/venv; /opt/clippy/venv/bin/pip install -q -r /opt/clippy/requirements.txt; fi
chmod -R a+rX /opt/clippy

mkdir -p /var/lib/clippy-lab
cat > /var/lib/clippy-lab/instance.sh <<'S'
#!/usr/bin/env bash
# usage: instance.sh start|stop a|b
port=$([ "$2" = a ] && echo 8001 || echo 8002)
pidf=/var/lib/clippy-lab/$2.pid
case "$1" in
  start) cd /opt/clippy; APP_VERSION="instance-$2" setsid nohup sudo -u clippy -E env APP_VERSION="instance-$2" /opt/clippy/venv/bin/uvicorn api.main:app --host 127.0.0.1 --port $port >/var/lib/clippy-lab/$2.log 2>&1 & ;;
  stop) pkill -f "uvicorn api.main:app --host 127.0.0.1 --port $port" || true ;;
esac
S
chmod +x /var/lib/clippy-lab/instance.sh
/var/lib/clippy-lab/instance.sh start a; /var/lib/clippy-lab/instance.sh start b
grep -q clippy.test /etc/hosts || echo "127.0.0.1 clippy.test www.clippy.test" >> /etc/hosts
rm -f /etc/nginx/sites-enabled/default; systemctl reload nginx 2>/dev/null || nginx -s reload 2>/dev/null || true
sleep 3
echo "Instance A: $(curl -s localhost:8001/healthz)"
echo "Instance B: $(curl -s localhost:8002/healthz)"
echo
echo "Nginx is installed and has no site configured. Open README.md and start Part 1."
