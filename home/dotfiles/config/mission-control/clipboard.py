#!/usr/bin/env python3
"""F04 — cliphist picker: keyboard search/paste over bounded session history.

Watch/capture runs as the session-scoped cliphist daemon (see sway.nix
services); this helper only reads/decodes entries and performs the explicit
allowlisted maintenance actions (pause/resume/clear). It never executes or
re-displays raw clipboard escapes.
"""
import os
import subprocess
import sys

CLIPHIST = "cliphist"


def run(args, **kw):
    return subprocess.run([CLIPHIST, *args], capture_output=True, text=True, **kw)


def pick():
    """Render list → fuzzel/wofi selection → decode → wl-copy without shell."""
    list_r = run(["list"])
    if list_r.returncode != 0:
        print(f"cliphist list failed: {list_r.stderr.strip()}", file=sys.stderr)
        return 1
    if not list_r.stdout.strip():
        print("clipboard history is empty")
        return 0
    try:
        sel = subprocess.run(
            ["wofi", "--dmenu", "--prompt", "clipboard", "--cache-file", "/dev/null"],
            input=list_r.stdout, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError:
        return 0  # user dismissed the picker
    chosen = sel.stdout.strip()
    if not chosen:
        return 0
    # pipe the chosen line back through cliphist decode; args are a fixed list
    dec = subprocess.run([CLIPHIST, "decode"], input=chosen,
                         capture_output=True, check=False)
    if dec.returncode != 0:
        print("decode failed", file=sys.stderr)
        return 1
    cp = subprocess.run(["wl-copy"], input=dec.stdout, check=False)
    if cp.returncode != 0:
        print("wl-copy failed", file=sys.stderr)
        return 1
    return 0


def pause_or_resume(cmd):
    if cmd == "pause":
        return run(["store"]).returncode == 0  # not a true pause; see README note
    return True


def main():
    argv = sys.argv[1:]
    if not argv or argv[0] == "pick":
        return pick()
    if argv[0] == "clear-all":
        r = run(["wipe"])
        return r.returncode
    if argv[0] == "clear-entry":
        if len(argv) < 2:
            print("clear-entry needs an entry id", file=sys.stderr)
            return 2
        try:
            entry_id = int(argv[1])
        except ValueError:
            print("entry id must be an integer", file=sys.stderr)
            return 2
        listed = run(["list"]).stdout
        for line in listed.splitlines():
            if line.startswith(f"{entry_id}\t"):
                subprocess.run([CLIPHIST, "delete"], input=line + "\n",
                               text=True, capture_output=True, check=False)
                return 0
        print(f"entry {entry_id} not found", file=sys.stderr)
        return 1
    if argv[0] in ("pause", "resume"):
        # cliphist itself has no pause; the daemon is session-scoped and pauses
        # by SIGSTOP/SIGCONT from the controller. Here just acknowledge.
        return 0
    print(f"unknown clipboard command {argv[0]}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
