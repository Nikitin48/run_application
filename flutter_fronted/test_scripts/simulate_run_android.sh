#!/usr/bin/env bash
#
# Simulates a hexagonal running route on Android emulator via ADB.
# Sends GPS coordinates every 3 seconds along a regular hexagon (~100m radius).
# The route is closed (ends at the starting point). Runs 2 laps.
#
# Usage:
#   1. Start the Android emulator
#   2. Start a run in the app
#   3. Minimize the app (press Home)
#   4. Run this script: ./simulate_run_android.sh
#   5. After ~2 minutes, open the app and check if the route was recorded

set -e

CENTER_LAT=52.604314
CENTER_LNG=39.545575
RADIUS_M=100
INTERVAL=3
LAPS=2
POINTS_PER_SIDE=3

# ~meters per degree at this latitude
M_PER_DEG_LAT=111320
COS_LAT=$(echo "scale=10; c($CENTER_LAT * 3.14159265358979 / 180)" | bc -l)
M_PER_DEG_LNG=$(echo "scale=10; $M_PER_DEG_LAT * $COS_LAT" | bc -l)

RAD_LAT=$(echo "scale=10; $RADIUS_M / $M_PER_DEG_LAT" | bc -l)
RAD_LNG=$(echo "scale=10; $RADIUS_M / $M_PER_DEG_LNG" | bc -l)

# 6 vertices of regular hexagon (angles: 90, 30, -30, -90, -150, -210 = top, top-right, ...)
PI=$(echo "scale=10; 3.14159265358979" | bc -l)

hex_lat() {
    local idx=$1
    local angle=$(echo "scale=10; $PI / 2 + $idx * $PI / 3" | bc -l)
    echo "scale=8; $CENTER_LAT + $RAD_LAT * s($angle)" | bc -l
}

hex_lng() {
    local idx=$1
    local angle=$(echo "scale=10; $PI / 2 + $idx * $PI / 3" | bc -l)
    echo "scale=8; $CENTER_LNG + $RAD_LNG * c($angle)" | bc -l
}

send_location() {
    local la=$1
    local lo=$2
    adb emu geo fix "$lo" "$la" 150
    echo "[$(date +%H:%M:%S)] lat=$la lng=$lo"
}

lerp() {
    local from=$1 to=$2 t=$3
    echo "scale=8; $from + ($to - $from) * $t" | bc -l
}

echo "=== Android Background GPS Simulation ==="
echo "Route: hexagon (~${RADIUS_M}m radius) around ${CENTER_LAT}, ${CENTER_LNG}"
echo "Laps: $LAPS | Interval: ${INTERVAL}s | Points per side: $POINTS_PER_SIDE"
echo "Press Ctrl+C to stop"
echo ""

for lap in $(seq 1 $LAPS); do
    echo "--- Lap $lap ---"
    for side in $(seq 0 5); do
        next_side=$(( (side + 1) % 6 ))
        from_lat=$(hex_lat $side)
        from_lng=$(hex_lng $side)
        to_lat=$(hex_lat $next_side)
        to_lng=$(hex_lng $next_side)

        for step in $(seq 0 $((POINTS_PER_SIDE - 1))); do
            t=$(echo "scale=8; $step / $POINTS_PER_SIDE" | bc -l)
            lat=$(lerp "$from_lat" "$to_lat" "$t")
            lng=$(lerp "$from_lng" "$to_lng" "$t")
            send_location "$lat" "$lng"
            sleep $INTERVAL
        done
    done
done

# Final point = start
final_lat=$(hex_lat 0)
final_lng=$(hex_lng 0)
send_location "$final_lat" "$final_lng"

echo ""
echo "=== Done! Open the app to check the route ==="
