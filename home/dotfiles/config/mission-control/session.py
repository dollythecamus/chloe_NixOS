#!/usr/bin/env python3
"""F05 — session/power menu: lock, logout, reboot, power-off.

No suspend/hibernate: s2idle resume is broken on this machine. Disruptive
actions show the exact effect and require typing "yes" — Return alone cancels.
Targets are a fixed allowlist; menu items map to these constants only.
"""
import subprocess
import sys

LOCK = ["swaylock", "-f"]
LOGOUT = ["swaymsg", "exit"]
REBOOT = ["systemctl", "reboot"]
POWEROFF = ["systemctl", "poweroff"]

CONFIRM_WORD = "yes"


def menu(items):
    lines = [f"{key} — {label}" for key, label in items]
    text = "\n".join(lines)
    r = subprocess.run(
        ["wofi", "--dmenu", "--prompt", "session", "--cache-file", "/dev/null",
         "--width", "300", "--height", "180"],
        input=text, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        return None
    chosen = r.stdout.strip().split(" — ", 1)
    return chosen[0] if chosen else None


def confirm(question):
    print(question)
    print(f"type '{CONFIRM_WORD}' to proceed, anything else to cancel:")
    try:
        answer = input().strip()
    except EOFError:
        return False
    return answer == CONFIRM_WORD


def dispatch(key):
    if key == "l":
        subprocess.run(LOCK, check=False)
        return 0
    if key == "o":
        if confirm("This logs out of the Sway session and closes all windows."):
            subprocess.run(LOGOUT, check=False)
            return 0
        return 0
    if key == "r":
        if confirm("This REBOOTS the machine now."):
            subprocess.run(REBOOT, check=False)
            return 0
        return 0
    if key == "p":
        if confirm("This POWERS OFF the machine now."):
            subprocess.run(POWEROFF, check=False)
            return 0
        return 0
    if key is None:
        return 0
    return 2


ACTIONS = [
    ("l", "Lock screen"),
    ("o", "Log out"),
    ("r", "Reboot (confirm)"),
    ("p", "Power off (confirm)"),
]


def main():
    key = menu(ACTIONS)
    return dispatch(key)


if __name__ == "__main__":
    sys.exit(main())
