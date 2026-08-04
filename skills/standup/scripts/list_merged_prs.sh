#!/bin/zsh
# REST fallback for the standup skill: list PRs merged since a date, without
# touching the throttle-prone GitHub search API.
# Usage: list_merged_prs.sh <composio-account> <owner> <repo> <since YYYY-MM-DD>
set -u
COMPOSIO=/Users/testadmin/.composio/composio
ACCOUNT="$1"; OWNER="$2"; REPO="$3"; SINCE="$4"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
for page in 1 2 3; do
  $COMPOSIO execute GITHUB_LIST_PULL_REQUESTS --account "$ACCOUNT" \
    -d "{\"owner\":\"$OWNER\",\"repo\":\"$REPO\",\"state\":\"closed\",\"sort\":\"updated\",\"direction\":\"desc\",\"per_page\":100,\"page\":$page}" 2>/dev/null \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
fp = d.get('outputFilePath')
if d.get('storedInFile') and fp:
    d = json.load(open(fp))
prs = (d.get('data') or {}).get('pull_requests') or []
print(json.dumps(prs))
" >> "$tmp"
done
python3 -c "
import json
since = '$SINCE'; seen = {}
for line in open('$tmp'):
    line = line.strip()
    if not line: continue
    for it in json.loads(line):
        m = it.get('merged_at')
        if m and m[:10] >= since:
            seen[it['number']] = (m[:10], (it.get('user') or {}).get('login'), (it.get('title') or '').strip())
print('MERGED since', since, ':', len(seen))
for n in sorted(seen):
    d, u, t = seen[n]; print(f'#{n}\t{d}\t@{u}\t{t[:72]}')
"
