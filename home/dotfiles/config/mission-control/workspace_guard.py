#!/usr/bin/env python3
"""Limit ordinary tiled windows to two per numbered Sway workspace.

Sway has no tile-count limit. Subscribe to window events rather than polling;
move only the incoming ordinary leaf, leaving creative applications and floats
alone. Editors may create temporary drag windows before supplying dialog hints.
"""
import json
import os
import subprocess
import sys
import time


def workspaces(node):
    if node.get("type") == "workspace" and node.get("num", -1) > 0:
        yield node
    for child in node.get("nodes", []):
        yield from workspaces(child)


def tiled_leaves(node):
    for child in node.get("nodes", []):
        if child.get("type") == "con" and (child.get("app_id") or child.get("window")):
            yield child
        else:
            yield from tiled_leaves(child)


# Match identities, never window titles: titles may be shared by the editor
# and a popup, and they change while dragging or opening a document.
CREATIVE_APPS = frozenset({
    "unity", "krita", "org.kde.krita", "lmms", "io.lmms.lmms",
    "godot", "godot_editor", "godot_engine", "godot_projectmanager",
    "org.godotengine.godot",
})


def creative_window(node):
    properties = node.get("window_properties") or {}
    identities = (node.get("app_id"), properties.get("class"), properties.get("instance"))
    return any((identity or "").casefold() in CREATIVE_APPS for identity in identities)


def relocation(tree, window_id):
    spaces = list(workspaces(tree))
    source = next((ws for ws in spaces if any(c["id"] == window_id for c in tiled_leaves(ws))), None)
    if source is None or len(list(tiled_leaves(source))) <= 2:
        return None
    incoming = next(c for c in tiled_leaves(source) if c["id"] == window_id)
    if creative_window(incoming):
        return None
    counts = {ws["num"]: len(list(tiled_leaves(ws))) for ws in spaces}
    target = source["num"] + 1
    while counts.get(target, 0) >= 2:
        target += 1
    return target


def query_tree():
    result = subprocess.run(["swaymsg", "-r", "-t", "get_tree"],
                            capture_output=True, text=True, timeout=3, check=True)
    return json.loads(result.stdout)


def watch():
    # swaymsg -m streams newline-delimited JSON and exits with the compositor.
    with subprocess.Popen(["swaymsg", "-m", "-r", "-t", "subscribe", '["window"]'],
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                          text=True, bufsize=1) as stream:
        assert stream.stdout is not None
        for line in stream.stdout:
            try:
                event = json.loads(line)
                if event.get("change") not in ("new", "move", "floating"):
                    continue
                window_id = event["container"]["id"]
                destination = relocation(query_tree(), window_id)
                if destination is not None:
                    subprocess.run(["swaymsg", "-r", f"[con_id={window_id}] move container to workspace number {destination}"],
                                   capture_output=True, text=True, timeout=3, check=True)
                    # Follow overflow into its new workspace instead of leaving
                    # focus on the now-emptier source workspace.
                    subprocess.run(["swaymsg", "-r", f"workspace number {destination}"],
                                   capture_output=True, text=True, timeout=3, check=True)
            except (KeyError, TypeError, ValueError, OSError, subprocess.SubprocessError) as exc:
                print(f"workspace_guard: {exc}", file=sys.stderr, flush=True)


if __name__ == "__main__":
    # Reconnect if swaymsg's subscription drops while the session remains up.
    while True:
        try:
            watch()
        except OSError as exc:
            print(f"workspace_guard: {exc}", file=sys.stderr, flush=True)
        if not os.path.exists(os.environ.get("SWAYSOCK", "")):
            break
        time.sleep(2)
