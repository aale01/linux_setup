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

exec ./setup-2.sh
