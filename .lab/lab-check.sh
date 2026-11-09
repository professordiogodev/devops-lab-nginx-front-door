#!/usr/bin/env bash
rc=0
if [ -s clippy.conf ] && grep -q 'proxy_pass' clippy.conf && grep -q 'upstream' clippy.conf && grep -q 'limit_req' clippy.conf; then echo "- ✅ clippy.conf has an upstream, proxy_pass and limit_req"
else echo "- ❌ clippy.conf must contain an upstream block, proxy_pass and limit_req"; rc=1; fi
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
