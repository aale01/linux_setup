#!/bin/bash

# Serve a far terminare immediatamente lo script se qualunque comando fallisce
# set -e

echo "=== Ubuntu Provisioning Script ==="

USER="alebe"
HOME="/home/$USER"

# Richiedi sudo subito
sudo -v

# =========================
# KEYBOARD LAYOUT
# =========================
read -p "Choose keyboard layout (it/us) [us]: " LAYOUT

# fallback nel caso l'utente non scriva nulla
LAYOUT="${LAYOUT:-us}"

if [ "$LAYOUT" = "it" ]; then
	SOURCES="[('xkb', 'it')]"
else
	SOURCES="[('xkb', 'us')]"
fi

echo "[+] Applying keyboard layout: $SOURCES"
sudo -u alebe env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u alebe)/bus" \
	gsettings set org.gnome.desktop.input-sources sources "$SOURCES"

# =========================
# LINUX BACKUP REPO
# =========================
echo "[+] Restoring from linux_backup..."

if [ -d "$HOME/linux_backup" ]; then
	rsync -a -v --backup --backup-dir="$HOME/.pre-setup-backup" --exclude=".git/" "$HOME/linux_backup/" "$HOME/"
	rm -rf ~/.git
	sudo cp "$HOME/linux_backup/grub" /etc/default/grub
	sudo update-grub
	# rsync -a --backup --backup-dir="$HOME/.pre-setup-backup/.config" "$HOME/linux_backup/.config/" "$HOME/.config/"    -----   RIDONDANTE !
else
	echo "AVVISO: $HOME/linux_backup non trovato, skip."
fi

# =========================
# Git global config
# =========================
sudo -u "$USER" git config --global init.defaultBranch master
sudo -u "$USER" git config --global user.name "Alessandro"
sudo -u "$USER" git config --global user.email "alebecu01@gmail.com"

# =========================
# Directories
# =========================
mkdir -p "$HOME/scripts"
mkdir -p "$HOME/Desktop/42"
mkdir -p "$HOME/Desktop/42/examshell/"
mkdir -p "$HOME/Desktop/42/projects/"
mkdir -p "$HOME/.config"

# =========================
# BASH CONFIG REPO
# =========================
sudo -u $USER git clone git@github.com:aale01/BASH_config.git "$HOME/.bashrc.d"

echo 'source ~/.bashrc.d/.bashrc' >"$HOME/.bashrc"
source ~/.bashrc
# Nota: source qui non ha effetto utile nello script, verrà applicato al prossimo login

# =========================
# SYSTEM UPDATE
# =========================
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

sudo apt install -y xclip

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

# =========================
# Spotify
# =========================
echo "[+] Installing Spotify..."

bash ./setup-spotify.sh

# =========================
# Spicetify
# =========================
# NOTA: questo script modifica e lancia un installer esterno.
# Verifica il contenuto prima di eseguire in ambienti critici.
echo "[+] Installing Spicetify..."

bash setup-spicetify.sh

# =========================
# Spicetify - History in Sidebar
# =========================

echo "[+] Installazione Spicetify history-in-sidebar..."

bash setup-history-in-sidebar.sh

# =========================
# HIBERNATION
# =========================
echo "[+] Setting up hibernation..."

bash ./setup-hibernation.sh

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
echo "[+] Backup pre-setup saved in: $HOME/.pre-setup-backup"
echo ""
echo "*** REBOOT REQUIRED ***"
echo ""
