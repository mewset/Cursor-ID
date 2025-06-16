#!/bin/bash

# Cursor ID-changer - by mewset
# https://github.com/mewset/Cursor-ID/

# ASCII Logo
echo "
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@  ____ _   _ ____  ____   ___  ____  @
@ / ___| | | |  _ \/ ___| / _ \|  _ \ @
@| |   | | | | |_) \___ \| | | | |_) |@
@| |___| |_| |  _ < ___) | |_| |  _ < @
@ \____|\___/|_| \_\____/ \___/|_| \_\@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
"

generate_ids() {
  echo "[INFO] Generating new machine identifiers..."
  sudo rm -f /etc/machine-id
  sudo systemd-machine-id-setup
  local new_id
  new_id=$(cat /etc/machine-id)
  echo "[OK] New machine-id: $new_id"
}

change_cursor_identity() {
  echo "[INFO] Modifying Cursor identity..."

  CURSOR_DIR="$HOME/.config/Cursor"
  IDB_FILE="$CURSOR_DIR/IndexedDB.json"

  if [[ -f "$IDB_FILE" ]]; then
    echo "[INFO] Updating IDs in: $IDB_FILE"

    new_user_id=$(uuidgen)
    new_install_id=$(uuidgen)

    sed -i "s/\"userId\": *\"[^\"]*\"/\"userId\": \"$new_user_id\"/" "$IDB_FILE"
    sed -i "s/\"installId\": *\"[^\"]*\"/\"installId\": \"$new_install_id\"/" "$IDB_FILE"

    echo "[OK] New userId: $new_user_id"
    echo "[OK] New installId: $new_install_id"
  else
    echo "[WARN] $IDB_FILE not found. Skipping JSON update."
  fi
}

destroy_cursor_cookies() {
  echo "[INFO] Cleaning Cursor-specific cache and cookies ONLY..."

  CURSOR_DIRS=(
    "$HOME/.config/Cursor"
    "$HOME/.cache/Cursor"
    "$HOME/.local/share/Cursor"
  )

  for dir in "${CURSOR_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      echo " - Removing: $dir"
      rm -rf "$dir"
    fi
  done

  BROWSER_COOKIE_DIRS=(
    "$HOME/.mozilla/firefox"
    "$HOME/.config/google-chrome/Default"
    "$HOME/.config/chromium/Default"
  )

  for bdir in "${BROWSER_COOKIE_DIRS[@]}"; do
    if [[ -d "$bdir" ]]; then
      echo "[INFO] Searching for Cursor browser cookies in: $bdir"
      find "$bdir" -type f \( -iname '*Cookies*' -o -iname '*Local Storage*' \) -print0 | while IFS= read -r -d '' file; do
        if strings "$file" | grep -iq 'cursor'; then
          echo " - Removing browser file: $file"
          rm -f "$file"
        fi
      done
    fi
  done

  # ➕ Rensa eventuell systeminstallation
  if [[ -d "/opt/Cursor" ]]; then
    echo "[INFO] Removing system installation: /opt/Cursor"
    sudo rm -rf /opt/Cursor
  fi

  echo "[OK] Cookie cleanup done."
}

menu() {
  while true; do
    echo ""
    echo "==== Cursor ID-Changer Menu ===="
    echo "1. Automate (Reset ID + Clean Cookies + delete cursor appimage)"
    echo "2. Destroy Cursor Cookies + delete cursor appimage"
    echo "3. New Identity (Only change ID)"
    echo "4. Quit"
    echo "================================"
    read -rp "Choose an option: " choice

    case $choice in
      1)
        destroy_cursor_cookies
        generate_ids
        change_cursor_identity
        ;;
      2)
        destroy_cursor_cookies
        ;;
      3)
        generate_ids
        change_cursor_identity
        ;;
      4)
        echo "Exiting."
        break
        ;;
      *)
        echo "[WARN] Invalid option. Try again."
        ;;
    esac
  done
}

# Start script
menu
