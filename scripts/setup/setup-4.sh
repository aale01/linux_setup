#!/bin/bash

# =========================
# LAZYVIM INSTALL
# =========================
echo "[+] Installing LazyVim..."

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

for DIR in "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
	if [ -d "$DIR" ]; then
		mv "$DIR" "${DIR}.bak_${TIMESTAMP}"
	fi
done

sudo -u "$USER" git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"

# =========================
# LAZYVIM CONFIG REPO
# =========================
rm -rf "$HOME/.config/nvim/lua"
sudo -u $USER git clone git@github.com:aale01/LazyVim_config.git "$HOME/.config/nvim/lua"

# =========================
# FONTS (Meslo Nerd Font)
# =========================
echo "[+] Installing Meslo Nerd Font..."

cd /tmp
curl -L -o meslo.zip \
	https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip

mkdir -p "$HOME/.local/share/fonts"
unzip -o meslo.zip -d "$HOME/.local/share/fonts"
rm -f /tmp/meslo.zip
fc-cache -fv

sudo exec ./setup-5.sh
