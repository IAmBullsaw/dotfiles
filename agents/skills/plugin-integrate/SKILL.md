---
name: plugin-integrate
description: "Reverse-engineer a tool's plugin/extension API and build a working integration. Use when: \"$plugin\", \"write a plugin for\", \"create an extension for\", \"integrate with [tool]\", \"kitten\", \"neovim plugin\", \"zellij plugin\", \"git hook\", \"bash completion\", \"hook into\", \"extend [tool]\", \"custom command for\", \"add functionality to\", \"add a keybind that runs\", \"automate inside [tool]\". Not for: configuring a tool (use dotfiles), writing standalone scripts (no plugin API involved), using an already-understood API (just write the code)."
---

# Plugin Integration

Reverse-engineer a tool's plugin/extension API and build a working integration.

## Workflow
<procedure>

### Phase 0: Gather documentation

1. I will **ask the user for docs** before any code or introspection:
   - "Do you have local docs, man pages, or source for this plugin API?"
   - "Is there an online reference? (URL, GitHub repo, wiki)"
   - I will check for local docs: `<tool> --help`, man pages, `/usr/share/doc/`, tool's own `help` command.
   - I will check for bundled examples: many tools ship example plugins in their install directory.

2. I will **read the docs first**, skimming for: entry point conventions, required function signatures, lifecycle hooks, execution context, known limitations.

3. If docs are thin or missing, I will proceed to Phase 1. But I will always ask first, because 5 minutes reading docs saves 20 minutes guessing at APIs.

### Phase 1: Reconnaissance

4. I will **identify the plugin loader** by finding the function/module that loads plugins.
   - I will check the tool's source, not just docs, because plugin API docs are often incomplete or outdated.
   - I will use the tool's own interpreter if it has one (`kitty +runpy`, `nvim --cmd "lua print(...)"`, `python3 -c`).

5. I will **inspect the expected interface** using introspection tools (`dis.dis()`, `inspect.getsource()`, `getattr()`, `dir()`):
   - Function names and signatures
   - Attributes/decorators on functions
   - Return types
   - File naming conventions and paths

6. I will **identify the execution context**, because assumptions about the runtime cause the hardest bugs:
   - Same process as the tool? Subprocess? Overlay?
   - What's available: `sys.executable`, env vars, imports, filesystem access?
   - What's NOT available that you'd expect?

7. I will **document findings before writing any code**, because writing code without documented findings leads to guessing and dead ends:
   - [ ] Entry point function(s) and their signatures
   - [ ] Required attributes/decorators
   - [ ] Execution context (process, env, available APIs)
   - [ ] Known gotchas

### Phase 2: Minimal skeleton

8. I will **build the smallest possible working plugin** with hardcoded output and no real logic, because untested foundations cause cascading mystery failures. One wrong assumption in the skeleton propagates through every later addition.
   - Example: a kitten that just pastes "hello", a neovim plugin that just prints a message.

9. I will **verify the skeleton works** before adding any real logic.

### Phase 3: Real logic

10. I will **add one capability at a time** and test after each addition. If something breaks, the last addition is the cause. No need to debug multiple changes at once.

</procedure>

## Contrastive examples

**Reconnaissance vs guessing:**
- ✅ `kitty +runpy "from kittens.runner import create_kitten_handler; import dis; dis.dis(create_kitten_handler)"` - revealed kitty checks `m['end'].no_ui` attribute. Found the root cause in 2 minutes.
- ❌ Tried 5 variations of kitten code based on incomplete docs. Each failed for a different reason. 20 minutes wasted because we never inspected the loader.

**Execution context:**
- ✅ Tested `sys.executable` inside kitty's boss process, discovered it resolves to the kitty binary. Used `"python3"` instead.
- ❌ Assumed `sys.executable` would be python3 (it is everywhere else). Kitten timed out after 5 seconds trying to run redact.py with the kitty binary.

**Skeleton first:**
- ✅ Built a kitten that just pastes "hello". Confirmed: no overlay, loads correctly, `no_ui` attribute set. Then added xclip + redact logic.
- ❌ Built the full kitten with clipboard access + redaction + error handling. It hung. No idea which part was wrong because everything was untested.

**Path resolution:**
- ✅ Checked where the tool resolves relative paths from (`kitty.constants.config_dir` = `~/.config/kitty/`). Symlinked accordingly.
- ❌ Assumed relative paths resolve from where the config file lives on disk (the dotfiles repo). Got "file not found".

## Debugging checklist
<constraints>

When a plugin doesn't work:

- [ ] Does the tool find the file? (path resolution, naming convention)
- [ ] Does the module load without import errors? (test with tool's interpreter)
- [ ] Are required attributes/decorators present? (`getattr` check)
- [ ] Does the entry point function have the right signature?
- [ ] Is the execution context what you expect? (`sys.executable`, env vars, available imports)
- [ ] Is the plugin producing output but you can't see it? (check stderr, log files)

</constraints>

## Failure recovery
<failure-recovery>

| Situation | Action |
|---|---|
| Tool has no embedded interpreter | Read source on disk or GitHub. Search for the plugin loader by filename convention (e.g., `rg "load.*plugin\|import.*kitten"` in the tool's source). |
| Skeleton loads but no visible output | Add a print/log to the entry point. Check stderr, tool's debug/verbose mode, log files. |
| Tool is fully compiled, no introspection | Search GitHub issues/discussions for "custom plugin" + tool name. Look for example plugins in the repo's examples/ or contrib/ directory. |
| 2 failed approaches | Stop coding. Inspect the runtime with the tool's own interpreter. Document what I find before trying again. |
| No plugin API exists | Tell the user. Suggest alternatives: shell wrapper, tool's config-level hooks, or upstream feature request. |

</failure-recovery>

## Known tool-specific references

| Tool | Reference doc | Key gotcha |
|------|--------------|------------|
| Kitty kittens | `~/.agents/skills/plugin-integrate/references/kitty-kittens.md` | `@result_handler(no_ui=True)` required, `sys.executable` is kitty binary |

I will add rows as we integrate with more tools.

## Done
<done>

- [ ] Plugin loads without errors
- [ ] Skeleton produces visible output
- [ ] Real logic works end-to-end
- [ ] Gotchas documented in tool-specific reference doc
- [ ] Playbook entry logged
</done>
