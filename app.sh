#!/usr/bin/env bash

set -e

# ============================================
# ASCII LOGO
echo "
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@  ____ _   _ ____  ____   ___  ____  @
@ / ___| | | |  _ \/ ___| / _ \|  _ \ @
@| |   | | | | |_) \___ \| | | | |_) |@
@| |___| |_| |  _ < ___) | |_| |  _ < @
@ \____|\___/|_| \_\____/ \___/|_| \_\@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
"

echo "Cursor ID-Changer – Reset Your Trace"
echo

# === Config ===
CONFIG_DIR="$HOME/.config/Cursor"
STORAGE_FILE="$CONFIG_DIR/User/globalStorage/storage.json"
BACKUP_FILE="${STORAGE_FILE}.bak"
UPDATER_DIR="$HOME/.local/share/cursor-updater"

# === UUID Generator ===
uuid() {
  if command -v uuidgen &>/dev/null; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    cat /proc/sys/kernel/random/uuid
  fi
}

# === Backup ===
backup() {
  if [ -f "$STORAGE_FILE" ]; then
    cp "$STORAGE_FILE" "$BACKUP_FILE"
    echo "[OK] Backup created: $BACKUP_FILE"
  else
    echo "[ERROR] Could not find: $STORAGE_FILE"
    exit 1
  fi
}

# === Remove updater folder ===
remove_updater() {
  if [ -d "$UPDATER_DIR" ]; then
    rm -rf "$UPDATER_DIR"
    echo "[OK] Removed updater directory: $UPDATER_DIR"
  fi
}

# === Generate new IDs and write to storage.json ===
reset_ids() {
  tmpfile=$(mktemp)

  # Generate fresh UUIDs
  device_id=$(uuid)
  machine_id=$(uuid)
  telemetry_id=$(uuid)
  install_id=$(uuid)
  user_id=$(uuid)
  mac_machine_id=$(uuid)
  dev_device_id=$(uuid)
  sqm_id=$(uuid)

  jq \
    --arg deviceId "$device_id" \
    --arg machineId "$machine_id" \
    --arg telemetryId "$telemetry_id" \
    --arg installId "$install_id" \
    --arg userId "$user_id" \
    --arg macMachineId "$mac_machine_id" \
    --arg devDeviceId "$dev_device_id" \
    --arg sqmId "$sqm_id" \
    '.deviceId = $deviceId
     | .machineId = $machineId
     | .telemetryId = $telemetryId
     | .installId = $installId
     | .userId = $userId
     | .macMachineId = $macMachineId
     | .devDeviceId = $devDeviceId
     | .sqmId = $sqmId' \
    "$STORAGE_FILE" > "$tmpfile" && mv "$tmpfile" "$STORAGE_FILE"

  echo
  echo "[OK] All identifiers have been reset:"
  echo " - deviceId:      $device_id"
  echo " - machineId:     $machine_id"
  echo " - telemetryId:   $telemetry_id"
  echo " - installId:     $install_id"
  echo " - userId:        $user_id"
  echo " - macMachineId:  $mac_machine_id"
  echo " - devDeviceId:   $dev_device_id"
  echo " - sqmId:         $sqm_id"
  echo
}

# === Entry point ===
if ! command -v jq &>/dev/null; then
  echo "[ERROR] 'jq' is required but not installed. Install it with: sudo pacman -S jq"
  exit 1
fi

backup
remove_updater
reset_ids

# Optional: restart Cursor if running
if pgrep -x "cursor" > /dev/null; then
  echo "[INFO] Cursor is running. Restarting..."
  pkill cursor
  sleep 1
  nohup cursor > /dev/null 2>&1 &
  echo "[OK] Cursor restarted."
fi

echo "[DONE] Your system now appears brand new to Cursor."
