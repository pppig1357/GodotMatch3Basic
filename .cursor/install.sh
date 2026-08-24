#!/usr/bin/env bash
# Cloud Agent install script for the GodotMatch3 project.
# Idempotent: installs the pinned Godot engine + runtime libraries and
# imports the project's assets so the game is ready to run.
set -euo pipefail

GODOT_VERSION="4.7.2-stable"
GODOT_BIN="/usr/local/bin/godot"
GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1) Runtime libraries required by the Godot binary (X11 + software OpenGL via
#    Mesa llvmpipe + audio). Harmless to re-run; apt-get is idempotent.
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends \
    ca-certificates curl unzip \
    libgl1 libgl1-mesa-dri \
    libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
    libasound2t64 libpulse0 libudev1 libfontconfig1
fi

# 2) Install the pinned Godot engine only when missing or a different version.
need_install=1
if [ -x "${GODOT_BIN}" ] && "${GODOT_BIN}" --version 2>/dev/null | grep -q "^4.7.2"; then
  need_install=0
fi
if [ "${need_install}" -eq 1 ]; then
  tmpdir="$(mktemp -d)"
  curl -fL -o "${tmpdir}/godot.zip" "${GODOT_URL}"
  unzip -o "${tmpdir}/godot.zip" -d "${tmpdir}"
  sudo mv "${tmpdir}/Godot_v${GODOT_VERSION}_linux.x86_64" "${GODOT_BIN}"
  sudo chmod +x "${GODOT_BIN}"
  rm -rf "${tmpdir}"
fi
"${GODOT_BIN}" --version

# 3) Import the project's resources (generates the local .godot cache).
#    Runs headless so no display is required during setup.
cd "${PROJECT_DIR}"
godot --headless --import
