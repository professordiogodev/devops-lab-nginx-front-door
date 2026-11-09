#!/usr/bin/env bash
# Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
pkill -f 'uvicorn api.main:app --host 127.0.0.1' 2>/dev/null
rm -f /etc/nginx/sites-enabled/clipstr* /etc/nginx/sites-available/clipstr* /etc/nginx/conf.d/clipstr* 2>/dev/null
rm -rf /var/www/clipstr-errors /var/lib/clipstr-lab
sed -i '/clipstr\.test/d' /etc/hosts
systemctl reload nginx 2>/dev/null
echo "Lab environment removed. (Nginx itself stays installed.)"
