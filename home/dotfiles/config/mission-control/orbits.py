#!/usr/bin/env python3
"""On-demand heliocentric terminal plot. Horizons vectors, not simulated orbits.

Positions are samples at UTC midnight in the ecliptic J2000 plane. A sampled
one-year path is NOT a full orbit for outer planets. No background refresh.
"""
import argparse
import csv
from datetime import datetime, timedelta, timezone
import json
import math
import os
from pathlib import Path
import sys
import tempfile
from urllib.parse import urlencode
from urllib.request import urlopen

ENDPOINT = "https://ssd.jpl.nasa.gov/api/horizons.api"
BODIES = {"Mercury": (199, "m"), "Venus": (299, "V"), "Earth": (399, "E"),
          "Mars": (499, "M"), "Jupiter": (599, "J"), "Saturn": (699, "S")}


def parse_vectors(text):
    """Parse only Horizons CSV VECTORS records, rejecting malformed responses."""
    if "$$SOE" not in text or "$$EOE" not in text:
        raise ValueError("Horizons response has no ephemeris block")
    block = text.split("$$SOE", 1)[1].split("$$EOE", 1)[0]
    rows = []
    for cols in csv.reader(block.strip().splitlines()):
        if len(cols) < 8:
            raise ValueError("incomplete Horizons vector row")
        values = [float(s) for s in cols[2:8]]
        if not all(map(math.isfinite, values)):
            raise ValueError("non-finite Horizons vector")
        rows.append([cols[1].strip(), *values])
    if not rows:
        raise ValueError("empty Horizons vector block")
    return rows


def fetch(body_id, day):
    params = {"format": "json", "COMMAND": f"'{body_id}'", "CENTER": "'500@10'",
              "MAKE_EPHEM": "'YES'", "EPHEM_TYPE": "'VECTORS'",
              "START_TIME": f"'{day.isoformat()}'",
              "STOP_TIME": f"'{(day + timedelta(days=365)).isoformat()}'",
              "STEP_SIZE": "'5d'", "OUT_UNITS": "'AU-D'",
              "REF_PLANE": "'ECLIPTIC'", "TIME_TYPE": "'UT'",
              "VEC_TABLE": "'2'", "CSV_FORMAT": "'YES'"}
    url = ENDPOINT + "?" + urlencode(params)
    with urlopen(url, timeout=25) as response:
        payload = json.load(response)
    if payload.get("error"):
        raise ValueError(payload["error"])
    return {"url": url, "vectors": parse_vectors(payload["result"])}


def cache_path(day):
    root = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    return root / "mission-control" / f"horizons-{day.isoformat()}.json"


def load(day, offline=False):
    path = cache_path(day)
    if path.is_file():
        return json.loads(path.read_text()), "daily cache"
    if offline:
        raise FileNotFoundError(f"no cache at {path}")
    data = {"date": day.isoformat(), "fetched_utc": datetime.now(timezone.utc).isoformat(),
            "bodies": {}}
    for name, (body_id, _) in BODIES.items():
        print(f"Fetching {name} from JPL Horizons…", file=sys.stderr)
        data["bodies"][name] = fetch(body_id, day)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as tmp:
        json.dump(data, tmp)
        tmp_name = tmp.name
    os.replace(tmp_name, path)
    return data, "JPL Horizons (new fetch)"


def pane(data, names, radius):
    width, height = 43, 19
    cx, cy = width // 2, height // 2
    grid = [[" " for _ in range(width)] for _ in range(height)]
    for name in names:
        vectors = data["bodies"][name]["vectors"]
        symbol = BODIES[name][1]
        for index, (_, x, y, *_rest) in enumerate(reversed(vectors)):
            gx = round(cx + x / radius * (cx - 1))
            gy = round(cy - y / radius * (cy - 1))
            if 0 <= gx < width and 0 <= gy < height:
                grid[gy][gx] = symbol if index == len(vectors) - 1 else "."
    grid[cy][cx] = "+"  # Sun
    return ["|" + "".join(row) + "|" for row in grid]


def render(data, source):
    stamp = data["date"] + " 00:00:00 UT"
    print("MISSION // ORBITAL VECTORS    JPL HORIZONS")
    print(f"Sample epoch: {stamp} | ecliptic J2000 | AU / AU·day⁻¹")
    print(f"Source: {source}; fetched {data['fetched_utc']}; sampled 5d ahead for 365d")
    print("+ = Sun, uppercase/lowercase = current position, dots = sampled future path")
    print("INNER ±2 AU".ljust(46) + "OUTER ±12 AU")
    for left, right in zip(pane(data, ("Mercury", "Venus", "Earth", "Mars"), 2),
                           pane(data, ("Jupiter", "Saturn"), 12)):
        print(left + " " + right)
    print("BODY      X [AU]       Y [AU]       Z [AU]       r [AU]    speed [AU/day]")
    for name in BODIES:
        _, x, y, z, vx, vy, vz = data["bodies"][name]["vectors"][0]
        print(f"{name:<8} {x:>10.5f} {y:>12.5f} {z:>12.5f}"
              f" {math.sqrt(x*x+y*y+z*z):>12.5f} {math.sqrt(vx*vx+vy*vy+vz*vz):>12.6f}")
    print("Geometric Sun-relative ephemeris, NOT telemetry/live positions. Plot panes use")
    print("different scales; outer paths are arcs, not complete planetary orbits.")
    print("Data: https://ssd.jpl.nasa.gov/api/horizons.api (URLs in daily cache).")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--once", action="store_true", help="print and exit")
    parser.add_argument("--offline", action="store_true", help="use today's cached vectors only")
    args = parser.parse_args()
    while True:
        day = datetime.now(timezone.utc).date()
        try:
            data, source = load(day, args.offline)
        except (OSError, ValueError, KeyError, TypeError) as exc:
            print(f"Horizons unavailable: {exc}", file=sys.stderr)
            return 1
        print("\033[2J\033[H" if not args.once else "", end="")
        render(data, source)
        if args.once:
            return 0
        try:
            if input("[Enter] redraw cached view · [q] quit > ").strip().lower() == "q":
                return 0
        except (EOFError, KeyboardInterrupt):
            return 0


if __name__ == "__main__":
    sys.exit(main())
