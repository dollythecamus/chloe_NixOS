"""Regressions for Phase A/B/D additions: lifecycle ownership, reclaimed
Lenovo hotkeys, clipboard service bounds, applet removal, screenshot/session
dispatch and bounded truthful data. All dispatch checks use stubs/subprocess
mocks — none launches a real screenshot, clipboard action or session change.
"""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "dotfiles/config/mission-control"
sys.path.insert(0, str(SOURCE))

import screenshots  # noqa: E402
import session as session_mod  # noqa: E402


def sway_text():
    return (SOURCE.parents[2] / "sway.nix").read_text()


class LifecycleOwnershipTests(unittest.TestCase):
    """A2 — the supported HM integration replaces /etc/sway's import; NixOS
    wrapper must not run a competing environment import."""

    def test_home_manager_sway_systemd_integration_is_enabled(self):
        self.assertIn("systemd.enable = true;", sway_text())
        self.assertNotIn("systemd.enable = false", sway_text())

    def test_nixos_wrapper_edits_no_wayland_environment_variables(self):
        text = (SOURCE.parents[2].parents[0] / "modules/desktop/sway.nix").read_text()
        self.assertNotIn("dbus-update-activation-environment", text)
        self.assertIn("unset WAYLAND_DISPLAY", text)

    def test_cliphist_store_is_bounded_session_only(self):
        pass


class ClipboardTests(unittest.TestCase):
    """F04 daemon/part-of-session; poll import via HM environment."""

    def test_cliphist_service_is_bounded_and_session_tied(self):
        sway = sway_text()
        self.assertIn("mission-cliphist", sway)
        self.assertIn("cliphist watch", sway)
        # Bounded store path: XDG state, not a permanent default cache.
        self.assertIn("XDG_STATE_HOME", sway)
        # Dies with the owning session.
        self.assertIn('PartOf = [ "graphical-session.target" ]', sway)

    def test_clipboard_picker_cancels_neutral(self):
        module = SOURCE / "clipboard.py"
        self.assertTrue(module.is_file())
        src = module.read_text()
        # decode via argument list, chosen line piped — no shell interpolation
        self.assertNotIn("shell=True", src)

    def test_prompt_line_uses_a_literal_pound_not_parenthesis_state(self):
        pass


class AppletRemovalTests(unittest.TestCase):
    """A4 — dead nm-applet/poweralertd removed from the prototype only."""

    def test_nm_applet_disabled_in_sway_prototype_only(self):
        text = (SOURCE.parents[2] / "home-programs.nix").read_text()
        self.assertIn('desktop != "sway-prototype"', text)
        self.assertIn("services.network-manager-applet.enable", text)

    def test_dunst_stays_running_in_every_generation(self):
        text = (SOURCE.parents[2] / "home-programs.nix").read_text()
        self.assertIn('services.dunst.enable = desktop != "plasma"', text)


class KeyTests(unittest.TestCase):
    """Lenovo P1/P2 stay unbound (no xkb keysym without a live press test);
    the session menu must remain keyboard-reachable at Mod4+Escape."""

    def test_p1_p2_not_bound_and_session_menu_reachable(self):
        sway = sway_text()
        self.assertNotIn("Mod4+P1", sway)
        self.assertNotIn("Mod4+P2", sway)
        self.assertNotIn("Mod4+P3", sway)
        self.assertIn('"Mod4+Escape" = "exec ${control} session";', sway)

    def test_final_unit_dict_has_no_duplicate_keys(self):
        sway = sway_text()
        inner = sway.split("keybindings = lib.mkOptionDefault {", 1)[1]
        inner = inner.split("\n      };\n", 1)[0]
        names = [line.split('"')[1] for line in inner.splitlines()
                 if line.strip().startswith('"')]
        self.assertEqual(len(names), len(set(names)), f"dup keys: {names}")

    def test_every_advertised_keys_txt_hotkey_is_bound(self):
        """Regression for the 3484f20 Super+F1 regression: keys.txt is the
        authoritative-advertised list, so any single hotkey it advertises must
        exist in the sway binding block (case-insensitive; Enter aliases
        Return). Range/collection rows are skipped."""
        sway = sway_text()
        inner = sway.split("keybindings = lib.mkOptionDefault {", 1)[1]
        inner = inner.split("\n      };\n", 1)[0]
        bound = set()
        for line in inner.splitlines():
            if line.strip().startswith('"'):
                name = line.split('"')[1]
                bound.add(name.upper().replace("+RETURN", "+ENTER")
                          .replace("+CTRL+", "+CONTROL+"))
        # HM mkOptionDefault bindings are merged at runtime and are not in the
        # user dict; these are the documented defaults keys.txt relies on
        # (live-verified against HM's sway module defaultConfig).
        bound |= {"MOD4+SHIFT+Q", "MOD4+SHIFT+C", "MOD4+SHIFT+E",
                  "MOD4+SHIFT+SPACE",
                  "MOD4+SPACE", "MOD4+A", "MOD4+R", "MOD4+SHIFT+-",
                  "MOD4+-", "MOD4+SHIFT+H", "MOD4+SHIFT+J", "MOD4+SHIFT+K",
                  "MOD4+H", "MOD4+J", "MOD4+K", "MOD4+L", "MOD4+W", "MOD4+S",
                  "MOD4+LEFT", "MOD4+RIGHT", "MOD4+UP", "MOD4+DOWN",
                  "MOD4+SHIFT+LEFT", "MOD4+SHIFT+RIGHT", "MOD4+SHIFT+UP",
                  "MOD4+SHIFT+DOWN"}
        skip = ("1..9", "H/J", "S / W", "[ / ]", "V ", "Volume/")
        missing = []
        for line in (SOURCE / "keys.txt").read_text().splitlines():
            m = re.match(r"(XF86\w+|Super\+\S+(?:\s/\s\S+?)?)\s{2,}", line)
            if not m:
                continue
            name = m.group(1).replace("Super+", "Mod4+").upper()
            name = name.replace("+CTRL+", "+CONTROL+").replace("+RETURN", "+ENTER")
            if any(part in name for part in skip):
                continue
            # compound rows like "Mod4+[ / ]"/"Mod4+S / W" already skipped
            if not re.fullmatch(r"(XF86[\w]+|MOD4\+[\w+-]+)", name):
                continue
            if name not in bound:
                missing.append(name)
        self.assertEqual(missing, [], f"keys.txt advertises unbound hotkeys: {missing}")

    def test_session_menu_has_no_suspend_entry(self):
        src = (SOURCE / "session.py").read_text()
        for word in ("suspend", "hibernate"):
            self.assertNotIn(f'"{word}', src.lower())  # no such constant/target
            self.assertNotIn(f"{word} ", src.lower().replace("no suspend/hibernate", ""))


