"""Tests for `agents-sync sync/unlink/status`. Run: python3 -m unittest discover -s tests (from dotfiles/agents).

Spec section 9 list: empty destination, own link (no-op), foreign file and
foreign link (conflict), adopt with backup and restore, stale entry, overlay
precedence, idempotency, interrupted run, unlink leaving modified items alone,
path traversal. Every test uses a throwaway HOME.
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


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.home = tempfile.mkdtemp(prefix="agents-sync-sync-")
        self.p = os.path.join(self.home, ".agents")
        self.w = os.path.join(self.home, ".agents.local")
        self.k = os.path.join(self.home, ".kiro")
        write(f"{self.p}/targets/kiro/agents/vault.json", '{"name": "vault"}')
        write(f"{self.p}/targets/kiro/hooks/bell.sh", "#!/bin/sh\n")
        write(f"{self.w}/targets/kiro/agents/ez.json", '{"name": "ez"}')
        os.makedirs(f"{self.k}/agents")
        os.makedirs(f"{self.k}/hooks")

    def tearDown(self):
        shutil.rmtree(self.home, ignore_errors=True)

    def run_cmd(self, *args):
        env = dict(os.environ, HOME=self.home)
        env.pop("XDG_STATE_HOME", None)
        p = subprocess.run([sys.executable, BIN] + list(args) + ["--json"], env=env,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        self.assertEqual(p.stderr, "")
        return p.returncode, json.loads(p.stdout)

    def manifest(self):
        return json.loads(read(f"{self.home}/.local/state/agents-sync/manifest.json"))["entries"]

    def test_empty_destination_creates_links(self):
        rc, r = self.run_cmd("sync")
        self.assertEqual((rc, r["status"], r["changed"]), (0, "ok", 3))
        self.assertEqual(os.readlink(f"{self.k}/agents/ez.json"), f"{self.w}/targets/kiro/agents/ez.json")
        self.assertEqual(len(self.manifest()), 3)

    def test_second_run_is_no_changes(self):
        self.run_cmd("sync")
        rc, r = self.run_cmd("sync")
        self.assertEqual((rc, r["status"]), (0, "no changes"))

    def test_dry_run_changes_nothing(self):
        rc, r = self.run_cmd("sync", "--dry-run")
        self.assertEqual(r["status"], "planned")
        self.assertEqual(os.listdir(f"{self.k}/agents"), [])

    def test_real_file_is_conflict_without_adopt(self):
        write(f"{self.k}/agents/ez.json", '{"name": "old"}')
        rc, r = self.run_cmd("sync")
        self.assertEqual((rc, r["status"]), (1, "conflict"))
        self.assertFalse(os.path.islink(f"{self.k}/agents/vault.json"), "nothing applied on conflict")

    def test_foreign_link_is_conflict_even_with_adopt(self):
        os.symlink("/nowhere", f"{self.k}/agents/ez.json")
        rc, r = self.run_cmd("sync", "--adopt")
        self.assertEqual(r["status"], "conflict")
        self.assertEqual(os.readlink(f"{self.k}/agents/ez.json"), "/nowhere")

    def test_adopt_backs_up_and_unlink_restores(self):
        write(f"{self.k}/agents/ez.json", '{"name": "old"}')
        rc, r = self.run_cmd("sync", "--adopt")
        self.assertEqual(r["status"], "ok")
        self.assertTrue(os.path.islink(f"{self.k}/agents/ez.json"))
        e = [x for x in self.manifest() if x["path"].endswith("ez.json")][0]
        self.assertIn("backup", e)
        rc, r = self.run_cmd("unlink")
        self.assertFalse(os.path.islink(f"{self.k}/agents/ez.json"))
        self.assertEqual(read(f"{self.k}/agents/ez.json"), '{"name": "old"}')
        self.assertEqual(self.manifest(), [])

    def test_overlay_wins_on_same_name(self):
        write(f"{self.p}/targets/kiro/agents/ez.json", '{"name": "personal-ez"}')
        rc, r = self.run_cmd("sync")
        self.assertEqual(os.readlink(f"{self.k}/agents/ez.json"), f"{self.w}/targets/kiro/agents/ez.json")
        self.assertTrue(any("work wins" in w for w in r["warnings"]))

    def test_unlink_leaves_modified_items_alone(self):
        self.run_cmd("sync")
        os.remove(f"{self.k}/agents/vault.json")
        write(f"{self.k}/agents/vault.json", "edited by hand")
        rc, r = self.run_cmd("unlink")
        self.assertEqual(read(f"{self.k}/agents/vault.json"), "edited by hand")
        self.assertFalse(os.path.islink(f"{self.k}/agents/ez.json"))
        self.assertEqual([x["path"] for x in self.manifest()], ["~/.kiro/agents/vault.json"])

    def test_interrupted_run_converges(self):
        self.run_cmd("sync", "--only", "agents")
        rc, r = self.run_cmd("sync")
        self.assertEqual((r["status"], r["changed"]), ("ok", 1))
        rc, r = self.run_cmd("sync")
        self.assertEqual(r["status"], "no changes")

    def test_stale_entry_reported(self):
        self.run_cmd("sync")
        os.remove(f"{self.w}/targets/kiro/agents/ez.json")
        rc, r = self.run_cmd("sync", "--dry-run")
        self.assertIn("stale", [a["action"] for a in r["actions"]])
        rc, s = self.run_cmd("status")
        self.assertIn("stale (source gone)", [m["state"] for m in s["managed"]])

    def test_only_hooks(self):
        rc, r = self.run_cmd("sync", "--only", "hooks")
        self.assertEqual(r["changed"], 1)
        self.assertTrue(os.path.islink(f"{self.k}/hooks/bell.sh"))
        self.assertFalse(os.path.exists(f"{self.k}/agents/ez.json"))

    def test_dotfiles_and_other_extensions_ignored(self):
        write(f"{self.p}/targets/kiro/agents/.hidden.json", "{}")
        write(f"{self.p}/targets/kiro/agents/notes.md", "x")
        rc, r = self.run_cmd("sync", "--dry-run")
        paths = [a["path"] for a in r["actions"]]
        self.assertFalse(any(".hidden" in x or "notes.md" in x for x in paths))


if __name__ == "__main__":
    unittest.main()
