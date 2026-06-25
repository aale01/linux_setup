#!/bin/bash

set -e

echo "=== Ubuntu Provisioning Script ==="

USER="alebe"
HOME="/home/$USER"

if [ "$LAYOUT" = "it" ]; then
    SOURCES="[('xkb', 'it')]"
else
    SOURCES="[('xkb', 'us')]"
fi

echo "[+] Applying keyboard layout: $SOURCES"
sudo -u alebe gsettings set org.gnome.desktop.input-sources sources "$SOURCES"

# =========================
# LINUX BACKUP REPO
# =========================
echo "[+] System setup starting..."

# copy home files
rsync -a "$HOME/linux_backup/" "$HOME/"

# GRUB replacement (system file)
cp "$HOME/linux_backup/GRUB" /etc/default/grub
update-grub

# .config merge
rsync -a "$HOME/linux_backup/.config/" "$HOME/.config/"


# =========================
# Git global config
# =========================
git config --system init.defaultBranch master
git config --system user.name "Alessandro"
git config --system user.email "alebecu01@gmail.com"

# =========================
# Directories
# =========================
mkdir -p "$HOME/scripts"
mkdir -p "$HOME/Desktop/42"
mkdir -p "$HOME/.config"

chown -R $USER:$USER "$HOME"

# =========================
# BASH CONFIG REPO
# =========================
sudo -u $USER git clone git@github.com:aale01/BASH_config.git "$HOME/.bashrc.d"

echo 'source ~/.bashrc.d/.bashrc' > "$HOME/.bashrc"
source ~/.bashrc


sudo apt update && sudo apt upgrade -y


# =========================
# BASE SYSTEM
# =========================
echo "[+] Installing base tools..."

sudo apt install -y \
build-essential \
curl wget git \
vim nano \
htop tmux \
unzip zip tar \
tree jq file \
lsof


# =========================
# NEOVIM INSTALL
# =========================
echo "[+] Installing neovim..."

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz


# =========================
# LAZYVIM INSTALL
# =========================
echo "[+] Installing LazyVim..."

# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

git clone https://github.com/LazyVim/starter ~/.config/nvim


# =========================
# LAZYVIM CONFIG REPO
# =========================
rm -rf "$HOME/.config/nvim/lua"
sudo -u $USER git clone git@github.com:aale01/LazyVim_config.git "$HOME/.config/nvim/lua"


# =========================
# FONTS (Meslo Nerd Font)
# =========================
cd /tmp
curl -L -o meslo.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip

mkdir -p "$HOME/.local/share/fonts"
unzip -o meslo.zip -d "$HOME/.local/share/fonts"
fc-cache -fv


# =========================
# CLEANUP
# =========================
echo "[+] Cleaning up..."

sudo apt autoremove -y
sudo apt autoclean

# =========================
# FIX PERMISSIONS
# =========================
chown -R $USER:$USER "$HOME"


echo "=== DONE ==="
echo "[+] Setup completed successfully."
echo ""
echo "Reboot recommended."
echo ""
