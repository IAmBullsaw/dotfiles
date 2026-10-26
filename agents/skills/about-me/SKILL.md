---
name: about-me
type: reference
description: "Reference: who the user is and how they work: preferences (editor, terminal, theme, languages), how the AI files are organised and maintained, profile-building, dotfiles layout. Use when a task depends on the user's setup or preferences, or when updating these notes."
---

# about-me

Moved from ~/.kiro/profile.md on 2026-10-26 (sections L61, L147, L245, L265, L289).

## When learning something new about the user, update this prof

- When learning something new about the user, update this profile and commit

## Preferences
- **Terminal bell on turn completion: ALWAYS.** User explicitly asked for this ("i love the bell added to the tab when prompt was done - always do that!"). Emit `printf '\a'` at the end of the final shell command of a turn, especially after long-running work, so the kitty tab shows the bell indicator. Kitty must have `bell_on_tab` enabled for the indicator to render.
- Editor: Neovim
- Primary language: C++
- Secondary scripting language: Python (used for work automation, data processing, and tooling beyond dotfile scripts)
- Terminal: Kitty (100% primary — tabs, splits, kittens)
- Multiplexer: tmux, minimal — only for session persistence via `tmux new-session -A -s <name>`. No splits/windows in tmux. Zellij is retired.
- Personal git forge: Forgejo (self-hosted) for personal projects
- Theme: Catppuccin (across all tools — kitty, nvim, tmux, GTK)
- Prefers ripgrep (rg) over grep
- Downloads RPMs directly when repo setup is fiddly
- Likes things version-controlled (~/Code/janos -> ~/.kiro symlink)

## AI Techniques
- Playbook: `~/.agents.local/skills/playbook/SKILL.md` — tracks techniques, when to use them, effectiveness ratings
- Learnings: `~/.agents.local/skills/learnings/SKILL.md` — distilled rules, always loaded. Quick-lookup index at top maps task types to sections.
- Learnings context: `~/.agents.local/skills/learnings-context/SKILL.md` — append-only archive with the story/reasoning behind each bullet. Not auto-loaded. Read when a rule's applicability is unclear or during retros.
- Priming prompts: `~/.agents/skills/priming-prompts/SKILL.md` — reusable role/perspective prompts to pick from
- After non-trivial tasks, log what technique was used and how well it worked in the playbook results table
- After adding a bullet to learnings.md, also append the story + transferable insight to learnings-context.md
- Proactively flag workflow friction or repeated patterns as candidates for improvement.
- **Repo review pattern:** When reviewing external repos for adoptable patterns: (1) scan directory structure + README first, (2) filter by user's stack/workflow, (3) read only relevant skills/agents, (4) note findings in `~/.kiro/references/`, (5) log in playbook. Most repos are 80%+ irrelevant. Be aggressive about skipping.
- **Never copy external skills/agents directly.** Always write new or adapt into existing skills/agents. We own what we ship. External content may contain harmful, wrong, or misaligned instructions. Extract the pattern, understand it, then rewrite it in our voice with our constraints.

## Profile Building
- User says "profile questions" → ask 3 y/n questions to fill gaps
- Asked questions log: `~/.agents.local/skills/interview-questions-asked/SKILL.md` (check before asking)

## Dotfiles (~/dotfiles/)
- Bash configs: ~/dotfiles/bash/.bashrc.d/ (compiled module system with require())
  - config.sh: exports, shopt, env vars (EDITOR=nvim, PAGER=less, unlimited history)
  - aliases.sh: git aliases (ga/gb/gc/gd/gs/gh/gl/gfp/gca...), nav (groot, ccd), make (mk/mkc/mkt), C++ compile flags (g++14/17/20)
  - functions.sh: bashrc-compile, add-alias, bm (directory bookmarks), gc (safe commit refusing master/main), llb (repo logbook), most-frequent, lazy nvm loader
  - prompt.sh: [time] git-branch [short-pwd]$ with vim indicator, caches git root per PWD change
  - .bashrc.user: compiled module loader — auto-recompiles when any .sh is newer
- Scripts: ~/dotfiles/scripts/
  - hgg.sh: history grep using rg+fzf over ~/.bash_history_master
  - logbook.py: GPG-encrypted markdown logbook (per-repo via llb function) — no longer actively used, was an idea that faded
  - reg.py: regex match extractor (stdin pipe tool)
  - get_cmake.sh: cmake version installer
  - modmgr.sh: interactive TUI module manager for work.sh (arrow-key menu, add/edit/remove)
  - forgejo.py: Forgejo CLI (issues, labels, CI logs) — actively used for personal projects on self-hosted Forgejo
- Helpers: ~/dotfiles/helpers/
  - update.sh: auto-pull dotfiles repo if behind remote
- Other: nvim config, kitty config, zellij layouts, theme
  - kitty/kittens/smart_nav.py: custom-written kitten for window navigation — moves to neighboring Kitty window, falls back to next/prev tab when at the edge. Used for alt+h/l navigation.
