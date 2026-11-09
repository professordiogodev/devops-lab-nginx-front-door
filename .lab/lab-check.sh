#!/usr/bin/env bash
rc=0
if [ -s clipstr.conf ] && grep -q 'proxy_pass' clipstr.conf && grep -q 'upstream' clipstr.conf && grep -q 'limit_req' clipstr.conf; then echo "- ✅ clipstr.conf has an upstream, proxy_pass and limit_req"
else echo "- ❌ clipstr.conf must contain an upstream block, proxy_pass and limit_req"; rc=1; fi
grep -q 'ALL CHECKS PASSED' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
