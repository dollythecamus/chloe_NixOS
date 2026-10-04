#!/usr/bin/env python3
"""Test creative rules and the guard in isolated headless Sway/XWayland.

Xterm clients with synthetic WM_CLASS/titles prove matching, NOT application
panel docking, tablet input, or the NVIDIA renderer. Requires TMPDIR.
--without-rules is a negative control: Unity's Color selector must fail.
"""
import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import time

SOURCE = Path(__file__).resolve().parents[1] / "dotfiles/config/mission-control"


def wait_for(check, message, timeout=15):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = check()
        if result:
            return result
        time.sleep(0.05)
    raise AssertionError(message)


def leaves(node, workspace=-1, floating=False):
    if node.get("type") == "workspace":
        workspace = node.get("num", -1)  # scratchpad has no num
    if node.get("window"):
        yield node, workspace, floating
    for child in node.get("nodes", []):
        yield from leaves(child, workspace, floating)
    for child in node.get("floating_nodes", []):
        yield from leaves(child, workspace, True)


def run(args):
    # sockaddr_un paths have a small fixed limit; this profile's TMPDIR is long.
    with tempfile.TemporaryDirectory(prefix="", dir=os.environ["TMPDIR"]) as directory:
        root = Path(directory)
        runtime = root / "r"
        runtime.mkdir(mode=0o700)
        display_file = root / "display"
        config = root / "config"
        commands = ["output HEADLESS-1 mode 1920x1080", "xwayland force",
                    "seat seat0 fallback true", "focus_follows_mouse no",
                    "exec " + shlex.join(["sh", "-c", 'printf %s "$DISPLAY" > ' + shlex.quote(str(display_file))])]
        if not args.without_rules:
            commands.append("include " + str(SOURCE / "creative-windows.conf"))
        config.write_text("\n".join(commands) + "\n")
        env = dict(os.environ, XDG_RUNTIME_DIR=str(runtime), HOME=directory,
                   XDG_CONFIG_HOME=directory, WLR_BACKENDS="headless", WLR_HEADLESS_OUTPUTS="1",
                   WLR_RENDERER="pixman", WLR_LIBINPUT_NO_DEVICES="1",
                   PYTHONDONTWRITEBYTECODE="1")
        for variable in ("DISPLAY", "WAYLAND_DISPLAY", "SWAYSOCK", "NIRI_SOCKET"):
            env.pop(variable, None)
        swaymsg = str(Path(args.sway).with_name("swaymsg"))
        env["PATH"] = str(Path(args.sway).parent) + os.pathsep + env["PATH"]
        processes = []
        with (root / "sway.log").open("w+") as log:
            try:
                processes.append(subprocess.Popen([args.sway, "-c", str(config)], env=env,
                                                   stdout=log, stderr=log))
                socket = wait_for(lambda: next(runtime.glob("sway-ipc.*.sock"), None),
                                  "headless Sway did not create its IPC socket")
                wait_for(lambda: display_file.exists() and display_file.read_text(),
                         "XWayland did not publish DISPLAY")
                env["SWAYSOCK"] = str(socket)
                env["DISPLAY"] = display_file.read_text()

                def ipc(command, kind="command"):
                    result = subprocess.run([swaymsg, "-s", str(socket), "-r", "-t", kind, command],
                                            capture_output=True, text=True, check=True, timeout=5)
                    return json.loads(result.stdout)

                def state(pid):
                    return next((value for value in leaves(ipc("", "get_tree"))
                                 if value[0].get("pid") == pid), None)

                def create(title, app="Unity"):
                    process = subprocess.Popen([args.xterm, "-class", app, "-name", app,
                                                "-title", title, "-fa", "monospace", "-fs", "10",
                                                "-hold", "-e", "true"],
                                               env=env, stdout=log, stderr=log)
                    processes.append(process)
                    wait_for(lambda: state(process.pid), "Xterm test window was not mapped")
                    return process.pid

                for title, app, expected_float in (
                    ("Sample - Scene - Unity 6", "Unity", False),
                    ("Color", "Unity", True),
                    ("UnityEditor.PopupWindow", "Unity", True),
                    ("Inspector", "Unity", True),
                    ("Color", "OtherApp", False),
                    ("Untitled - Krita", "krita", False),
                    ("LMMS", "lmms", False),
                    ("Godot", "Godot_Editor", False),
                ):
                    pid = create(title, app)
                    value = state(pid)
                    assert value is not None
                    assert value[2] == expected_float, (title, app, value[2], expected_float)
                    print(f"PASS rule: {app} / {title}: {'floating' if value[2] else 'tiled'}")

                for executable in args.launcher:
                    result = subprocess.run([executable, "--version"],
                                            env=dict(env, QT_QPA_PLATFORM="wayland"),
                                            capture_output=True, text=True, timeout=45)
                    assert result.returncode == 0, (executable, result.stdout, result.stderr)
                    print(f"PASS launcher: {Path(executable).name}: {result.stdout.strip()[:400]}")

                processes.append(subprocess.Popen([sys.executable, str(SOURCE / "workspace_guard.py")],
                                                   env=env, stdout=log, stderr=log))
                # A positive ordinary-window relocation proves the subscription is active.
                ipc("workspace number 10")
                create("ordinary 1", "OtherApp")
                create("ordinary 2", "OtherApp")
                third = create("ordinary 3", "OtherApp")
                wait_for(lambda: (value := state(third)) is not None and value[1] == 11,
                         "ordinary third window was not relocated")
                ipc("workspace number 10")
                temporary = create("Unity", "Unity")
                deadline = time.monotonic() + 1
                while time.monotonic() < deadline:
                    value = state(temporary)
                    assert value is not None and value[1] == 10, "Unity drag window was relocated"
                    time.sleep(0.05)
                print("PASS live guard: ordinary third window moved; Unity drag window stayed")
            except Exception:
                log.flush()
                log.seek(0)
                print(log.read()[-6000:])
                raise
            finally:
                for process in reversed(processes):
                    if process.poll() is None:
                        process.terminate()
                        try:
                            process.wait(timeout=5)
                        except subprocess.TimeoutExpired:
                            process.kill()
                            process.wait(timeout=5)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sway", required=True)
    parser.add_argument("--xterm", required=True)
    parser.add_argument("--without-rules", action="store_true")
    parser.add_argument("--launcher", action="append", default=[],
                        help="built compatibility executable to smoke-test with --version")
    run(parser.parse_args())
