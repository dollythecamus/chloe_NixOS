"""Mission-control network/audio data and action boundaries."""
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "dotfiles/config/mission-control/widgets.py"
spec = importlib.util.spec_from_file_location("mission_widgets", SCRIPT)
widgets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(widgets)


class WidgetTests(unittest.TestCase):
    def test_network_report_is_a_compact_terminal_readout(self):
        data = {"wifi": True, "profiles": [{"name": "Cafe:West", "active": True}],
                "available": [{"ssid": "Cafe:West", "signal": "78", "security": "WPA2"}]}
        self.assertEqual(widgets.network_report(data),
                         "RADIO   ON\n\nSAVED // > ACTIVE\n> Cafe:West\n\n"
                         "NEARBY // CACHED\nSSID                   RX AUTH\n"
                         f"{'Cafe:West':<22}  78% WPA2")

    def test_network_report_bounds_rows_and_sanitizes_names_with_active_first(self):
        profiles = [{"name": "Guest" + str(i), "active": False} for i in range(12)]
        profiles.append({"name": "ACTIVE\n\t\x1b" + "x" * 80, "active": True})
        access = {"ssid": "Cafe\n\t\x1b" + "x" * 80, "signal": "78", "security": "WPA2 WPA3"}
        report = widgets.network_report({"wifi": True, "profiles": profiles, "available": [access] * 8})
        self.assertIn("> ACTIVE???", report)
        self.assertNotIn("Guest4", report)
        self.assertIn("SHIFT+N for all", report)
        self.assertEqual(report.count("Cafe???"), 5)
        self.assertNotIn("\x1b", report)
        self.assertNotIn("\t", report)
        self.assertLessEqual(max(map(len, report.splitlines())), 36)
        self.assertLessEqual(len(report.splitlines()), 18)

    def test_network_report_bounds_wide_unicode_saved_name_as_ascii(self):
        uuid = "94162cc7-eafa-4204-9641-c12519613134"
        name = "\U0001f600" * 30
        with patch.object(widgets, "run", side_effect=[
                "enabled", f"{uuid}:{name}:802-11-wireless", f"{uuid}:802-11-wireless", ""]):
            data = widgets.network()
        report = widgets.network_report(data)
        payload = json.loads(json.dumps(dict(data, report=report)))
        self.assertEqual(payload["profiles"], [{"uuid": uuid, "name": name, "active": True}])
        saved_row = report.splitlines()[3]
        self.assertEqual(saved_row, "> " + (r"\U0001f600" * 30)[:27] + "...")
        self.assertTrue(report.isascii())
        self.assertLessEqual(len(saved_row), 32)

    def test_network_report_aligns_valid_multibyte_ssids_as_ascii(self):
        ssid = "\u754c" * 10
        short_ssid = "\u754c"
        self.assertEqual(len(ssid.encode("utf-8")), 30)
        with patch.object(widgets, "run", side_effect=[
                "enabled", "", "", f"*:{ssid}:78:WPA2\n:{short_ssid}:78:WPA2"]):
            data = widgets.network()
        report = widgets.network_report(data)
        payload = json.loads(json.dumps(dict(data, report=report)))
        self.assertEqual([access["ssid"] for access in payload["available"]], [ssid, short_ssid])
        long_row, short_row = report.splitlines()[-2:]
        escaped_ssid = (r"\u754c" * 10)[:19] + "..."
        escaped_short_ssid = r"\u754c"
        self.assertEqual(long_row, f"{escaped_ssid:<22}  78% WPA2")
        self.assertEqual(short_row, f"{escaped_short_ssid:<22}  78% WPA2")
        self.assertEqual(long_row.index("78%"), short_row.index("78%"))
        self.assertEqual(long_row.index("WPA2"), short_row.index("WPA2"))
        self.assertTrue(report.isascii())
        self.assertLessEqual(max(map(len, report.splitlines())), 36)

    def test_network_report_distinguishes_missing_manager_from_radio_off(self):
        data = {"wifi": False, "profiles": [], "available": [], "error": "NetworkManager unavailable"}
        self.assertEqual(widgets.network_report(data), "RADIO   --\nSTATE   NetworkManager unavailable")
        data.pop("error")
        self.assertIn("RADIO   OFF", widgets.network_report(data))
        self.assertIn("(none)", widgets.network_report(data))

    def test_network_parses_escaped_profile_names_without_running_them(self):
        uuid = "94162cc7-eafa-4204-9641-c12519613134"
        def output(*args):
            if "--active" in args:
                return f"{uuid}:802-11-wireless"
            if "connection" in args:
                return f"{uuid}:Cafe\\:West:802-11-wireless\nignored:lo:loopback"
            if "general" in args:
                return "enabled"
            if "-f" in args:
                return "*:Cafe\\:West:78:WPA2\n:Guest:48:--"
            return "Cafe:West"
        with patch.object(widgets, "run", side_effect=output):
            data = widgets.network()
        self.assertEqual(data["profiles"], [{"uuid": uuid, "name": "Cafe:West", "active": True}])
        self.assertEqual(data["available"][0]["ssid"], "Cafe:West")
        self.assertEqual(data["available"][1]["ssid"], "Guest")
        self.assertTrue(data["wifi"])

    def test_scan_failure_preserves_radio_and_saved_profiles(self):
        import subprocess
        uuid = "94162cc7-eafa-4204-9641-c12519613134"
        def output(*args):
            if "general" in args:
                return "enabled"
            if "--active" in args:
                return ""
            if "connection" in args:
                return f"{uuid}:Home:802-11-wireless"
            raise subprocess.CalledProcessError(1, args)
        with patch.object(widgets, "run", side_effect=output):
            data = widgets.network()
        self.assertTrue(data["wifi"])
        self.assertEqual(data["profiles"][0]["uuid"], uuid)
        self.assertEqual(data["available"], [])

    def test_wifi_toggle_reads_only_radio_state(self):
        import subprocess
        def output(*args):
            if "general" in args:
                return "enabled"
            if "radio" in args:
                return ""
            raise subprocess.CalledProcessError(1, args)
        with patch.object(widgets, "run", side_effect=output) as run:
            widgets.action("wifi-toggle")
        self.assertEqual(run.call_args_list[-1].args, ("nmcli", "radio", "wifi", "off"))

    def test_connect_works_if_access_point_scan_fails(self):
        import subprocess
        uuid = "94162cc7-eafa-4204-9641-c12519613134"
        def output(*args, **kwargs):
            if "connection" in args and "up" in args:
                return ""
            if "connection" in args and "--active" in args:
                return ""
            if "connection" in args:
                return f"{uuid}:Home:802-11-wireless"
            raise subprocess.CalledProcessError(1, args)
        with patch.object(widgets, "run", side_effect=output) as run:
            widgets.action("connect", uuid)
        self.assertEqual(run.call_args_list[-1].args, ("nmcli", "connection", "up", "uuid", uuid))

    def test_disabled_wifi_still_shows_saved_profiles(self):
        uuid = "94162cc7-eafa-4204-9641-c12519613134"
        def output(*args):
            if "general" in args:
                return "disabled"
            if "--active" in args:
                return ""
            if "connection" in args:
                return f"{uuid}:Home:802-11-wireless"
            raise RuntimeError("Wi-Fi scan must not run with radio disabled")
        with patch.object(widgets, "run", side_effect=output):
            data = widgets.network()
        self.assertFalse(data["wifi"])
        self.assertEqual(data["profiles"][0]["name"], "Home")
        self.assertEqual(data["available"], [])

    def test_wifi_toggle_off_does_not_query_access_points(self):
        with patch.object(widgets, "wifi_state", return_value=True), patch.object(widgets, "run", return_value="") as run:
            widgets.action("wifi-toggle")
        run.assert_called_once_with("nmcli", "radio", "wifi", "off")

    def test_audio_report_uses_ascii_gauges_with_explicit_mute_state(self):
        data = {"sink": 60, "sink_muted": False, "sink_available": True,
                "source": 26, "source_muted": True, "source_available": True}
        self.assertEqual(widgets.audio_report(data),
                         "OUTPUT  60% LIVE\n        [######....]\n\n"
                         "INPUT   26% MUTED\n        [##........]")

    def test_audio_report_bounds_overamplified_gauge_and_marks_missing_device(self):
        data = {"sink": 150, "sink_muted": True, "sink_available": True,
                "source": 0, "source_muted": False, "source_available": False}
        report = widgets.audio_report(data)
        self.assertIn("OUTPUT 150% MUTED", report)
        self.assertIn("[##########]", report)
        self.assertIn("INPUT   -- // NO DEVICE", report)

    def test_cli_reports_are_derived_from_real_read_only_telemetry(self):
        import json
        import subprocess
        import sys
        for command, formatter in (("network", widgets.network_report), ("audio", widgets.audio_report)):
            with self.subTest(command=command):
                output = subprocess.run([sys.executable, str(SCRIPT), command], check=True,
                                        capture_output=True, text=True, timeout=40).stdout
                data = json.loads(output)
                self.assertIn("report", data)
                self.assertEqual(data["report"], formatter(data))

    def test_audio_parses_muted_and_missing_devices(self):
        with patch.object(widgets, "run", side_effect=["Volume: 0.90 [MUTED]", ""]):
            self.assertEqual(widgets.audio(), {"sink": 90, "sink_muted": True, "source": 0, "source_muted": False, "source_available": False, "sink_available": True})

    def test_connect_rejects_untrusted_identifier_without_invoking_nmcli(self):
        with patch.object(widgets, "run") as run:
            with self.assertRaises(ValueError):
                widgets.action("connect", "$(touch /tmp/unsafe)")
            run.assert_not_called()

    def test_volume_rejects_out_of_range_and_non_numeric(self):
        with patch.object(widgets, "run") as run:
            for value in ("-1", "101", "nan", "10;true"):
                with self.assertRaises(ValueError):
                    widgets.action("volume", value)
            run.assert_not_called()

    def test_volume_uses_wpctl_default_sink_and_integer_percent(self):
        with patch.object(widgets, "run", return_value="") as run:
            widgets.action("volume", "35")
        run.assert_called_once_with("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "35%")

    def test_volume_step_is_bounded_to_five_percent(self):
        with patch.object(widgets, "run", return_value="") as run:
            widgets.action("volume-up")
            widgets.action("volume-down")
        self.assertEqual(run.call_args_list[0].args, ("wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"))
        self.assertEqual(run.call_args_list[1].args, ("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"))

    def test_connect_requires_saved_wifi_uuid(self):
        with patch.object(widgets, "saved_profiles", return_value=[]), patch.object(widgets, "run") as run:
            with self.assertRaises(ValueError):
                widgets.action("connect", "94162cc7-eafa-4204-9641-c12519613134")
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
