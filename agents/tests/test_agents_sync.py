"""Tests for `agents-sync check`. Run: python3 -m unittest discover -s tests (from dotfiles/agents).

Every test builds a throwaway HOME, so nothing real is read. Sample leaks are
assembled at runtime: this file lives in ~/.agents and must pass the leak check
itself.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

BIN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin", "agents-sync")
WORK_WORD = "acme" + "corp"                      # stands in for an employer name
SECRET = "gl" + "pat-" + "A" * 24                 # shape of a GitLab token


def write(path, text):
    with open(path, "w") as fh:
        fh.write(text)


def skill(root, name, front=None, body="Body.\n"):
    d = os.path.join(root, "skills", name)
    os.makedirs(d, exist_ok=True)
    front = front if front is not None else f"name: {name}\ndescription: Does {name}. Use when testing.\n"
    with open(os.path.join(d, "SKILL.md"), "w") as fh:
        fh.write(f"---\n{front}---\n\n{body}")


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.home = tempfile.mkdtemp(prefix="agents-sync-test-")
        self.personal = os.path.join(self.home, ".agents")
        self.work = os.path.join(self.home, ".agents.local")
        os.makedirs(self.personal)
        os.makedirs(os.path.join(self.work, "agents-sync"))
        with open(os.path.join(self.work, "agents-sync", "leak-patterns.txt"), "w") as fh:
            fh.write("# test patterns\n" + WORK_WORD + "\n")

    def tearDown(self):
        shutil.rmtree(self.home, ignore_errors=True)

    def run_check(self):
        env = dict(os.environ, HOME=self.home)
        p = subprocess.run([sys.executable, BIN, "check", "--json"], env=env,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        return p.returncode, json.loads(p.stdout)

    def test_clean_tree_passes(self):
        skill(self.personal, "tech-doc")
        rc, r = self.run_check()
        self.assertEqual(rc, 0, r)
        self.assertEqual(r["errors"], [])

    def test_missing_personal_root_fails(self):
        shutil.rmtree(self.personal)
        rc, r = self.run_check()
        self.assertEqual(rc, 1)

    def test_work_word_in_personal_is_a_leak(self):
        skill(self.personal, "tech-doc", body=f"See the {WORK_WORD} wiki.\n")
        rc, r = self.run_check()
        self.assertEqual(rc, 1)
        self.assertTrue(any(e.startswith("leak: personal:skills/tech-doc/SKILL.md:") for e in r["errors"]), r)
        self.assertFalse(any(WORK_WORD in e for e in r["errors"]), "matched text must not be printed")

    def test_work_word_in_overlay_is_fine(self):
        skill(self.personal, "tech-doc")
        skill(self.work, "work-run", body=f"Run it at {WORK_WORD}.\n")
        rc, r = self.run_check()
        self.assertEqual(rc, 0, r)

    def test_secret_is_caught_even_without_overlay(self):
        shutil.rmtree(self.work)
        skill(self.personal, "tech-doc", body=f"token = '{SECRET}'\n")
        rc, r = self.run_check()
        self.assertEqual(rc, 1)
        self.assertTrue(any("gitlab token" in e or "assigned secret" in e for e in r["errors"]), r)
        self.assertTrue(any("limited to secret patterns" in w for w in r["warnings"]), r)

    def test_name_must_match_folder(self):
        skill(self.personal, "tech-doc", front="name: techdoc\ndescription: x\n")
        rc, r = self.run_check()
        self.assertEqual(rc, 1)
        self.assertTrue(any("does not match folder" in e for e in r["errors"]), r)

    def test_bad_folder_name_rejected(self):
        skill(self.personal, "Bad_Name", front="name: Bad_Name\ndescription: x\n")
        rc, r = self.run_check()
        self.assertTrue(any("lowercase-hyphenated" in e for e in r["errors"]), r)

    def test_missing_description(self):
        skill(self.personal, "tech-doc", front="name: tech-doc\n")
        rc, r = self.run_check()
        self.assertTrue(any("description missing" in e for e in r["errors"]), r)

    def test_folded_description_is_read(self):
        skill(self.personal, "tech-doc", front="name: tech-doc\ndescription: >\n  Write docs.\n  Use when: docs.\n")
        rc, r = self.run_check()
        self.assertEqual(rc, 0, r)

    def test_description_too_long(self):
        skill(self.personal, "tech-doc", front=f"name: tech-doc\ndescription: {'x' * 1100}\n")
        rc, r = self.run_check()
        self.assertTrue(any("max 1024" in e for e in r["errors"]), r)

    def test_allowed_and_disallowed_extra_keys(self):
        skill(self.personal, "a-skill", front="name: a-skill\ndescription: x\ntype: reference\nversion: \"1.0\"\n")
        skill(self.personal, "b-skill", front="name: b-skill\ndescription: x\nauthor: someone\n")
        rc, r = self.run_check()
        self.assertFalse(any("a-skill" in e for e in r["errors"]), r)
        self.assertTrue(any("b-skill" in e and "author" in e for e in r["errors"]), r)

    def test_metadata_block_allowed(self):
        skill(self.personal, "tech-doc", front="name: tech-doc\ndescription: x\nmetadata:\n  model: m\n  notes: n\n")
        rc, r = self.run_check()
        self.assertEqual(rc, 0, r)

    def test_duplicate_name_warns_overlay_wins(self):
        skill(self.personal, "tech-doc")
        skill(self.work, "tech-doc")
        rc, r = self.run_check()
        self.assertEqual(rc, 0, r)
        self.assertTrue(any("both personal and work: work wins" in w for w in r["warnings"]), r)

    def test_no_front_matter(self):
        d = os.path.join(self.personal, "skills", "tech-doc")
        os.makedirs(d)
        write(os.path.join(d, "SKILL.md"), "# no front matter\n")
        rc, r = self.run_check()
        self.assertTrue(any("no front matter" in e for e in r["errors"]), r)

    def test_invalid_agent_json(self):
        d = os.path.join(self.personal, "targets", "kiro", "agents")
        os.makedirs(d)
        write(os.path.join(d, "x.json"), "{not json")
        rc, r = self.run_check()
        self.assertTrue(any("invalid JSON" in e for e in r["errors"]), r)

    def test_long_agents_md_warns(self):
        write(os.path.join(self.personal, "AGENTS.md"), "line\n" * 60)
        rc, r = self.run_check()
        self.assertEqual(rc, 0, r)
        self.assertTrue(any("AGENTS.md is 60 lines" in w for w in r["warnings"]), r)


if __name__ == "__main__":
    unittest.main()
