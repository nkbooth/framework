#!/bin/bash
# Re-expose a re-enumerated ttyACM device inside the meshtastic firmware devcontainer.
#
# The problem: pio's adafruit-nrfutil does a 1200 bps touch to enter DFU bootloader,
# which causes the device to disconnect and re-enumerate. The container's /dev/ttyACM0
# is a bind mount that references the OLD inode; after reconnect the bind is stale and
# the upload hangs waiting for the device.
#
# The fix: on every ttyACM "add" event, enter the container's mount namespace as host
# root (which CAN chmod device nodes that container root cannot), tear down the stale
# bind mount, and chmod the underlying --device node to 0666.
#
# Called by udev as root with the kernel device name, e.g.:
#   meshtastic-hrv-sync-dev.sh ttyACM0
#
# Requires: devcontainer.json postStartCommand writes the container's mount namespace
# ID to .pio/container-mnt-ns so this script can locate the container without podman.

set -euo pipefail

DEVNAME="${1:?usage: $0 <devname>}"
DEVICE="/dev/$DEVNAME"
MNT_NS_FILE="/var/home/nick/Documents/code/defcon/meshtastic/firmware/.pio/container-mnt-ns"

MNT_NS=$(cat "$MNT_NS_FILE" 2>/dev/null | tr -d '[:space:]')
[ -z "$MNT_NS" ] && exit 0

# Find any PID inside the container's mount namespace.
CONTAINER_PID=""
for ns_link in /proc/[0-9]*/ns/mnt; do
    [[ "$(readlink "$ns_link" 2>/dev/null)" == "$MNT_NS" ]] || continue
    CONTAINER_PID="${ns_link%/ns/mnt}"
    CONTAINER_PID="${CONTAINER_PID##*/}"
    break
done
[ -z "$CONTAINER_PID" ] && exit 0

# Enter the container's mount namespace (not PID/user namespace) as real root.
# 1. Unmount any stale bind that was overlaying the device node.
# 2. Chmod the underlying --device node (created by Podman at container start).
nsenter --mount="/proc/$CONTAINER_PID/ns/mnt" -- sh -c "
    umount '$DEVICE' 2>/dev/null || true
    chmod 0666 '$DEVICE' 2>/dev/null || true
"
