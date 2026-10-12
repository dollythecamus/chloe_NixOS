"""Regressions for panel telemetry, window icons and overflow routing."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "dotfiles/config/mission-control"
sys.path.insert(0, str(SOURCE))
import status
import workspace_guard as guard


def win(identifier, app="kitty", name="terminal"):
    return {"id": identifier, "type": "con", "app_id": app, "name": name, "nodes": []}


def ws(number, *windows, floats=()):
    return {"type": "workspace", "num": number, "nodes": list(windows),
            "floating_nodes": list(floats)}


class WorkspaceTests(unittest.TestCase):
    def test_sidebar_is_a_text_command_surface_not_a_mouse_control_panel(self):
        yuck = (SOURCE / "eww.yuck").read_text()
        for widget in ("button", "scale", "progress", "scroll"):
            self.assertNotIn(f"({widget} ", yuck)
        for hint in ("[BS] STATUS", "[N] NET", "[M] AUDIO", "SHIFT+N", "CTRL+N",
                     "[ / ]", "SHIFT+M", "CTRL+M", "SHIFT+A"):
            self.assertIn(hint, yuck)
        self.assertIn(':text {network.report', yuck)
        self.assertIn(':text {audio.report', yuck)
        self.assertEqual(yuck.count(':focusable false'), 2)

    def test_widget_navigation_restores_theme_and_has_a_keyboard_home_route(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            eww = root / "eww"
            eww.write_text('#!/bin/sh\nif [ "$3" = active-windows ]; then\n'
                           '  printf "%s" "$EWW_ACTIVE"\nelse\n  printf "%s\\n" "$*"\nfi\n')
            eww.chmod(0o755)
            state = root / "state/mission-control"
            state.mkdir(parents=True)
            (state / "theme").write_text("dark\n")
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ["PATH"],
                       XDG_STATE_HOME=str(root / "state"), XDG_CONFIG_HOME=str(root / "config"))
            for view, active in (("home", ""), ("network", ""), ("audio", "expanded: expanded")):
                with self.subTest(view=view):
                    result = subprocess.run(["bash", str(SOURCE / "control.sh"), "widget", view],
                                            capture_output=True, text=True, check=True,
                                            env=dict(env, EWW_ACTIVE=active)).stdout
                    self.assertIn(f"update view={view} dark=true", result)
                    if not active:
                        self.assertIn("open compact", result)
                    else:
                        self.assertNotIn("open compact", result)
                    self.assertIn(f"poll {'status' if view == 'home' else view}", result)
                    self.assertNotIn("poll home", result)

    def test_theme_change_reloads_css_after_updating_the_theme_variable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            eww = root / "eww"
            eww.write_text('#!/bin/sh\nprintf "%s\\n" "$*"\n')
            eww.chmod(0o755)
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ["PATH"],
                       XDG_STATE_HOME=str(root / "state"), XDG_CONFIG_HOME=str(root / "config"),
                       XDG_RUNTIME_DIR="")
            for value in ("true", "false"):
                result = subprocess.run(["bash", str(SOURCE / "control.sh"), "theme"],
                                        capture_output=True, text=True, check=True, env=env).stdout
                self.assertIn(f"update dark={value}", result)
                self.assertIn("reload", result)
                self.assertLess(result.index("update"), result.index("reload"))

    def test_sway_binds_every_visible_system_command(self):
        sway = (SOURCE.parents[2] / "sway.nix").read_text()
        for key, command in {
            "Mod4+BackSpace": "widget home", "Mod4+n": "widget network",
            "Mod4+m": "widget audio", "Mod4+Control+n": "action wifi-toggle",
            "Mod4+bracketleft": "action volume-down", "Mod4+bracketright": "action volume-up",
            "Mod4+Shift+m": "action sink-mute", "Mod4+Control+m": "action source-mute",
            "XF86AudioMicMute": "action source-mute", "XF86AudioRaiseVolume": "action volume-up",
        }.items():
            self.assertIn(f'"{key}" = "exec ${{control}} {command}";', sway)
        self.assertIn('${pkgs.networkmanager}/bin/nmtui', sway)
        self.assertNotIn('${pkgs.networkmanagerapplet}/bin/nm-connection-editor', sway)

    def test_keys_dispatches_to_kitty_pager(self):
        with tempfile.TemporaryDirectory() as directory:
            kitty = Path(directory) / "kitty"
            kitty.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            kitty.chmod(0o755)
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ["PATH"])
            output = subprocess.run(["bash", str(SOURCE / "control.sh"), "keys"],
                                    capture_output=True, text=True, env=env, check=True).stdout
            self.assertIn("--title\nmission-keys\nless\n", output)
            self.assertIn("/mission-control/keys.txt", output)

    def test_eww_polls_use_exported_home_not_eww_expression_variable(self):
        yuck = (SOURCE / "eww.yuck").read_text()
        poll_lines = [line for line in yuck.splitlines() if line.startswith("(defpoll")]
        self.assertEqual(len(poll_lines), 6)
        self.assertIn("$HOME/.config/mission-control/widgets.py network", poll_lines[0])
        self.assertIn("$HOME/.config/mission-control/widgets.py audio", poll_lines[1])
        self.assertTrue(all("$HOME/.config/mission-control/status.py" in line
                            for line in poll_lines[2:5]))

    def test_new_third_goes_to_next_workspace_with_room(self):
        tree = {"type": "root", "nodes": [ws(1, win(1), win(2), win(3)),
                                           ws(2, win(4), win(5)), ws(3, win(6))]}
        self.assertEqual(guard.relocation(tree, 3), 3)
        self.assertIsNone(guard.relocation(
            {"type": "root", "nodes": [ws(1, win(1), win(2))]}, 2))
        self.assertIsNone(guard.relocation(tree, 999))

    def test_floating_and_nested_containers(self):
        nested = {"type": "con", "nodes": [win(1), win(2)]}
        tree = {"type": "root", "nodes": [ws(1, nested, win(3), floats=[win(4)])]}
        self.assertEqual(guard.relocation(tree, 3), 2)
        self.assertIsNone(guard.relocation(tree, 4))

    def test_creative_auxiliary_windows_stay_on_editor_workspace(self):
        for app in ("Unity", "krita", "org.kde.krita", "lmms",
                    "io.lmms.LMMS", "Godot", "Godot_Editor", "Godot_Engine",
                    "Godot_ProjectManager", "org.godotengine.Godot"):
            with self.subTest(app=app):
                tree = {"type": "root", "nodes": [ws(1, win(1), win(2), win(3, app))]}
                self.assertIsNone(guard.relocation(tree, 3))

    def test_xwayland_creative_windows_use_class_or_instance(self):
        for properties in ({"class": "Unity", "instance": "Unity"},
                           {"class": "krita"}, {"instance": "lmms"},
                           {"class": "Godot_Editor"}):
            with self.subTest(properties=properties):
                auxiliary = dict(win(3), app_id=None, window=300,
                                 window_properties=properties)
                tree = {"type": "root", "nodes": [ws(1, win(1), win(2), auxiliary)]}
                self.assertIsNone(guard.relocation(tree, 3))

    def test_creative_rules_scope_unity_selectors_to_unity(self):
        rules = SOURCE / "creative-windows.conf"
        self.assertTrue(rules.is_file(), "creative-app floating rules are missing")
        lines = rules.read_text().splitlines()
        unity_selectors = [line for line in lines if line.startswith("for_window")
                           and ('UnityEditor' in line or 'Gradient Editor' in line)]
        self.assertTrue(unity_selectors)
        self.assertTrue(all('class="(?i)^Unity$"' in line for line in unity_selectors))
        self.assertFalse(any('resize set' in line for line in lines))

    def test_panel_shows_focus_and_window_icons(self):
        tree = {"type": "root", "nodes": [ws(1, win(1)),
                                           ws(2, win(2, name="mission-pet")),
                                           ws(3, win(3, name="mission-orbits"))]}
        spaces = [{"num": 1, "focused": False}, {"num": 2, "focused": True}]
        def fake_run(*args):
            return json.dumps(tree if "get_tree" in args else spaces)
        with patch.object(status, "run", fake_run):
            rows = status.workspaces()
        # The current panel is a horizontal number row with icons below it.
        # The old assertions described the superseded vertical list.
        number_row, icon_row = rows.splitlines()
        self.assertIn("○ 1", number_row)
        self.assertIn("● 2", number_row)
        self.assertIn("○ 9", number_row)
        self.assertEqual(icon_row.split(), [">_", "♥", "◎"])

    def test_real_telemetry_has_fields(self):
        data = status.metrics()
        self.assertEqual(set(data), {"battery", "cpu", "memory", "disk", "audio"})
        self.assertTrue(all(value for value in data.values()))


if __name__ == "__main__":
    unittest.main()
