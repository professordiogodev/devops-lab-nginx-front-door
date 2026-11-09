#!/usr/bin/env bash
# Run with: sudo ./verify.sh
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify.sh" >&2; exit 1; }
[ -x /var/lib/clipstr-lab/instance.sh ] || { echo "Run sudo ./setup.sh first"; exit 1; }
I=/var/lib/clipstr-lab/instance.sh
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
code() { curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$@"; }
restore() { $I start a >/dev/null 2>&1; $I start b >/dev/null 2>&1; sleep 3; }
trap restore EXIT
restore

echo "== Configuration =="
check "nginx -t says the configuration is valid"             nginx -t
check "your clipstr.conf is the config nginx actually loads" bash -c "[ -s clipstr.conf ] && nginx -T 2>/dev/null | grep -qF \"\$(grep -m1 proxy_pass clipstr.conf)\""
check "Host and X-Forwarded-For are passed to the app"       bash -c "grep -q 'proxy_set_header Host' clipstr.conf && grep -q 'X-Forwarded-For' clipstr.conf"

echo "== Serving =="
check "http://clipstr.test/healthz answers 200"              test "$(code http://clipstr.test/healthz)" = 200
check "both instances answer (load balancing)"               bash -c "o=\$(for i in \$(seq 12); do curl -s --max-time 3 http://clipstr.test/healthz; sleep 0.25; done); grep -q instance-a <<< \"\$o\" && grep -q instance-b <<< \"\$o\""
check "www.clipstr.test redirects (301) to clipstr.test"     bash -c "h=\$(curl -si --max-time 3 http://www.clipstr.test/stats | tr -d '\r'); head -1 <<< \"\$h\" | grep -q 301 && grep -qi '^location: http://clipstr.test/stats' <<< \"\$h\""
check "security headers: nosniff and X-Frame-Options"        bash -c "h=\$(curl -sI --max-time 3 http://clipstr.test/healthz | tr -d '\r'); grep -qi '^x-content-type-options: nosniff' <<< \"\$h\" && grep -qi '^x-frame-options:' <<< \"\$h\""
check "the Server header does not leak the Nginx version"    bash -c "! curl -sI --max-time 3 http://clipstr.test/healthz | grep -i '^server:' | grep -q '/'"

echo "== Failure =="
$I stop a; sleep 1
check "one instance down: users still get 200 every time"    bash -c "for i in \$(seq 8); do [ \"\$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://clipstr.test/healthz)\" = 200 ] || exit 1; done"
$I stop b; sleep 1
check "both down: a 502/503/504 comes back"                   bash -c "c=\$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://clipstr.test/healthz); [[ \$c =~ ^50[234]\$ ]]"
check "...with YOUR error page, not the default Nginx one"    bash -c "b=\$(curl -s --max-time 5 http://clipstr.test/healthz); [ \${#b} -gt 40 ] && ! grep -qi '<center>' <<< \"\$b\" && ! grep -qi 'nginx' <<< \"\$b\""
restore

echo "== Protection =="
check "a flood gets 429 Too Many Requests, normal calls still get 200" bash -c "sleep 2; c=\$(for i in \$(seq 60); do curl -s -o /dev/null -w '%{http_code}\n' --max-time 3 http://clipstr.test/healthz; done | sort | uniq -c); grep -q ' 429' <<< \"\$c\" && grep -q ' 200' <<< \"\$c\""

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
