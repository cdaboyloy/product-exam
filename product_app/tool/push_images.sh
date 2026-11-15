#!/bin/bash
# Copy images from your laptop into the Android Emulator's gallery.
#
# Usage:
#   ./tool/push_images.sh ~/Desktop/product-photos      (a folder)
#   ./tool/push_images.sh ~/Downloads/cola.jpg          (one or more files)
#
# Then in the app: tap the image → "Choose from gallery" → pick → Done.

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $0 <folder or image files...>"
  exit 1
fi

if ! adb get-state >/dev/null 2>&1; then
  echo "No emulator found. Start the Android Emulator first."
  exit 1
fi

DEST=/sdcard/Pictures/Products
adb shell mkdir -p "$DEST"

count=0
push_one() {
  local f="$1"
  case "$(echo "$f" | tr '[:upper:]' '[:lower:]')" in
    *.jpg|*.jpeg|*.png|*.webp|*.gif)
      adb push "$f" "$DEST/" >/dev/null 2>&1
      echo "  ✓ $(basename "$f")"
      count=$((count + 1))
      ;;
  esac
}

for arg in "$@"; do
  if [ -d "$arg" ]; then
    while IFS= read -r -d '' f; do push_one "$f"; done < <(find "$arg" -maxdepth 1 -type f -print0)
  elif [ -f "$arg" ]; then
    push_one "$arg"
  else
    echo "  ✗ not found: $arg"
  fi
done

# Ask Android to index the new files so they appear in the photo picker
adb shell content call --uri content://media --method scan_volume --arg external_primary >/dev/null 2>&1 || true

echo "Done: $count image(s) copied to the emulator gallery."
