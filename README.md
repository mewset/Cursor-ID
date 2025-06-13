
**Cursor ID-Changer** is a lightweight script that resets all machine-specific identifiers used by [Cursor](https://cursor.sh), making your system look like a completely new device.

## ✨ Features

- Generates fresh UUIDs for:
  - `deviceId`
  - `machineId`
  - `telemetryId`
  - `installId`
  - `userId`
  - `macMachineId`
  - `devDeviceId`
  - `sqmId`
- Deletes local update/tracking folders
- Backs up original config before making changes
- Restarts Cursor if running

## 📦 Requirements

- Linux (tested on Arch & Debian-based systems)
- `bash`, `jq`
- Cursor installed and launched at least once

## 🚀 Usage

```bash
chmod +x app.sh
./app.sh
```

## 🛡️ What it does

- reates a backup of your ~/.config/Cursor/User/globalStorage/storage.json

- Replaces relevant telemetry and machine identifiers with new ones

- Removes updater cache: ~/.local/share/cursor-updater

 - Optionally restarts Cursor

⚠️ Disclaimer

This script is for educational and research purposes only.
You are solely responsible for how you use it.

Made with ❤️ by tinkerers, for tinkerers.
