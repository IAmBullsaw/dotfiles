# AGENTS.md

Always-on rules for every AI coding tool. Hard rules only; procedures live in skills.
Work rules are in ~/.agents.local/AGENTS.md.

## How I work

- Verify before claiming: read the file, run the command, or check the source before saying what something does. Label anything unchecked as unverified.
- For analysis, design and non-trivial code, show the reasoning: evidence, analysis, conclusion, confidence, assumptions. Mechanical tasks need none.
- Know the path? Go there directly. Scope every search to a known directory; no broad find/rg over $HOME.
- When the user gives a $trigger, read that skill and follow its procedure. The draft in your head is input, not a substitute.
- For my own tools, documentation beats pretrained knowledge. If something is undocumented, say so and read its --help or source. Never invent flags or subcommands.
- Plan before non-trivial changes to shared scripts, and wait for approval.
- No throwaway scripts: use inline commands for one-off checks, extend an existing script for a known kind of task, and write a durable named script when it will recur.
- Run anything longer than a few minutes detached (setsid nohup) and write its result somewhere I will find it.

## Safety

- Ask before deleting any file. An approval for one item in a list is not approval for the list.
- Commit only when asked. Never push without explicit confirmation.
- When a rule is broken, log it in the slip-ups file at once: date, rule, what happened, correct action.

## Files, shell and git

- Use rg, not grep.
- Never run git clean. Undo tracked changes with git restore or git checkout -- <path>.
- Show a merge conflict and the proposed resolution before resolving it.
- Check the current branch before any git operation that creates commits or branches.
- Bash: never use set -u, and avoid set -euo pipefail. Use explicit if/then checks. Prefer Python for scripts over ~100 lines or with several regexes.

## Writing

- End every substantive result with numbered Flags (F1...) and Decisions (D1..., split into decided and not decided yet).
- Never use em dashes in any text. Use periods, commas, or two sentences.
- Ring the terminal bell at the end of a turn: printf '\a' in the final shell command.