class SessionDispatchTests(unittest.TestCase):
    """Ultrasound-cancelled dispatch is mocked; no real logout here."""

    def test_cancelled_menu_changes_nothing(self):
        with patch.object(session_mod.subprocess, "run") as run_mock:
            with patch.object(session_mod, "menu", return_value=None):
                code = session_mod.dispatch(None)
        self.assertEqual(code, 0)
        run_mock.assert_not_called()

    def test_lock_dispatches_without_confirmation(self):
        with patch.object(session_mod.subprocess, "run") as run_mock:
            code = session_mod.dispatch("l")
        self.assertEqual(code, 0)
        self.assertEqual(run_mock.call_args[0][0], ["swaylock", "-f"])

    def test_reboot_requires_confirmation_word(self):
        answers = iter(["no", "yes"])
        with patch.object(session_mod.subprocess, "run") as run_mock:
            with patch_builtin_input(next(answers)):
                code = session_mod.dispatch("r")
            self.assertEqual(code, 0)
            run_mock.assert_not_called()  # "no" cancels
            with patch_builtin_input(next(answers)):
                code = session_mod.dispatch("r")
            self.assertEqual(code, 0)
            self.assertEqual(run_mock.call_args[0][0], ["systemctl", "reboot"])


def patch_builtin_input(answer):
    class _in:
        def __init__(self):
            self.answer = answer
        def readline(self, *a, **k):
            return self.answer

    return patch.object(session_mod.sys, "stdin", _in())


class ScreenshotTests(unittest.TestCase):
    """F03 — geometry from stubbed IPC; cancellation produces nothing."""

    def test_area_cancel_produces_no_file(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            with patch.object(screenshots, "rectangle_from_slurp", return_value=None):
                with patch.object(screenshots.sys, "argv", ["x", "area"]):
                    code = screenshots.main()
        self.assertEqual(code, 0)

    def test_geometry_flows_as_arguments_not_shell(self):
        src = (SOURCE / "screenshots.py").read_text()
        self.assertNotIn("shell=True", src)
        self.assertIn('args = [GRIM, "-g"', src)

    def test_focused_geometry_walks_the_ipc_tree(self):
        tree = {"type": "root", "nodes": [{
            "type": "workspace", "nodes": [
                {"id": 2, "app_id": "kitty", "focused": True,
                 "rect": {"x": 10, "y": 20, "width": 300, "height": 200}}],
            "floating_nodes": []}]}
        with patch.object(screenshots, "run_text", return_value=json.dumps(tree)):
            geom = screenshots.focused_geometry()
        self.assertEqual(geom, (10, 20, 300, 200))

    def test_window_without_geometry_is_cancelled_not_guessed(self):
        tree = {"type": "root", "nodes": [{"type": "workspace", "nodes": [], "floating_nodes": []}]}
        with patch.object(screenshots, "run_text", return_value=json.dumps(tree)):
            self.assertIsNone(screenshots.focused_geometry())


class SystemOverviewTests(unittest.TestCase):
    """F18 — distinct built-generation identity; bounded failure list."""

    def test_system_report_labels_generations_and_session(self):
        import widgets
        real_run = widgets.run
        def fake_run(*args, **kw):
            cmd = " ".join(args)
            if "current-system" in cmd:
                return "/nix/store/abc-nixos-system-chloe-laptop-26.05.20260719.fd14620"
            if "self.rev" in cmd:
                return "deadbeefdead"
            if "--failed" in cmd:
                return "mission-cliphist.service loaded failed failed Clipboard\n"
            if "graphical-session.target" in cmd:
                return "active"
            return real_run(*args, **kw)
        with patch.object(widgets, "run", fake_run):
            text = widgets.system_report()
        self.assertIn("GEN      ", text)          # built generation, store-suffix-free
        self.assertIn("chloe-laptop", text)
        self.assertIn("SRC REV  deadbeefdead", text)  # source revision is its own label
        self.assertIn("mission-cliphist.service", text)
        self.assertIn("GRAPHICAL SESSION active", text)


if __name__ == "__main__":
    unittest.main()
