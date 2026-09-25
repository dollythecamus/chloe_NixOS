#!/usr/bin/env python3
"""Low-rate, failure-tolerant telemetry for the prototype EWW panel."""
import json
import os
from pathlib import Path
import subprocess
import sys
from workspace_guard import workspaces as tree_workspaces, tiled_leaves


def run(*args):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=3, check=True).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def read(path):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return ""


def gpu():
    value = run("nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits")
    return f"GPU {value.splitlines()[0]}%" if value and value.splitlines()[0].isdigit() else "GPU --"


def workspaces():
    try:
        spaces = json.loads(run("swaymsg", "-t", "get_workspaces", "-r"))
        tree = json.loads(run("swaymsg", "-t", "get_tree", "-r"))
        by_number = {s["num"]: s for s in tree_workspaces(tree)}
        focused = next((s["num"] for s in spaces if s["focused"]), None)
        numbers = sorted(set(range(1, 10)) | set(by_number))
        labels = []
        app_icons = []
        for number in numbers:
            ws = by_number.get(number, {})
            windows = list(tiled_leaves(ws)) + list(floating_leaves(ws))
            labels.append(f"{'●' if number == focused else '○'}{number:>2}")
            app_icons.append([window_icon(win) for win in windows])
        # Fixed-width columns keep each workspace's app icons directly below
        # its number in the monospace EWW label.
        lines = ["  ".join(labels)]
        for row in range(max(map(len, app_icons), default=0)):
            lines.append("  ".join(
                f"{icons[row] if row < len(icons) else '':>3}" for icons in app_icons
            ))
        return "\n".join(lines)
    except (ValueError, KeyError, TypeError):
        return "WS --"


def floating_leaves(node):
    for child in node.get("floating_nodes", []):
        if child.get("app_id") or child.get("window"):
            yield child
        yield from floating_leaves(child)


def window_icon(window):
    title = (window.get("name") or "").lower()
    app = (window.get("app_id") or window.get("window_properties", {}).get("class") or "").lower()
    if "mission-pet" in title or "mission-pet" in app:
        return "♥"
    if "mission-orbits" in title or "mission-orbits" in app:
        return "◎"
    if any(name in app for name in ("firefox", "chrom", "brave")):
        return "◉"
    if any(name in app for name in ("code", "codium")):
        return "⌘"
    if "kitty" in app or "terminal" in app:
        return ">_"
    if any(name in app for name in ("discord", "steam")):
        return "♫"
    if any(name in app for name in ("nautilus", "dolphin", "thunar")):
        return "▤"
    return "▣"


def metrics():
    batteries = sorted(Path("/sys/class/power_supply").glob("BAT*"))
    battery = "BAT --"
    if batteries:
        capacity = read(batteries[0] / "capacity")
        state = read(batteries[0] / "status")
        battery = f"BAT {capacity}% · {state}" if capacity else "BAT --"
    mem = {}
    for line in read("/proc/meminfo").splitlines():
        name, _, value = line.partition(":")
        if name in ("MemTotal", "MemAvailable"):
            try:
                mem[name] = int(value.strip().split()[0])
            except (IndexError, ValueError):
                pass
    memory = "MEM --"
    if mem.get("MemTotal") and "MemAvailable" in mem:
        memory = f"MEM {(mem['MemTotal'] - mem['MemAvailable']) * 100 // mem['MemTotal']}%"
    disk = "DISK --"
    try:
        fs = os.statvfs("/")
        disk = f"DISK {(fs.f_blocks - fs.f_bavail) * 100 // fs.f_blocks}%" if fs.f_blocks else disk
    except OSError:
        pass
    try:
        cpu = f"CPU load {os.getloadavg()[0]:.2f}"  # 1-minute load, not CPU percent
    except OSError:
        cpu = "CPU --"
    volume = run("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@")
    audio = "AUDIO --"
    if volume:
        try:
            audio = f"AUDIO {int(float(volume.split()[1]) * 100)}%"
            if "MUTED" in volume:
                audio += " muted"
        except (ValueError, IndexError):
            pass
    return dict(battery=battery, cpu=cpu, memory=memory, disk=disk, audio=audio)


if __name__ == "__main__":
    if sys.argv[1:] == ["gpu"]:
        print(gpu())
    elif sys.argv[1:] == ["workspaces"]:
        print(workspaces())
    else:
        print(json.dumps(metrics()))
