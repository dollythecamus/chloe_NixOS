#!/usr/bin/env python3
"""EWW panel data and bounded NetworkManager/WirePlumber actions.

Never pass SSIDs or profile names to a shell. New networks and credentials belong
in NetworkManager's connection editor, not an EWW command-line argument.
"""
import json
import re
import subprocess
import sys

UUID = re.compile(r"[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}\Z")


def run(*args, timeout=6):
    return subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=True).stdout.strip()


def fields(line):
    """Split nmcli's escaped terse fields, preserving colons/backslashes in names."""
    values, value, escaped = [], "", False
    for char in line:
        if escaped:
            value += char
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == ":":
            values.append(value)
            value = ""
        else:
            value += char
    values.append(value + ("\\" if escaped else ""))
    return values


def wifi_state():
    return run("nmcli", "-g", "WIFI", "general") == "enabled"


def saved_profiles():
    return [{"uuid": row[0], "name": row[1]}
            for line in run("nmcli", "-t", "-e", "yes", "-f", "UUID,NAME,TYPE", "connection", "show").splitlines()
            if len(row := fields(line)) == 3 and row[2] == "802-11-wireless" and UUID.fullmatch(row[0])]


def network():
    try:
        wifi = wifi_state()
    except (OSError, subprocess.SubprocessError):
        return {"wifi": False, "profiles": [], "available": [], "error": "NetworkManager unavailable"}
    try:
        profiles = saved_profiles()
    except (OSError, subprocess.SubprocessError):
        profiles = []
    try:
        active = {row[0] for line in run("nmcli", "-t", "-e", "yes", "-f", "UUID,TYPE", "connection", "show", "--active").splitlines()
                  if (row := fields(line))[-1] == "802-11-wireless"}
    except (OSError, subprocess.SubprocessError):
        active = set()
    profiles = [dict(profile, active=profile["uuid"] in active) for profile in profiles]
    available = []
    if wifi:
        try:
            available = [{"ssid": row[1], "signal": row[2], "security": row[3] or "open"}
                         for line in run("nmcli", "-t", "-e", "yes", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no").splitlines()
                         if len(row := fields(line)) == 4 and row[1]]
        except (OSError, subprocess.SubprocessError):
            pass
    return {"wifi": wifi, "profiles": profiles, "available": available[:8]}


def audio():
    data = {}
    for name, target in (("sink", "@DEFAULT_AUDIO_SINK@"), ("source", "@DEFAULT_AUDIO_SOURCE@")):
        try:
            output = run("wpctl", "get-volume", target)
            match = re.search(r"Volume:\s+([0-9.]+)", output)
            data[name] = round(float(match.group(1)) * 100) if match else 0
            data[f"{name}_available"] = bool(match)
            data[f"{name}_muted"] = "[MUTED]" in output
        except (OSError, subprocess.SubprocessError):
            data[name] = 0
            data[f"{name}_available"] = False
            data[f"{name}_muted"] = False
    return data


def action(name, value=None):
    if name == "connect":
        if not value or not UUID.fullmatch(value) or value not in {p["uuid"] for p in saved_profiles()}:
            raise ValueError("Only a saved Wi-Fi profile UUID can be activated")
        run("nmcli", "connection", "up", "uuid", value, timeout=20)
    elif name == "wifi-toggle":
        run("nmcli", "radio", "wifi", "off" if wifi_state() else "on")
    elif name == "volume":
        if value is None or not re.fullmatch(r"\d{1,3}(?:\.\d{1,3})?", value) or not 0 <= float(value) <= 100:
            raise ValueError("Volume must be a percentage in 0..100")
        run("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{round(float(value))}%")
    elif name in ("volume-up", "volume-down"):
        if name == "volume-up":
            run("wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+")
        else:
            run("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-")
    elif name in ("sink-mute", "source-mute"):
        target = "@DEFAULT_AUDIO_SINK@" if name == "sink-mute" else "@DEFAULT_AUDIO_SOURCE@"
        run("wpctl", "set-mute", target, "toggle")
    else:
        raise ValueError("Unknown widget action")


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["network"]:
            print(json.dumps(network()))
        elif sys.argv[1:] == ["audio"]:
            print(json.dumps(audio()))
        elif len(sys.argv) >= 2 and sys.argv[1] == "action":
            action(*sys.argv[2:])
        else:
            raise ValueError("usage: widgets.py {network|audio|action <name> [value]}")
    except (ValueError, OSError, subprocess.SubprocessError) as exc:
        print(exc, file=sys.stderr)
        sys.exit(2)
