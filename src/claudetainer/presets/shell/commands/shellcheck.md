---
allowed-tools: all
description: Run shellcheck on shell scripts with intelligent discovery
---

Run shellcheck on all shell scripts in the project. Find shell scripts by looking for:
- Files with .sh extension
- Files with bash/sh shebangs
- Executable files that appear to be shell scripts

Use appropriate shellcheck options:
- Show all issues with context
- Include informational messages
- Format output for readability
- Skip common false positives if needed

Focus on the most critical issues first (errors and warnings over style suggestions).