#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Find the area a coordinate is in, from a boundary package.

Usage:
    uv run data/scripts/locate.py LAT LON [--package data/boundaries/14.json] [--near METRES]

This is the reference for the app's on-device lookup: plain arithmetic on the
package, no geometry library. It prints the area that contains the point and
every other area within --near metres (default 50), nearest first.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent
METRES_PER_DEGREE = 111_320.0  # of latitude; longitude is scaled by cos(latitude)


class Package:
    """A boundary package with its arcs decoded into rings per area."""

    def __init__(self, document: dict):
        self.document = document
        topology = document["topology"]
        (sx, sy), (tx, ty) = topology["transform"]["scale"], topology["transform"]["translate"]
        arcs = []
        for arc in topology["arcs"]:  # each arc is delta-encoded integer steps
            x = y = 0
            points = []
            for dx, dy in arc:
                x, y = x + dx, y + dy
                points.append((x * sx + tx, y * sy + ty))
            arcs.append(points)

        def ring(indexes: list[int]) -> list[tuple[float, float]]:
            points: list[tuple[float, float]] = []
            for i in indexes:  # a negative index means the arc ~i, walked backwards
                part = arcs[i] if i >= 0 else arcs[~i][::-1]
                points.extend(part[1:] if points else part)
            return points

        self.areas = []
        for geometry in topology["objects"]["areas"]["geometries"]:
            polygons = geometry["arcs"] if geometry["type"] == "MultiPolygon" else [geometry["arcs"]]
            rings = [ring(r) for polygon in polygons for r in polygon]
            xs = [x for r in rings for x, _ in r]
            ys = [y for r in rings for _, y in r]
            self.areas.append(
                {
                    "id": geometry["id"],
                    "name": geometry["properties"]["name"],
                    "rings": rings,
                    "bbox": (min(xs), min(ys), max(xs), max(ys)),
                }
            )

    def locate(self, lat: float, lon: float, near: float = 50.0) -> dict:
        """The containing area (or None) and the other areas within `near` metres, nearest first."""
        kx = METRES_PER_DEGREE * math.cos(math.radians(lat))
        pad_x, pad_y = near / kx, near / METRES_PER_DEGREE
        inside, nearby = None, []
        for area in self.areas:
            w, s, e, n = area["bbox"]
            if not (w - pad_x <= lon <= e + pad_x and s - pad_y <= lat <= n + pad_y):
                continue
            if inside is None and contains(area["rings"], lon, lat):
                inside = area
                continue
            distance = border_distance(area["rings"], lon, lat, kx)
            if distance <= near:
                nearby.append((distance, area))
        nearby.sort(key=lambda pair: pair[0])
        return {
            "area": describe(inside),
            "border_m": round(border_distance(inside["rings"], lon, lat, kx), 1) if inside else None,
            "nearby": [describe(a) | {"distance_m": round(d, 1)} for d, a in nearby],
        }


def describe(area: dict | None) -> dict | None:
    return {"id": area["id"], "name": area["name"]} if area else None


def contains(rings: list, x: float, y: float) -> bool:
    """Even-odd rule over every ring, so holes and multi-part areas need no special case."""
    inside = False
    for ring in rings:
        x1, y1 = ring[-1]
        for x2, y2 in ring:
            if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                inside = not inside
            x1, y1 = x2, y2
    return inside


def border_distance(rings: list, x: float, y: float, kx: float) -> float:
    """Metres from the point to the nearest edge of the area."""
    best = math.inf
    for ring in rings:
        ax, ay = (ring[-1][0] - x) * kx, (ring[-1][1] - y) * METRES_PER_DEGREE
        for px, py in ring:
            bx, by = (px - x) * kx, (py - y) * METRES_PER_DEGREE
            dx, dy = bx - ax, by - ay
            length = dx * dx + dy * dy
            t = 0.0 if length == 0 else max(0.0, min(1.0, -(ax * dx + ay * dy) / length))
            best = min(best, math.hypot(ax + t * dx, ay + t * dy))
            ax, ay = bx, by
    return best


def load(path: Path) -> Package:
    return Package(json.loads(path.read_text(encoding="utf-8")))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("lat", type=float)
    parser.add_argument("lon", type=float)
    parser.add_argument("--package", type=Path, default=DATA_DIR / "boundaries" / "14.json")
    parser.add_argument("--near", type=float, default=50.0)
    args = parser.parse_args()
    print(json.dumps(load(args.package).locate(args.lat, args.lon, args.near), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
