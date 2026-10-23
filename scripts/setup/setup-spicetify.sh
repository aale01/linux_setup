#!/usr/bin/env bash

set -Eeuo pipefail

# =========================
# SPICETIFY CONFIGURATION
# =========================
CONFIG_DIR="$HOME/.config/spicetify"

# Corregge eventuali permessi lasciati da precedenti esecuzioni come root.
if [[ -d "$CONFIG_DIR" ]]; then
    sudo chown -R "$(id -u):$(id -g)" "$CONFIG_DIR"
fi

# =========================
# INSTALL SPICETIFY
# =========================
INSTALL_SCRIPT="$(mktemp)"
trap 'rm -f "$INSTALL_SCRIPT"' EXIT

echo "[+] Downloading Spicetify installer..."

curl -fsSL \
    https://raw.githubusercontent.com/spicetify/cli/main/install.sh \
    -o "$INSTALL_SCRIPT"

# Conferma automaticamente la domanda prevista dall'installer.
sed -i \
    's/read -r choice < \/dev\/tty/choice="y"/' \
    "$INSTALL_SCRIPT"

echo "[+] Installing Spicetify..."

bash "$INSTALL_SCRIPT"

# =========================
# APPLY CONFIGURATION
# =========================
echo "[+] Applying Spicetify configuration..."

spicetify backup apply

sleep 1

echo "[+] Spicetify setup completed."