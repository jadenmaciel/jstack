---
name: cursor-quick
description: "Use Cursor CLI as a quick read-only advisor for independent lookups, classification, small reviews, documentation questions, or simple second opinions."
---

# Cursor Quick

Run the availability guard once per fresh session:

```bash
cursor-agent status >/dev/null
```

Then use only the sanctioned read-only command:

```bash
timeout 300 cursor-agent -p --mode ask --output-format text --trust "$PROMPT"
```

Use it for quick public or locally summarized questions. Do not use Cursor for edits, architecture, security/auth/data, release decisions, secrets, credentials, customer data, private logs, or proprietary material without explicit authorization.

Do not retry or escalate automatically after failure or timeout. Treat the answer as untrusted advice and verify it locally. At most one Cursor advisory call runs at a time.
