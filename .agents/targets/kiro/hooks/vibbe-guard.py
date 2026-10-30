#!/usr/bin/env python3
"""
preToolUse hook: hard-block destructive shell/write/git operations for Vibbe.

Reads the preToolUse payload from stdin. If the tool call matches a
destructive pattern, prints a reason to stderr and exits 2 (blocks the
tool call). Otherwise exits 0 (allow).

Only inspects the `shell` tool's `command` field. Fails open (allows)
on any parsing error, so a bug here never hangs the agent, it just
loses the extra safety net (the prompt-level instruction is still in play).
"""
import json
import re
import sys

# Each pattern is matched case-insensitively against the full command string.
# Kept intentionally broad (substring/regex, not full shell parsing) because
# false positives just mean an extra confirmation-free block+explanation,
# while false negatives defeat the whole point of a hard block.
DESTRUCTIVE_PATTERNS = [
    (r"\brm\s+(-\w*r\w*f\w*|-\w*f\w*r\w*)\b", "rm -rf (or similar recursive force delete)"),
    (r"\brm\s+.*-\w*f\w*\b.*\*", "rm -f with a wildcard"),
    (r"\bgit\s+push\s+.*(--force|-f)\b", "git push --force"),
    (r"\bgit\s+push\s+.*\+refs/", "git push with a force-push refspec (+branch)"),
    (r"\bgit\s+reset\s+--hard\b", "git reset --hard"),
    (r"\bgit\s+clean\s+.*-\w*f\w*", "git clean -f (removes untracked files)"),
    (r"\bgit\s+branch\s+-D\b", "git branch -D (force branch delete)"),
    (r"\bgit\s+checkout\s+.*--\s*\.\s*$", "git checkout -- . (discards all local changes)"),
    (r"\bgit\s+filter-branch\b", "git filter-branch (rewrites history)"),
    (r"\bdrop\s+(table|database|schema)\b", "SQL DROP TABLE/DATABASE/SCHEMA"),
    (r"\btruncate\s+table\b", "SQL TRUNCATE TABLE"),
    (r"\bmkfs\b", "mkfs (formats a filesystem)"),
    (r"\bdd\s+.*of=/dev/", "dd writing directly to a device"),
    (r":\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;", "fork bomb pattern"),
    (r"\bchmod\s+-R\s+000\b", "chmod -R 000 (locks out all access)"),
    (r"\bchown\s+-R\b.*\broot\b", "chown -R to root (broad ownership change)"),
    (r"\bshred\b", "shred (secure irreversible delete)"),
    (r">\s*/dev/sd[a-z]\b", "raw write to a block device"),
]

COMPILED = [(re.compile(p, re.IGNORECASE), desc) for p, desc in DESTRUCTIVE_PATTERNS]


def check_command(command: str):
    for pattern, desc in COMPILED:
        if pattern.search(command):
            return desc
    return None


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # fail open, can't parse input

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}

    command = None
    if tool_name == "shell":
        command = tool_input.get("command", "")

    if not command:
        sys.exit(0)  # nothing to check

    hit = check_command(command)
    if hit:
        sys.stderr.write(
            f"BLOCKED by Vibbe guard: command matches a destructive pattern ({hit}).\n"
            f"Command: {command}\n"
            "This action is hard-blocked for this agent. If it's genuinely needed, "
            "ask the user to run it manually outside Vibbe.\n"
        )
        sys.exit(2)  # block

    sys.exit(0)  # allow


if __name__ == "__main__":
    main()
