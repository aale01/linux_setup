#!/bin/bash

# === VALIDAZIONI INIZIALI ===
echo "=== VALIDAZIONI INIZIALI ==="

STATE=1

SWAP_DEV=$(swapon --show=NAME --noheadings | tail -n 1)

if [ -z "$SWAP_DEV" ]; then
	echo "AVVISO: nessuna swap attiva. Salto tutto."
	STATE=0
else
	SWAP_UUID=$(sudo blkid -s UUID -o value "$SWAP_DEV")
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
	sudo tee /etc/polkit-1/rules.d/90-enable-hibernate.rules >/dev/null <<'EOF'
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
	sudo tee /etc/systemd/sleep.conf.d/disable-hybrid.conf >/dev/null <<'EOF'
[Sleep]
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF

	# 8. Extension manager
	sudo apt install -y gnome-shell-extension-manager

	extension-manager

	# 7. GNOME power settings
	# Determina l'utente "reale" indipendentemente da come è stato lanciato lo script

	if [ -n "$SUDO_USER" ]; then
		REAL_USER="$SUDO_USER"
	else
		REAL_USER="$(logname 2>/dev/null || whoami)"
	fi
	REAL_UID=$(id -u "$REAL_USER")

	echo "Utente reale rilevato: $REAL_USER (UID $REAL_UID)"
	sudo -u "$REAL_USER" env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
		gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
	sudo -u "$REAL_USER" env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
		gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'

	# fa il logout e fa rifare il login
	# sudo systemctl restart systemd-logind

	echo "== HIBERNATION SETUP DONE =="
else
	echo "== QUIT =="

fi
