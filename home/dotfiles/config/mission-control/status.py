#!/usr/bin/env python3
"""Low-rate, failure-tolerant telemetry for the prototype EWW panel."""
import json
import os
from pathlib import Path
import subprocess
import sys


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
        return "WS " + "  ".join(f"[{s['name']}]" if s['focused'] else s['name'] for s in spaces)
    except (ValueError, KeyError, TypeError):
        return "WS --"


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
