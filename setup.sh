#!/usr/bin/env bash
# Installs Nginx and starts two Clipstr instances (ports 8001 and 8002). Run with: sudo ./setup.sh (safe to re-run)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./setup.sh" >&2; exit 1; }
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq nginx python3-venv git curl >/dev/null
./teardown.sh >/dev/null 2>&1 || true

id clipstr >/dev/null 2>&1 || useradd --system --home /opt/clipstr --shell /usr/sbin/nologin clipstr
if [ ! -d /opt/clipstr/.git ]; then rm -rf /opt/clipstr; git clone -q https://github.com/professordiogodev/clipstr /opt/clipstr; fi
if [ ! -x /opt/clipstr/venv/bin/uvicorn ]; then python3 -m venv /opt/clipstr/venv; /opt/clipstr/venv/bin/pip install -q -r /opt/clipstr/requirements.txt; fi
chmod -R a+rX /opt/clipstr

mkdir -p /var/lib/clipstr-lab
cat > /var/lib/clipstr-lab/instance.sh <<'S'
#!/usr/bin/env bash
# usage: instance.sh start|stop a|b
port=$([ "$2" = a ] && echo 8001 || echo 8002)
pidf=/var/lib/clipstr-lab/$2.pid
case "$1" in
  start) cd /opt/clipstr; APP_VERSION="instance-$2" setsid nohup sudo -u clipstr -E env APP_VERSION="instance-$2" /opt/clipstr/venv/bin/uvicorn api.main:app --host 127.0.0.1 --port $port >/var/lib/clipstr-lab/$2.log 2>&1 & ;;
  stop) pkill -f "uvicorn api.main:app --host 127.0.0.1 --port $port" || true ;;
esac
S
chmod +x /var/lib/clipstr-lab/instance.sh
/var/lib/clipstr-lab/instance.sh start a; /var/lib/clipstr-lab/instance.sh start b
grep -q clipstr.test /etc/hosts || echo "127.0.0.1 clipstr.test www.clipstr.test" >> /etc/hosts
rm -f /etc/nginx/sites-enabled/default; systemctl reload nginx 2>/dev/null || nginx -s reload 2>/dev/null || true
sleep 3
echo "Instance A: $(curl -s localhost:8001/healthz)"
echo "Instance B: $(curl -s localhost:8002/healthz)"
echo
echo "Nginx is installed and has no site configured. Open README.md and start Part 1."
