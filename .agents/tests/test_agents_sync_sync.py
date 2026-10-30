"""Tests for `agents-sync sync/unlink/status`. Run: python3 -m unittest discover -s tests (from dotfiles/.agents).

Covers the merged view (additions, work overrides, removals), the Claude and
Kiro adapters, conflicts with things agents-sync didn't create, adopt with
backup and restore, the one-time migration of an old ~/.agents link,
idempotency, interrupted runs, and that sources are never written. Every test
uses a throwaway HOME with explicit source paths.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

BIN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin", "agents-sync")


def read(path):
    with open(path) as fh:
        return fh.read()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write(text)


def skill(root, name, body="Body.\n"):
    write(f"{root}/skills/{name}/SKILL.md", f"---\nname: {name}\ndescription: Does {name}.\n---\n\n{body}")


def snapshot(root):
    out = {}
    for dp, dn, fn in os.walk(root):
        for f in fn:
            p = os.path.join(dp, f)
            out[p] = (os.lstat(p).st_mtime_ns, read(p) if not os.path.islink(p) else os.readlink(p))
    return out


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.home = tempfile.mkdtemp(prefix="agents-sync-sync-")
        self.p = os.path.join(self.home, "dotfiles", ".agents")
        self.w = os.path.join(self.home, "dotwork", ".agents")
        self.v = os.path.join(self.home, ".agents")
        self.c = os.path.join(self.home, ".claude")
        self.k = os.path.join(self.home, ".kiro")
        write(f"{self.p}/AGENTS.md", "personal rules\n")
        skill(self.p, "tech-doc")
        skill(self.p, "shared")
        skill(self.w, "shared", body="work version\n")
        skill(self.w, "work-only")
        write(f"{self.p}/targets/kiro/agents/vault.json", '{"name": "vault"}')
        write(f"{self.p}/targets/kiro/hooks/bell.sh", "#!/bin/sh\n")
        write(f"{self.w}/targets/kiro/agents/ez.json", '{"name": "ez"}')
        os.makedirs(self.c)
        os.makedirs(self.k)

    def tearDown(self):
        shutil.rmtree(self.home, ignore_errors=True)

    def run_cmd(self, *args):
        env = dict(os.environ, HOME=self.home)
        for k in ("XDG_STATE_HOME", "AGENTS_PERSONAL", "AGENTS_WORK"):
            env.pop(k, None)
        p = subprocess.run([sys.executable, BIN, "--personal", self.p, "--work", self.w] + list(args) + ["--json"],
                           env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        self.assertEqual(p.stderr, "")
        return p.returncode, json.loads(p.stdout)

    def manifest(self):
        return json.loads(read(f"{self.home}/.local/state/agents-sync/manifest.json"))["entries"]

    def targets(self):
        return json.loads(read(f"{self.home}/.local/state/agents-sync/manifest.json")).get("targets")

    # --- merged view -------------------------------------------------

    def test_view_merges_personal_and_work(self):
        rc, r = self.run_cmd("sync")
        self.assertEqual((rc, r["status"]), (0, "ok"))
        self.assertFalse(os.path.islink(self.v), "~/.agents is a real generated folder")
        self.assertEqual(os.readlink(f"{self.v}/skills/tech-doc"), f"{self.p}/skills/tech-doc")
        self.assertEqual(os.readlink(f"{self.v}/skills/work-only"), f"{self.w}/skills/work-only")
        self.assertEqual(os.readlink(f"{self.v}/AGENTS.md"), f"{self.p}/AGENTS.md")
        self.assertFalse(os.path.lexists(f"{self.v}/AGENTS.work.md"), "no work AGENTS.md, no link")

    def test_work_skill_replaces_whole_personal_folder(self):
        write(f"{self.p}/skills/shared/references/only-personal.md", "x")
        rc, r = self.run_cmd("sync")
        self.assertEqual(os.readlink(f"{self.v}/skills/shared"), f"{self.w}/skills/shared")
        self.assertFalse(os.path.exists(f"{self.v}/skills/shared/references/only-personal.md"))
        self.assertIn("skills/shared: work replaces personal", r["overrides"])

    def test_removing_work_override_falls_back_to_personal(self):
        self.run_cmd("sync")
        shutil.rmtree(f"{self.w}/skills/shared")
        rc, r = self.run_cmd("sync")
        self.assertEqual(os.readlink(f"{self.v}/skills/shared"), f"{self.p}/skills/shared")
        self.assertEqual(r["overrides"], [])

    def test_skill_gone_from_sources_is_removed_everywhere(self):
        self.run_cmd("sync")
        shutil.rmtree(f"{self.p}/skills/tech-doc")
        rc, r = self.run_cmd("sync")
        self.assertIn("remove", [a["action"] for a in r["actions"]])
        self.assertFalse(os.path.lexists(f"{self.v}/skills/tech-doc"))
        self.assertFalse(os.path.lexists(f"{self.c}/skills/tech-doc"))
        self.assertFalse(any(e["path"].endswith("tech-doc") for e in self.manifest()))

    def test_work_agents_md_is_layered_not_overridden(self):
        write(f"{self.w}/AGENTS.md", "work rules\n")
        self.run_cmd("sync")
        self.assertEqual(os.readlink(f"{self.v}/AGENTS.md"), f"{self.p}/AGENTS.md")
        self.assertEqual(os.readlink(f"{self.v}/AGENTS.work.md"), f"{self.w}/AGENTS.md")
        self.assertIn("@~/.agents/AGENTS.work.md", read(f"{self.c}/CLAUDE.md"))

    def test_work_repo_missing_is_fine(self):
        shutil.rmtree(self.w)
        rc, r = self.run_cmd("sync")
        self.assertEqual((rc, r["status"]), (0, "ok"))
        self.assertEqual(sorted(os.listdir(f"{self.v}/skills")), ["shared", "tech-doc"])

    def test_sources_are_never_written(self):
        before = snapshot(self.p), snapshot(self.w)
        self.run_cmd("sync")
        self.run_cmd("unlink")
        self.assertEqual((snapshot(self.p), snapshot(self.w)), before)

    # --- claude ------------------------------------------------------

    def test_claude_links_point_into_view_and_stub_imports_it(self):
        self.run_cmd("sync")
        self.assertEqual(os.readlink(f"{self.c}/skills/shared"), f"{self.v}/skills/shared")
        stub = read(f"{self.c}/CLAUDE.md")
        self.assertTrue(stub.startswith("<!-- Generated by agents-sync."))
        self.assertIn("@~/.agents/AGENTS.md\n", stub)
        self.assertNotIn("AGENTS.work.md", stub)

    def test_claude_exclude_list(self):
        write(f"{self.p}/targets/claude/target.json",
              '{"capabilities": {"skills": {"exclude": ["tech-doc"]}}}')
        self.run_cmd("sync")
        self.assertFalse(os.path.lexists(f"{self.c}/skills/tech-doc"))
        self.assertTrue(os.path.islink(f"{self.v}/skills/tech-doc"), "excluded for Claude, still in the view")

    def test_no_tool_home_no_adapter(self):
        shutil.rmtree(self.c)
        shutil.rmtree(self.k)
        rc, r = self.run_cmd("sync")
        self.assertFalse(os.path.exists(self.c))
        self.assertFalse(os.path.exists(self.k))
        self.assertTrue(os.path.isdir(f"{self.v}/skills"))

    def test_hand_written_claude_md_needs_adopt_and_comes_back_on_unlink(self):
        write(f"{self.c}/CLAUDE.md", "my own notes\n")
        rc, r = self.run_cmd("sync")
        self.assertEqual((rc, r["status"]), (1, "conflict"))
        self.assertFalse(os.path.exists(self.v), "nothing applied on conflict")
        rc, r = self.run_cmd("sync", "--adopt")
        self.assertEqual(r["status"], "ok")
        self.assertIn("Generated by agents-sync", read(f"{self.c}/CLAUDE.md"))
        self.run_cmd("unlink")
        self.assertEqual(read(f"{self.c}/CLAUDE.md"), "my own notes\n")

    def test_edited_stub_is_a_conflict(self):
        self.run_cmd("sync")
        write(f"{self.c}/CLAUDE.md", "edited the generated file\n")
        rc, r = self.run_cmd("sync")
        self.assertIn("conflict:edited-by-hand", [a["action"] for a in r["actions"]])
        rc, s = self.run_cmd("status")
        self.assertIn("edited by hand", [m["state"] for m in s["managed"]])

    def test_stub_regenerates_when_sources_change(self):
        self.run_cmd("sync")
        write(f"{self.w}/AGENTS.md", "work rules\n")
        rc, r = self.run_cmd("sync")
        self.assertIn("regenerate", [a["action"] for a in r["actions"]])
        self.assertIn("AGENTS.work.md", read(f"{self.c}/CLAUDE.md"))

    # --- kiro --------------------------------------------------------

    def test_kiro_links_go_to_sources_and_work_wins(self):
        write(f"{self.p}/targets/kiro/agents/ez.json", '{"name": "personal-ez"}')
        rc, r = self.run_cmd("sync")
        self.assertEqual(os.readlink(f"{self.k}/agents/ez.json"), f"{self.w}/targets/kiro/agents/ez.json")
        self.assertEqual(os.readlink(f"{self.k}/hooks/bell.sh"), f"{self.p}/targets/kiro/hooks/bell.sh")
        self.assertIn("kiro/agents/ez.json: work replaces personal", r["overrides"])

    # --- targets -------------------------------------------------------

    def test_named_target_creates_its_home(self):
        shutil.rmtree(self.k)
        rc, r = self.run_cmd("sync", "kiro")
        self.assertEqual((rc, r["status"], r["targets"]), (0, "ok", ["kiro"]))
        self.assertEqual(os.readlink(f"{self.k}/agents/vault.json"), f"{self.p}/targets/kiro/agents/vault.json")
        dirs = {e["path"] for e in self.manifest() if e["kind"] == "dir"}
        self.assertTrue({"~/.kiro", "~/.kiro/agents", "~/.kiro/hooks"} <= dirs)
        self.assertFalse(os.path.lexists(f"{self.c}/skills"), "claude not named, not wired")

    def test_unnamed_missing_home_is_not_created(self):
        shutil.rmtree(self.k)
        rc, r = self.run_cmd("sync")
        self.assertEqual(r["targets"], ["claude"])
        self.assertFalse(os.path.exists(self.k))

    def test_existing_home_is_not_recorded(self):
        self.run_cmd("sync", "kiro")
        paths = {e["path"] for e in self.manifest()}
        self.assertNotIn("~/.kiro", paths, "a ~/.kiro made by Kiro is never ours")
        self.assertIn("~/.kiro/agents", paths)

    def test_targets_are_remembered(self):
        shutil.rmtree(self.k)
        shutil.rmtree(self.c)
        self.run_cmd("sync", "kiro")
        rc, r = self.run_cmd("sync")
        self.assertEqual((r["status"], r["targets"]), ("no changes", ["kiro"]))
        self.assertFalse(os.path.exists(self.c))
        rc, r = self.run_cmd("sync", "claude")
        self.assertEqual(r["targets"], ["claude", "kiro"])
        self.assertTrue(os.path.islink(f"{self.c}/skills/tech-doc"))

    def test_unlink_target_removes_created_dirs_and_forgets_it(self):
        shutil.rmtree(self.k)
        self.run_cmd("sync", "kiro", "claude")
        rc, r = self.run_cmd("unlink", "kiro")
        self.assertFalse(os.path.exists(self.k), "everything under ~/.kiro was ours and empty")
        self.assertTrue(os.path.islink(f"{self.v}/skills/tech-doc"), "view untouched")
        self.assertTrue(os.path.islink(f"{self.c}/skills/tech-doc"), "other target untouched")
        self.assertEqual(self.targets(), ["claude"])
        rc, r = self.run_cmd("sync")
        self.assertFalse(os.path.exists(self.k), "a forgotten target is not recreated")

    def test_unlink_keeps_created_home_once_the_tool_uses_it(self):
        shutil.rmtree(self.k)
        self.run_cmd("sync", "kiro")
        write(f"{self.k}/settings/cli.json", "{}")
        rc, r = self.run_cmd("unlink", "kiro")
        self.assertEqual(read(f"{self.k}/settings/cli.json"), "{}")
        self.assertFalse(os.path.lexists(f"{self.k}/agents"))

    # --- kiro settings ------------------------------------------------

    def cli(self):
        return json.loads(read(f"{self.k}/settings/cli.json"))

    def test_default_agent_set_when_unset_and_work_wins(self):
        write(f"{self.p}/targets/kiro/settings.json", '{"chat.defaultAgent": "main"}')
        self.run_cmd("sync", "kiro")
        self.assertEqual(self.cli()["chat.defaultAgent"], "main")
        write(f"{self.w}/targets/kiro/settings.json", '{"chat.defaultAgent": "ez"}')
        rc, r = self.run_cmd("sync")
        self.assertEqual(self.cli()["chat.defaultAgent"], "ez", "still ours, so the work value replaces it")
        rc, r = self.run_cmd("sync")
        self.assertEqual(r["status"], "no changes")

    def test_setting_by_hand_is_kept_and_other_keys_survive(self):
        write(f"{self.k}/settings/cli.json", '{"chat.defaultAgent": "mine", "other": 1}')
        write(f"{self.p}/targets/kiro/settings.json", '{"chat.defaultAgent": "main"}')
        rc, r = self.run_cmd("sync", "kiro")
        self.assertEqual(self.cli(), {"chat.defaultAgent": "mine", "other": 1})
        self.assertIn("keep:set-by-hand", [a["action"] for a in r["actions"]])

    def test_unlink_kiro_removes_only_our_setting(self):
        write(f"{self.k}/settings/cli.json", '{"other": 1}')
        write(f"{self.p}/targets/kiro/settings.json", '{"chat.defaultAgent": "main"}')
        self.run_cmd("sync", "kiro")
        self.assertEqual(self.cli(), {"other": 1, "chat.defaultAgent": "main"})
        self.run_cmd("unlink", "kiro")
        self.assertEqual(self.cli(), {"other": 1})

    def test_no_kiro_target_no_settings(self):
        shutil.rmtree(self.k)
        write(f"{self.p}/targets/kiro/settings.json", '{"chat.defaultAgent": "main"}')
        self.run_cmd("sync", "claude")
        self.assertFalse(os.path.exists(self.k))

    def test_unknown_target_is_an_error(self):
        env = dict(os.environ, HOME=self.home)
        p = subprocess.run([sys.executable, BIN, "--personal", self.p, "sync", "cursor"], env=env,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        self.assertEqual(p.returncode, 2)
        self.assertIn("unknown target cursor", p.stderr)
        self.assertFalse(os.path.exists(self.v))

    def test_dotfiles_and_other_extensions_ignored(self):
        write(f"{self.p}/targets/kiro/agents/.hidden.json", "{}")
        write(f"{self.p}/targets/kiro/agents/notes.md", "x")
        rc, r = self.run_cmd("sync", "--dry-run")
        paths = [a["path"] for a in r["actions"]]
        self.assertFalse(any(".hidden" in x or "notes.md" in x for x in paths))

    # --- safety and lifecycle ------------------------------------------

    def test_second_run_is_no_changes(self):
        self.run_cmd("sync")
        rc, r = self.run_cmd("sync")
        self.assertEqual((rc, r["status"]), (0, "no changes"))

    def test_dry_run_changes_nothing(self):
        rc, r = self.run_cmd("sync", "--dry-run")
        self.assertEqual(r["status"], "planned")
        self.assertFalse(os.path.exists(self.v))
        self.assertEqual(os.listdir(self.c), [])

    def test_old_agents_link_migrates_with_adopt_and_unlink_restores_it(self):
        os.symlink(self.p, self.v)
        before = snapshot(self.p)
        rc, r = self.run_cmd("sync")
        self.assertIn("conflict:in-the-way", [a["action"] for a in r["actions"]])
        rc, r = self.run_cmd("sync", "--adopt")
        self.assertEqual(r["status"], "ok")
        self.assertFalse(os.path.islink(self.v))
        self.assertTrue(os.path.islink(f"{self.v}/skills/tech-doc"))
        self.assertEqual(snapshot(self.p), before, "personal repo untouched by the migration")
        self.run_cmd("unlink")
        self.assertEqual(os.readlink(self.v), self.p)
        self.assertEqual(self.manifest(), [])

    def test_never_writes_through_a_link_into_a_source(self):
        shutil.rmtree(self.c)
        os.symlink(self.p, self.c)               # ~/.claude pointing into the repo: adapter must refuse
        before = snapshot(self.p)
        rc, r = self.run_cmd("sync", "--adopt")
        self.assertEqual(r["status"], "conflict")
        self.assertIn("conflict:inside-source-repo", [a["action"] for a in r["actions"]])
        self.assertEqual(snapshot(self.p), before)

    def test_foreign_link_is_conflict_even_with_adopt(self):
        os.makedirs(f"{self.k}/agents")
        os.symlink("/nowhere", f"{self.k}/agents/ez.json")
        rc, r = self.run_cmd("sync", "--adopt")
        self.assertEqual(r["status"], "conflict")
        self.assertEqual(os.readlink(f"{self.k}/agents/ez.json"), "/nowhere")

    def test_unlink_removes_everything_it_made(self):
        self.run_cmd("sync")
        rc, r = self.run_cmd("unlink")
        self.assertFalse(os.path.exists(self.v))
        self.assertEqual(os.listdir(self.c), ["skills"] if os.path.exists(f"{self.c}/skills") else [])
        self.assertEqual(self.manifest(), [])

    def test_unlink_leaves_modified_items_alone(self):
        self.run_cmd("sync")
        os.remove(f"{self.k}/agents/vault.json")
        write(f"{self.k}/agents/vault.json", "edited by hand")
        write(f"{self.v}/skills/stray.txt", "someone put this here")
        rc, r = self.run_cmd("unlink")
        self.assertEqual(read(f"{self.k}/agents/vault.json"), "edited by hand")
        self.assertFalse(os.path.islink(f"{self.k}/agents/ez.json"))
        self.assertTrue(os.path.exists(f"{self.v}/skills/stray.txt"), "folders with foreign content stay")
        left = sorted(e["path"] for e in self.manifest())
        self.assertEqual(left, ["~/.agents", "~/.agents/skills", "~/.kiro/agents", "~/.kiro/agents/vault.json"])

    def test_interrupted_run_converges(self):
        self.run_cmd("sync")
        m = json.loads(read(f"{self.home}/.local/state/agents-sync/manifest.json"))
        for e in m["entries"][len(m["entries"]) // 2:]:          # as if killed halfway
            path = e["path"].replace("~", self.home, 1)
            if os.path.islink(path) or os.path.isfile(path):
                os.remove(path)
        m["entries"] = m["entries"][:len(m["entries"]) // 2]
        write(f"{self.home}/.local/state/agents-sync/manifest.json", json.dumps(m))
        rc, r = self.run_cmd("sync")
        self.assertEqual(r["status"], "ok")
        rc, r = self.run_cmd("sync")
        self.assertEqual(r["status"], "no changes")


if __name__ == "__main__":
    unittest.main()
