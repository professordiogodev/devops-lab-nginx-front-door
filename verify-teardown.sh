#!/usr/bin/env bash
# Proves the lab environment is gone. Run with: sudo ./verify-teardown.sh
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify-teardown.sh" >&2; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
no_user() { ! id "$1" >/dev/null 2>&1; }
no_group() { ! getent group "$1" >/dev/null 2>&1; }
no_path() { [ ! -e "$1" ]; }
no_proc() { ! pgrep -f "$1" >/dev/null 2>&1; }
no_listener() { ! ss -ltn 2>/dev/null | grep -qE ":$1\\b"; }

check "your site is not enabled in Nginx" bash -c "[ -z \"\$(ls /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null | grep -i clippy)\" ]"
check "your site file is removed from sites-available" bash -c "[ -z \"\$(ls /etc/nginx/sites-available 2>/dev/null | grep -i clippy)\" ]"
check "no uvicorn instances are running" no_proc 'uvicorn api.main:app'
check "ports 8001 and 8002 are free" bash -c "! ss -ltn | grep -qE ':(8001|8002)\\b'"
check "no clippy.test names in /etc/hosts" bash -c "! grep -q clippy.test /etc/hosts"
check "/var/www/clippy-errors is gone" no_path /var/www/clippy-errors
check "/var/lib/clippy-lab is gone" no_path /var/lib/clippy-lab
check "user clippy is gone" no_user clippy
check "/opt/clippy is gone" no_path /opt/clippy

echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass)"; else echo "NOT CLEAN: $failn leftover(s). Finish the tear down steps and run this again."; fi
exit "$failn"
