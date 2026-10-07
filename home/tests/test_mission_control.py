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
