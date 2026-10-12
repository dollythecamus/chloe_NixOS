#!/usr/bin/env python3
"""F03 — grim/slurp/wl-copy screenshots: area/output/focused window.

Feedback is explicit and state-changing operations happen only after the
select/cancel step. Nothing relies on a graphical environment other than the
compositor and Wayland itself; geometry is passed as separate arguments,
never interpolated into a shell string. Save/copy failures are reported;
a slurp cancellation prints "cancelled" and produces nothing.
"""
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

MAX_NAME_LEN = 60
SAVE_DIR = Path(os.environ.get("XDG_PICTURES_DIR") or (Path.home() / "Pictures"))
SLURP = "slurp"
GRIM = "grim"
WL_COPY = "wl-copy"
SWAYMSG = "swaymsg"


def run(*args, **kwargs):
    kwargs.setdefault("check", True)
    return subprocess.run(args, capture_output=True, text=True, **kwargs)


def safe_name(prefix="shot"):
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return re.sub(r"[^a-zA-Z0-9._-]", "_", f"{prefix}-{stamp}.png")[:MAX_NAME_LEN]


def rectangle_from_slurp():
    """Interactive region selection; returns None on cancel/error."""
    r = run(SLURP, "-ro", "-d", "-f", "%x %y %w %h", check=False)
    if r.returncode != 0:
        return None
    fields = r.stdout.split()
    if len(fields) != 4:
        return None
    try:
        return tuple(int(v) for v in fields)
    except ValueError:
        return None


def run_text(*args):
    """IPC/config reads: return stdout as text or "" on any failure."""
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=5, check=True)
        return r.stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def focused_geometry():
    try:
        tree = json.loads(run_text(SWAYMSG, "-t", "get_tree", "-r"))
        focus_stack = [tree]
        # Walk to the focused window; use its stored geometry.
        while focus_stack:
            node = focus_stack.pop()
            if node.get("focused"):
                rect = node.get("rect", {})
                if rect.get("width") and node.get("app_id"):
                    x, y = rect["x"], rect["y"]
                    return x, y, rect["width"], rect["height"]
                return None
            focus_stack.extend(node.get("nodes", []) + node.get("floating_nodes", []))
    except (ValueError, KeyError, OSError):
        return None
    return None


def output_geometry(name=None):
    try:
        outputs = json.loads(run_text(SWAYMSG, "-t", "get_outputs", "-r"))
        target = outputs[0]
        if name:
            for out in outputs:
                if out.get("name") == name:
                    target = out
                    break
        rect = target.get("rect", {})
        if rect.get("width"):
            return rect["x"], rect["y"], rect["width"], rect["height"]
    except (ValueError, KeyError, IndexError, OSError):
        pass
    return None


def capture(geometry, copy_mode, out_dir):
    """Run grim on the bounding box, then optionally copy the file bytes."""
    if geometry is None:
        return "cancelled", None
    x, y, w, h = geometry
    if w <= 0 or h <= 0:
        return "failed", "bad geometry from Sway IPC"
    out_dir.mkdir(parents=True, exist_ok=True)
    if not os.access(out_dir, os.W_OK):
        return "failed", f"directory not writable: {out_dir}"
    path = out_dir / safe_name()
    args = [GRIM, "-g", f"{x},{y} {w}x{h}", str(path)]
    r = run(*args, check=False)
    if r.returncode != 0:
        return "failed", r.stderr.strip() or "grim failed"
    if not path.is_file() or path.stat().st_size == 0:
        return "failed", "grim produced no readable file"
    if copy_mode in ("also-clipboard", "only-clipboard"):
        data = path.read_bytes()
        c = subprocess.run([WL_COPY], input=data, capture_output=True, check=False)
        if c.returncode != 0:
            return "failed", f"file saved to {path}; clipboard copy failed"
        if copy_mode == "only-clipboard":
            path.unlink()
            return "copied", None
    return "saved", str(path)


def main():
    argv = sys.argv[1:]
    if not argv:
        print("usage: screenshots.py {area|output [name]|window} [--copy-only] [--dir PATH]", file=sys.stderr)
        return 2
    mode = argv[0]
    copy_mode = "none"
    if "--copy-only" in argv[1:]:
        copy_mode = "only-clipboard"
    elif "--also-clipboard" in argv[1:]:
        copy_mode = "also-clipboard"
    out_dir = SAVE_DIR
    if "--dir" in argv[1:]:
        try:
            out_dir = Path(argv[argv.index("--dir") + 1])
        except IndexError:
            return 2

    if mode == "area":
        geometry = rectangle_from_slurp()
    elif mode == "output":
        name = argv[1] if len(argv) > 1 and not argv[1].startswith("-") else None
        geometry = output_geometry(name)
    elif mode == "window":
        geometry = focused_geometry()
    else:
        print(f"unknown mode {mode}", file=sys.stderr)
        return 2

    if geometry is None and mode in ("area",):
        print("cancelled: no region selected", file=sys.stderr)
        return 0  # a deliberate cancel is success with no effect

    status, detail = capture(geometry, copy_mode, out_dir)
    if status in ("saved", "copied"):
        print(f"{status}: {detail}" if detail else f"{status} to clipboard")
        return 0
    print(f"failed: {detail}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
