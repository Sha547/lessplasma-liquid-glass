#!/usr/bin/env python3
"""Compute today's sunrise/sunset and print them as flat key=value lines.

Usage: sun.py [lat] [lon]

Uses the classic Sunrise/Sunset Algorithm (Edward W. Williams, as published
by the US Naval Observatory almanac), so no API key or network round trip
is needed for the calculation itself -- only for geolocation, and only when
lat/lon are left blank. That reuses the same ipinfo.io lookup weather-strip
already makes, for the same reason: the widget works with nothing configured.

Printing key=value keeps the QML side free of JSON parsing. Any failure
prints nothing and exits 0, so the widget keeps its last good data instead
of flashing an error.
"""
import json
import math
import sys
import urllib.request
from datetime import datetime, timedelta, timezone


def fetch(url, timeout=5):
    req = urllib.request.Request(url, headers={"User-Agent": "lessplasma-sun-times"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return json.load(response)


def locate():
    """(lat, lon, city) from the caller's public IP; empty strings on failure."""
    try:
        data = fetch("https://ipinfo.io/json")
    except Exception:
        return "", "", ""
    loc = data.get("loc", "")
    if "," not in loc:
        return "", "", data.get("city", "")
    lat, lon = loc.split(",")[:2]
    return lat.strip(), lon.strip(), data.get("city", "")


def sun_time(day_of_year, lat, lon, is_rise):
    """UTC decimal hour-of-day (0..24) of sunrise/sunset for the given
    day-of-year, or None if the sun doesn't cross the horizon that day
    (polar day/night). This is a clock reading only -- which UTC calendar
    date it belongs to is for the caller to resolve, since the same
    hour-of-day repeats every day."""
    lng_hour = lon / 15
    t = day_of_year + ((6 - lng_hour) / 24 if is_rise else (18 - lng_hour) / 24)

    m = (0.9856 * t) - 3.289
    l = m + (1.916 * math.sin(math.radians(m))) + (0.020 * math.sin(math.radians(2 * m))) + 282.634
    l %= 360

    ra = math.degrees(math.atan(0.91764 * math.tan(math.radians(l))))
    ra %= 360
    l_quadrant = math.floor(l / 90) * 90
    ra_quadrant = math.floor(ra / 90) * 90
    ra = (ra + (l_quadrant - ra_quadrant)) / 15

    sin_dec = 0.39782 * math.sin(math.radians(l))
    cos_dec = math.cos(math.asin(sin_dec))
    cos_h = (math.cos(math.radians(90.833)) - (sin_dec * math.sin(math.radians(lat)))) / \
            (cos_dec * math.cos(math.radians(lat)))

    if cos_h > 1 or cos_h < -1:
        return None

    h = (360 - math.degrees(math.acos(cos_h))) if is_rise else math.degrees(math.acos(cos_h))
    h /= 15

    local_t = h + ra - (0.06571 * t) - 6.622
    ut = local_t - lng_hour
    return ut % 24


def instant_for_local_date(local_date, lng_hour, hour_of_day):
    """The UTC instant with the given UTC hour-of-day whose *simulated local
    date* (its clock reading if you just add lngHour, ignoring real
    timezones/DST -- the same approximation used to pick day_of_year) equals
    `local_date`. Deliberately not "nearest to now": once the event has
    already happened locally (e.g. it's evening in Tokyo), the nearest
    candidate in absolute time would be tomorrow's, not today's."""
    for d in (-1, 0, 1):
        candidate = datetime(local_date.year, local_date.month, local_date.day, tzinfo=timezone.utc) \
            + timedelta(days=d, hours=hour_of_day)
        if (candidate + timedelta(hours=lng_hour)).date() == local_date:
            return candidate
    # Should be unreachable for any real lngHour (-12..14), but fall back to
    # the plain same-date candidate rather than raising.
    return datetime(local_date.year, local_date.month, local_date.day, tzinfo=timezone.utc) \
        + timedelta(hours=hour_of_day)


def main():
    argv = sys.argv[1:]
    lat = argv[0].strip() if len(argv) > 0 else ""
    lon = argv[1].strip() if len(argv) > 1 else ""

    city = ""
    if not lat or not lon:
        lat, lon, city = locate()
    if not lat or not lon:
        return 0

    lat_f, lon_f = float(lat), float(lon)
    today = datetime.now(timezone.utc)
    # The algorithm expects the day-of-year of the LOCATION's calendar day,
    # not UTC's -- using UTC's day-of-year directly can pick the wrong day
    # entirely for longitudes far from Greenwich (e.g. Tokyo, New Zealand).
    # There's no timezone name to consult, only coordinates, so approximate
    # the local date with solar time: UTC now shifted by lngHour.
    lng_hour = lon_f / 15
    local_approx = today + timedelta(hours=lng_hour)
    local_date = local_approx.date()
    day_of_year = local_approx.timetuple().tm_yday

    rise = sun_time(day_of_year, lat_f, lon_f, True)
    set_ = sun_time(day_of_year, lat_f, lon_f, False)

    out = []
    if city:
        out.append(f"city={city}")

    if rise is None or set_ is None:
        # Sun never rises or never sets today at this latitude.
        out.append("polar=1")
        print("\n".join(out))
        return 0

    sunrise = instant_for_local_date(local_date, lng_hour, rise)
    sunset = instant_for_local_date(local_date, lng_hour, set_)

    out.append(f"sunrise={sunrise.strftime('%Y-%m-%dT%H:%M:%SZ')}")
    out.append(f"sunset={sunset.strftime('%Y-%m-%dT%H:%M:%SZ')}")
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
