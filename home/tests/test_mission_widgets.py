"""Mission-control network/audio data and action boundaries."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "dotfiles/config/mission-control/widgets.py"
spec = importlib.util.spec_from_file_location("mission_widgets", SCRIPT)
widgets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(widgets)


class WidgetTests(unittest.TestCase):
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
