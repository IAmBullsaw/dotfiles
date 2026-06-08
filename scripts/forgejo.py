#!/usr/bin/env python3
"""Forgejo CLI — issues, labels, priority/size, CI logs, and more."""

import argparse
import io
import json
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile


def _git_credential_token(host):
    proc = subprocess.run(
        ["git", "credential", "fill"],
        input=f"protocol=https\nhost={host}\n",
        capture_output=True, text=True,
    )
    for line in proc.stdout.splitlines():
        if line.startswith("password="):
            return line[len("password="):]
    sys.exit(f"No credentials found for {host} in git credential store")


def _git_remote_info():
    proc = subprocess.run(
        ["git", "remote", "get-url", "origin"],
        capture_output=True, text=True, cwd=_repo_root(),
    )
    url = proc.stdout.strip()
    m = re.match(r"https://([^/]+)/([^/]+/[^/]+?)(?:\.git)?$", url)
    if not m:
        sys.exit(f"Cannot parse git remote URL: {url}")
    return m.group(1), m.group(2)  # host, owner/repo


def _repo_root():
    proc = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True,
    )
    return proc.stdout.strip() or "."


class Forge:
    def __init__(self):
        self.host, self.repo = _git_remote_info()
        self.token = _git_credential_token(self.host)
        self.base = f"https://{self.host}/api/v1/repos/{self.repo}"
        self._label_map = None  # name → id

    def _req(self, method, path, body=None, *, raw=False):
        url = self.base + path
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(
            url, data=data, method=method,
            headers={
                "Authorization": f"token {self.token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req) as resp:
                if raw:
                    return resp.read()
                return json.loads(resp.read()) if resp.length != 0 else None
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            sys.exit(f"HTTP {e.code} {method} {url}\n{body}")

    def _labels(self):
        if self._label_map is None:
            data = self._req("GET", "/labels?limit=50")
            self._label_map = {l["name"]: l["id"] for l in data}
        return self._label_map

    def _label_id(self, name):
        lmap = self._labels()
        if name not in lmap:
            available = ", ".join(sorted(lmap))
            sys.exit(f"Label '{name}' not found.\nAvailable: {available}")
        return lmap[name]

    def _issue_labels(self, issue):
        return self._req("GET", f"/issues/{issue}/labels")  # [{id, name}, ...]

    def _replace_labels(self, issue, ids):
        self._req("PUT", f"/issues/{issue}/labels", {"labels": ids})

    def _post_comment(self, issue, body):
        result = self._req("POST", f"/issues/{issue}/comments", {"body": body})
        return result["id"]

    # --- issue list / show ---

    def issues_list(self, state="open", label=None, limit=30):
        params = f"?type=issues&state={state}&limit={limit}"
        if label:
            params += f"&labels={urllib.parse.quote(label)}"
        data = self._req("GET", f"/issues{params}")
        if not data:
            print("No issues found.")
            return
        tty = sys.stdout.isatty()
        for issue in data:
            labels = " ".join(f"[{l['name']}]" for l in issue.get("labels", []))
            idx = f"#{issue['number']}"
            title = issue["title"]
            if tty and len(title) > 60:
                title = title[:57] + "..."
            print(f"{idx:<6} {title:<62} {labels}")

    def issue_show(self, number, comments=False):
        data = self._req("GET", f"/issues/{number}")
        labels = ", ".join(l["name"] for l in data.get("labels", []))
        print(f"#{data['number']}: {data['title']}")
        print(f"State:  {data['state']}")
        print(f"Labels: {labels or '(none)'}")
        print(f"URL:    {data['html_url']}")
        print()
        print(data.get("body") or "(no body)")
        if comments:
            comms = self._req("GET", f"/issues/{number}/comments")
            if comms:
                print(f"\n{'─' * 60}")
                for c in comms:
                    ts = c["created_at"][:16].replace("T", " ")
                    print(f"\n@{c['user']['login']} — {ts}")
                    print(c["body"])

    # --- issue mutations ---

    def comment(self, issue, message):
        cid = self._post_comment(issue, message)
        print(f"#{issue} → comment {cid} posted")

    def reopen(self, issue):
        self._req("PATCH", f"/issues/{issue}", {"state": "open"})
        print(f"#{issue} reopened")

    def label_add(self, issue, name):
        lid = self._label_id(name)
        current = self._issue_labels(issue)
        if any(l["id"] == lid for l in current):
            print(f"#{issue} already has '{name}'")
            return
        ids = [l["id"] for l in current] + [lid]
        self._replace_labels(issue, ids)
        print(f"#{issue} + '{name}'")

    def label_remove(self, issue, name):
        lid = self._label_id(name)
        current = self._issue_labels(issue)
        remaining = [l["id"] for l in current if l["id"] != lid]
        if len(remaining) == len(current):
            print(f"#{issue} does not have '{name}'")
            return
        self._replace_labels(issue, remaining)
        print(f"#{issue} - '{name}'")

    def _set_typed_label(self, issue, prefix_re, new_name, reason, kind):
        """Remove existing label matching prefix_re, add new_name, post audit comment."""
        new_id = self._label_id(new_name)
        current = self._issue_labels(issue)
        old = [l for l in current if re.match(prefix_re, l["name"])]

        ids = [l["id"] for l in current if not re.match(prefix_re, l["name"])]
        ids.append(new_id)
        self._replace_labels(issue, ids)

        if old:
            old_name = old[0]["name"]
            if old_name == new_name:
                print(f"#{issue} already '{new_name}' — no change")
                return
            audit = f"**{kind} changed: {old_name} → {new_name}** — {reason}"
        else:
            audit = f"**{kind} set: {new_name}** — {reason}"

        cid = self._post_comment(issue, audit)
        print(f"#{issue} → {new_name}, comment {cid}")

    def set_priority(self, issue, prio, reason):
        _SHORT = {"p1": "p1-critical", "p2": "p2-high", "p3": "p3-normal", "p4": "p4-low"}
        name = _SHORT.get(prio, prio)
        self._set_typed_label(issue, r"^p[1-4]-", name, reason, "Priority")

    def set_size(self, issue, size, reason):
        _SHORT = {"xs": "size-xs", "s": "size-s", "m": "size-m", "l": "size-l", "xl": "size-xl"}
        name = _SHORT.get(size, size)
        self._set_typed_label(issue, r"^size-", name, reason, "Size")

    def close(self, issue, message=None):
        if message:
            self._post_comment(issue, message)
        self._req("PATCH", f"/issues/{issue}", {"state": "closed"})
        print(f"#{issue} closed")

    def create(self, title, body, labels):
        label_ids = [self._label_id(n) for n in labels] if labels else []
        result = self._req("POST", "/issues", {
            "title": title,
            "body": body,
            "labels": label_ids,
        })
        print(f"#{result['number']} created: {result['title']}")
        return result["number"]

    def batch(self, path, as_json=False):
        src = sys.stdin if path == "-" else open(path)
        with src:
            try:
                ops = json.load(src)
            except json.JSONDecodeError as e:
                sys.exit(f"batch: invalid JSON — {e}")
        if not isinstance(ops, list):
            sys.exit("batch: expected a JSON array at top level")
        results = []
        for i, op in enumerate(ops):
            cmd = op.get("cmd")
            try:
                match cmd:
                    case "create":
                        num = self.create(op["title"], op.get("body", ""), op.get("labels", []))
                        results.append({"cmd": cmd, "issue": num, "status": "ok"})
                    case "close":
                        self.close(op["issue"], op.get("message"))
                        results.append({"cmd": cmd, "issue": op["issue"], "status": "ok"})
                    case "reopen":
                        self.reopen(op["issue"])
                        results.append({"cmd": cmd, "issue": op["issue"], "status": "ok"})
                    case "comment":
                        self.comment(op["issue"], op["message"])
                        results.append({"cmd": cmd, "issue": op["issue"], "status": "ok"})
                    case "set-priority":
                        self.set_priority(op["issue"], op["priority"], op["reason"])
                        results.append({"cmd": cmd, "issue": op["issue"], "status": "ok"})
                    case "set-size":
                        self.set_size(op["issue"], op["size"], op["reason"])
                        results.append({"cmd": cmd, "issue": op["issue"], "status": "ok"})
                    case "label-add":
                        self.label_add(op["issue"], op["label"])
                        results.append({"cmd": cmd, "issue": op["issue"], "status": "ok"})
                    case "label-remove":
                        self.label_remove(op["issue"], op["label"])
                        results.append({"cmd": cmd, "issue": op["issue"], "status": "ok"})
                    case _:
                        print(f"[{i}] unknown cmd '{cmd}' — skipped", file=sys.stderr)
                        results.append({"cmd": cmd, "status": "skipped", "reason": "unknown cmd"})
            except KeyError as e:
                sys.exit(f"[{i}] missing field {e} in {op}")
        if as_json:
            print(json.dumps(results, indent=2))

    # --- CI commands ---

    def _ci_runs(self, limit=50):
        data = self._req("GET", f"/actions/tasks?limit={limit}")
        return data.get("workflow_runs", [])

    def ci_status(self):
        _ICON = {"success": "\033[32m✓\033[0m", "failure": "\033[31m✗\033[0m",
                 "running": "\033[33m…\033[0m", "waiting": "\033[33m·\033[0m",
                 "cancelled": "\033[90mx\033[0m"}
        _PLAIN = {"success": "OK  ", "failure": "FAIL", "running": "RUN ",
                  "waiting": "WAIT", "cancelled": "CANC"}
        runs = self._ci_runs(limit=100)
        seen = {}
        for r in runs:
            if r["workflow_id"] not in seen:
                seen[r["workflow_id"]] = r
        tty = sys.stdout.isatty()
        for wid, r in sorted(seen.items()):
            icon = _ICON.get(r["status"], "?") if tty else _PLAIN.get(r["status"], r["status"][:4])
            sha = r["head_sha"][:8]
            ts = r["updated_at"][:16].replace("T", " ")
            url = r["url"] if r["status"] == "failure" else ""
            print(f"{icon}  {wid:<30} run#{r['run_number']:<4} {sha}  {ts}  {url or r['display_title'][:50]}")

    def ci_list(self, limit=20):
        _PLAIN = {"success": "OK  ", "failure": "FAIL", "running": "RUN ",
                  "waiting": "WAIT", "cancelled": "CANC"}
        _COLOR = {"success": "\033[32mOK  \033[0m", "failure": "\033[31mFAIL\033[0m",
                  "running": "\033[33mRUN \033[0m", "cancelled": "\033[90mCANC\033[0m"}
        runs = self._ci_runs(limit=limit)
        tty = sys.stdout.isatty()
        for r in runs:
            status = _COLOR.get(r["status"], r["status"][:4]) if tty \
                else _PLAIN.get(r["status"], r["status"][:4].upper())
            sha = r["head_sha"][:8]
            ts = r["updated_at"][:16].replace("T", " ")
            print(f"{status}  {r['id']:<5} {r['workflow_id']:<30} {sha}  {ts}  {r['display_title'][:50]}")

    def ci_logs(self, run_number):
        runs = self._ci_runs(limit=200)
        match = [r for r in runs if r["run_number"] == run_number]
        if not match:
            sys.exit(f"Run #{run_number} not found (searched last 200 runs)")
        r = match[0]
        run_id = r["id"]
        print(f"Run #{run_number} (id={run_id}) — {r['workflow_id']} — {r['status']}")
        print(f"  {r['display_title']}")

        log_path = f"/actions/runs/{run_id}/logs"
        req = urllib.request.Request(
            self.base + log_path,
            headers={"Authorization": f"token {self.token}", "Accept": "application/octet-stream"},
        )
        try:
            with urllib.request.urlopen(req) as resp:
                data = resp.read()
            zf = zipfile.ZipFile(io.BytesIO(data))
            for name in sorted(zf.namelist()):
                content = zf.read(name).decode(errors="replace").strip()
                if content:
                    print(f"\n{'─' * 60}")
                    print(f"  {name}")
                    print("─" * 60)
                    print(content)
        except urllib.error.HTTPError as e:
            print(f"  (log API returned HTTP {e.code} — web URL: {r['url']})")
        except zipfile.BadZipFile:
            print(f"  (unexpected response format — web URL: {r['url']})")


def main():
    p = argparse.ArgumentParser(description="Forgejo issue helper")
    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("issues", help="List issues")
    c.add_argument("--state", default="open", choices=["open", "closed", "all"])
    c.add_argument("--label", default=None, metavar="LABEL")
    c.add_argument("--limit", type=int, default=30)

    c = sub.add_parser("show", help="Show an issue (body + optional comments)")
    c.add_argument("issue", type=int)
    c.add_argument("--comments", action="store_true")

    c = sub.add_parser("comment", help="Post a comment")
    c.add_argument("issue", type=int)
    c.add_argument("message")

    c = sub.add_parser("reopen", help="Reopen a closed issue")
    c.add_argument("issue", type=int)

    c = sub.add_parser("label-add", help="Add a label by name")
    c.add_argument("issue", type=int)
    c.add_argument("label")

    c = sub.add_parser("label-remove", help="Remove a label by name")
    c.add_argument("issue", type=int)
    c.add_argument("label")

    c = sub.add_parser("set-priority", help="Set priority label with audit comment")
    c.add_argument("issue", type=int)
    c.add_argument("priority", metavar="PRIO",
                   help="p1/p2/p3/p4 or full name (p1-critical etc.)")
    c.add_argument("reason")

    c = sub.add_parser("set-size", help="Set t-shirt size label with audit comment")
    c.add_argument("issue", type=int)
    c.add_argument("size", metavar="SIZE",
                   help="xs/s/m/l/xl or full name (size-xs etc.)")
    c.add_argument("reason")

    c = sub.add_parser("close", help="Close an issue (optional closing comment)")
    c.add_argument("issue", type=int)
    c.add_argument("message", nargs="?")

    c = sub.add_parser("create", help="Create a new issue")
    c.add_argument("--title", required=True)
    c.add_argument("--body", default="")
    c.add_argument("--label", dest="labels", action="append", default=[],
                   metavar="LABEL")

    c = sub.add_parser("batch", help="Run a JSON array of operations from FILE (or - for stdin)")
    c.add_argument("file", metavar="FILE")
    c.add_argument("--json-output", action="store_true", dest="as_json",
                   help="Print results as a JSON array on stdout")

    c = sub.add_parser("ci-status", help="Latest run per workflow with pass/fail")
    c = sub.add_parser("ci-list", help="Recent CI runs across all workflows")
    c.add_argument("--limit", type=int, default=20)
    c = sub.add_parser("ci-logs", help="Fetch and print logs for a CI run")
    c.add_argument("run_number", type=int)

    args = p.parse_args()
    f = Forge()

    match args.cmd:
        case "issues":       f.issues_list(args.state, args.label, args.limit)
        case "show":         f.issue_show(args.issue, args.comments)
        case "comment":      f.comment(args.issue, args.message)
        case "reopen":       f.reopen(args.issue)
        case "label-add":    f.label_add(args.issue, args.label)
        case "label-remove": f.label_remove(args.issue, args.label)
        case "set-priority": f.set_priority(args.issue, args.priority, args.reason)
        case "set-size":     f.set_size(args.issue, args.size, args.reason)
        case "close":        f.close(args.issue, args.message)
        case "create":       f.create(args.title, args.body, args.labels)
        case "batch":        f.batch(args.file, args.as_json)
        case "ci-status":    f.ci_status()
        case "ci-list":      f.ci_list(args.limit)
        case "ci-logs":      f.ci_logs(args.run_number)


if __name__ == "__main__":
    main()
