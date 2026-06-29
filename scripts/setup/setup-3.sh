#!/bin/bash

# =========================
# NEOVIM INSTALL
# =========================
echo "[+] Installing neovim..."

NVIM_ARCHIVE="/tmp/nvim-linux-x86_64.tar.gz"
curl -L -o "$NVIM_ARCHIVE" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf "$NVIM_ARCHIVE"
rm -f "$NVIM_ARCHIVE"

# Aggiungi nvim al PATH se non già presente
NVIM_BIN="/opt/nvim-linux-x86_64/bin"
if ! grep -q "$NVIM_BIN" "$HOME/.bashrc.d/.bashrc" 2>/dev/null && ! grep -q "$NVIM_BIN" "$HOME/.bashrc"; then
	echo -e "\e[1;31m  --------    Aggiungere  /opt/nvim-linux-x86_64/bin  al path    --------\e[0m"
	# echo "export PATH=\"$NVIM_BIN:\$PATH\"" >> "$HOME/.bashrc"
fi

# LazyVim package
sudo bash ./setup-lazyvim-package.sh

exec ./setup-4.sh
