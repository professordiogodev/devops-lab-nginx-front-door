#!/usr/bin/env bash
# Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
pkill -KILL -f 'uvicorn api.main:app --host 127.0.0.1' 2>/dev/null; sleep 1
rm -f /etc/nginx/sites-enabled/clippy* /etc/nginx/sites-available/clippy* /etc/nginx/conf.d/clippy* 2>/dev/null
rm -rf /var/www/clippy-errors /var/lib/clippy-lab
sed -i '/clippy\.test/d' /etc/hosts
systemctl reload nginx 2>/dev/null
userdel -f clippy 2>/dev/null; rm -rf /opt/clippy
echo "Lab environment removed. (Nginx itself stays installed.)"
