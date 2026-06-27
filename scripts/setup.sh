#!/bin/bash

set -e

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
    rsync -a --backup --backup-dir="$HOME/.pre-setup-backup" "$HOME/linux_backup/" "$HOME/"
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
mkdir -p "$HOME/.config"


# =========================
# BASH CONFIG REPO
# =========================
sudo -u $USER git clone git@github.com:aale01/BASH_config.git "$HOME/.bashrc.d"

echo 'source ~/.bashrc.d/.bashrc' > "$HOME/.bashrc"
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
 
curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc \
    | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" \
    | sudo tee /etc/apt/sources.list.d/spotify.list
 
sudo apt-get update && sudo apt-get install -y spotify-client

echo "[+] Avvia Spotify e fai login..."

until pgrep spotify >/dev/null; do
    echo "Spotify non avviato ancora..."
    sleep 3
done

echo "Spotify rilevato. Premi INVIO quando hai completato il login."
read -r


# =========================
# Spicetify
# =========================
# NOTA: questo script modifica e lancia un installer esterno.
# Verifica il contenuto prima di eseguire in ambienti critici.
echo "[+] Installing Spicetify..."
 
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh -o /tmp/spicetify_install.sh
sed -i 's/read -r choice < \/dev\/tty/choice="y"/' /tmp/spicetify_install.sh
sh /tmp/spicetify_install.sh
rm -f /tmp/spicetify_install.sh


# =========================
# HIBERNATION
# =========================
echo "[+] Setting up hibernation..."

# === VALIDAZIONI INIZIALI ===
STATE=1

SWAP_DEV=$(swapon --show=NAME --noheadings | tail -n 1)
 
echo "=== VALIDAZIONI INIZIALI ==="

if [ -z "$SWAP_DEV" ]; then
	echo "AVVISO: nessuna swap attiva. Salto tutto."
	STATE=0
else
	SWAP_UUID=$(blkid -s UUID -o value "$SWAP_DEV")
	if [ -z "$SWAP_UUID" ]; then
	    	echo "AVVISO: UUID della swap non trovato per $SWAP_DEV. Salto tutto."
		STATE=0
	else
		OUTPUT=$(cat /sys/power/state)
	        if ! grep -q "disk" /sys/power/state 2>/dev/null; then
        		echo "AVVISO: /sys/power/state non contiene 'disk', hibernate potrebbe non funzionare."
			STATE=0
        	fi
	fi
fi

	# === TUTTO OK, PROCEDO ===
if [ "$STATE" -eq 1 ]; then

	echo "== HIBERNATION SETUP START =="
	 
        echo "Swap device: $SWAP_DEV"
        echo "Swap UUID:   $SWAP_UUID"
 
        # 1. Configura resume initramfs
        sudo mkdir -p /etc/initramfs-tools/conf.d
        echo "RESUME=UUID=$SWAP_UUID" | sudo tee /etc/initramfs-tools/conf.d/resume

	# 2. configura GRUB
	echo "Configuring GRUB..."
	 
	echo "Swap UUID: $SWAP_UUID"
	 
        if ! grep -q "resume=UUID=$SWAP_UUID" /etc/default/grub; then
		sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ {
		    s/[[:space:]]*resume=UUID=[^ \"]*/\n/g
		    s/\n[[:space:]]*/\n/g
		    s/\n/ /g
		    s/[[:space:]]*\"[[:space:]]*$/ resume=UUID=$SWAP_UUID\"/
		}" /etc/default/grub
	fi
	 
	echo "Fatto. Verifica:"
	grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub

	# 3. update grub and initramfs
	sudo update-grub
	sudo update-initramfs -u

	# 4. enable hibernate in systemd PolicyKit
	echo "Enabling PoliicyKit for systemctl hibernate..."

	mkdir -p /etc/polkit-1/rules.d
        sudo tee /etc/polkit-1/rules.d/90-enable-hibernate.rules > /dev/null << 'EOF'
polkit.addRule(function(action, subject) {
    if (
        action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions"
    ) {
        return polkit.Result.YES;
    }
});
EOF
	sudo systemctl restart polkit

	# 5. disabilita hybrid sleep / suspend-then-hibernate
	echo "Disabling hybrid sleep..."
	sudo systemctl mask suspend-then-hibernate.target
	sudo systemctl mask systemd-suspend-then-hibernate.service

	# 8. sleep.conf hard disable hybrid
	sudo mkdir -p /etc/systemd/sleep.conf.d
        sudo tee /etc/systemd/sleep.conf.d/disable-hybrid.conf > /dev/null << 'EOF'
[Sleep]
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF

        # 8. Extension manager
        sudo apt install -y gnome-shell-extension-manager

	extension-manager


        # 7. GNOME power settings
        sudo -u "$USER" env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USER")/bus" \
            gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
        sudo -u "$USER" env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USER")/bus" \
            gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'

	sudo systemctl restart systemd-logind

	echo "== HIBERNATION SETUP DONE =="
fi

echo "== DONE =="


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

