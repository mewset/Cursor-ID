#!/usr/bin/env bash

set -euo pipefail

# ASCII LOGO
cat <<'EOF'

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@  ____ _   _ ____  ____   ___  ____  @
@ / ___| | | |  _ \/ ___| / _ \|  _ \ @
@| |   | | | | |_) \___ \| | | | |_) |@
@| |___| |_| |  _ < ___) | |_| |  _ < @
@ \____|\___/|_| \_\____/ \___/|_| \_\@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Cursor ID-Changer – Reset Your Trace

EOF

# === CONFIGURATION ===
CONFIG_DIR="$HOME/.config/Cursor"
STORAGE_FILE="$CONFIG_DIR/User/globalStorage/storage.json"
BACKUP_FILE="${STORAGE_FILE}.bak"

EXTRA_DIRS=(
  "$HOME/.local/share/cursor-updater"
  "$HOME/.cache/Cursor"
  "$HOME/.local/share/Cursor"
  "$HOME/.cache/appimage/Cursor"
)

# === DEPENDENCY CHECK ===
require_jq() {
  if ! command -v jq &>/dev/null; then
    echo "[ERROR] 'jq' is required. Install it and try again." >&2
    exit 1
  fi
}

generate_uuid() {
  command -v uuidgen &>/dev/null && uuidgen || cat /proc/sys/kernel/random/uuid
}

backup_storage() {
  [[ -f "$STORAGE_FILE" ]] || {
    echo "[ERROR] storage.json not found at: $STORAGE_FILE" >&2
    return 1
  }
  cp "$STORAGE_FILE" "$BACKUP_FILE"
  echo "[OK] Backup created at: $BACKUP_FILE"
}

rewrite_storage() {
  declare -A ids
  for key in deviceId machineId telemetryId installId userId macMachineId devDeviceId sqmId; do
    ids[$key]=$(generate_uuid | tr '[:upper:]' '[:lower:]')
  done

  local tmpfile
  tmpfile=$(mktemp)

  jq \
    --arg deviceId       "${ids[deviceId]}" \
    --arg machineId      "${ids[machineId]}" \
    --arg telemetryId    "${ids[telemetryId]}" \
    --arg installId      "${ids[installId]}" \
    --arg userId         "${ids[userId]}" \
    --arg macMachineId   "${ids[macMachineId]}" \
    --arg devDeviceId    "${ids[devDeviceId]}" \
    --arg sqmId          "${ids[sqmId]}" \
    '.deviceId = $deviceId
     | .machineId = $machineId
     | .telemetryId = $telemetryId
     | .installId = $installId
     | .userId = $userId
     | .macMachineId = $macMachineId
     | .devDeviceId = $devDeviceId
     | .sqmId = $sqmId' \
    "$STORAGE_FILE" > "$tmpfile" && mv "$tmpfile" "$STORAGE_FILE"

  echo "[OK] storage.json updated with new identifiers:"
  for key in "${!ids[@]}"; do
    printf " - %-14s %s\n" "$key:" "${ids[$key]}"
  done
}

clean_all_traces() {
  for dir in "${EXTRA_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      rm -rf "$dir"
      echo "[OK] Removed: $dir"
    fi
  done
}

restart_cursor() {
  if pgrep -x "cursor" > /dev/null; then
    echo "[INFO] Cursor is running. Restarting..."
    pkill cursor
    sleep 1
    nohup cursor > /dev/null 2>&1 &
    echo "[OK] Cursor restarted."
  fi
}

destroy_cursor_cookies() {
  echo "[INFO] Cleaning Cursor-specific cache and cookies ONLY..."

  # Cursor-specifika mappar (verifierade/kända)
  CURSOR_DIRS=(
    "$HOME/.config/Cursor"
    "$HOME/.cache/Cursor"
    "$HOME/.local/share/Cursor"
  )

  for dir in "${CURSOR_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      echo "[INFO] Removing files in: $dir"
      rm -rf "$dir"
      echo " - Deleted: $dir"
    fi
  done

  # Begränsad sökning i webbläsare – endast efter cookies och local storage där Cursor kan ha dykt upp
  BROWSER_COOKIE_DIRS=(
    "$HOME/.mozilla/firefox"
    "$HOME/.config/google-chrome/Default"
    "$HOME/.config/chromium/Default"
  )

  for bdir in "${BROWSER_COOKIE_DIRS[@]}"; do
    if [[ -d "$bdir" ]]; then
      echo "[INFO] Searching for Cursor browser cookies in: $bdir"
      find "$bdir" -type f \( -iname '*Cookies*' -o -iname '*Local Storage*' \) -print0 | while IFS= read -r -d '' file; do
        # Kontrollera om filen innehåller cursor-relaterade data
        if strings "$file" | grep -iq 'cursor'; then
          echo " - Removing browser file: $file"
          rm -f "$file"
        fi
      done
    fi
  done

  echo "[OK] Done. Only Cursor-related data was touched."
}



# === MENU ===
show_menu() {
  echo ""
  echo "Select an option:"
  echo "  1) Automate (Clear & New Identity)"
  echo "  2) Destroy Cursor-cookies"
  echo "  3) New Identity only"
  echo "  4) Quit"
  echo ""
  read -rp "Enter your choice [1-4]: " choice

  case "$choice" in
    1)
      echo "[+] Running full automation..."
      destroy_cursor_cookies
      backup_storage && rewrite_storage && clean_all_traces && restart_cursor
      ;;
    2)
      destroy_cursor_cookies
      ;;
    3)
      backup_storage && rewrite_storage && clean_all_traces && restart_cursor
      ;;
    4)
      echo "Goodbye!"
      exit 0
      ;;
    *)
      echo "[ERROR] Invalid option. Try again."
      ;;
  esac
}

# === MAIN ===
require_jq

while true; do
  show_menu
done
