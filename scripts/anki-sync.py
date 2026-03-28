#!/usr/bin/env python3
"""Sync a TSV deck file to Anki via AnkiConnect."""

import argparse
import json
import sys
import urllib.request


def add_note(url, deck, front, back, tags):
    payload = json.dumps({
        "action": "addNote", "version": 6,
        "params": {"note": {
            "deckName": deck, "modelName": "Basic",
            "fields": {"Front": front, "Back": back},
            "tags": tags.split() if tags else [],
        }}
    }).encode()
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def main():
    p = argparse.ArgumentParser(description="Sync TSV deck file to Anki via AnkiConnect")
    p.add_argument("deck_file", help="TSV file: front<TAB>back<TAB>tags")
    p.add_argument("-d", "--deck", default="Default", help="Anki deck name (default: Default)")
    p.add_argument("-u", "--url", default="http://localhost:8765", help="AnkiConnect URL")
    args = p.parse_args()

    added = skipped = failed = 0
    with open(args.deck_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            front, back = parts[0], parts[1] if len(parts) > 1 else ""
            tags = parts[2] if len(parts) > 2 else ""
            try:
                result = add_note(args.url, args.deck, front, back, tags)
                if result.get("error") is None:
                    added += 1
                elif "duplicate" in str(result.get("error", "")):
                    skipped += 1
                else:
                    failed += 1
                    print(f"FAIL: {front} -> {result['error']}", file=sys.stderr)
            except Exception as e:
                failed += 1
                print(f"FAIL: {front} -> {e}", file=sys.stderr)

    print(f"Done: {added} added, {skipped} duplicates skipped, {failed} failed")


if __name__ == "__main__":
    main()
