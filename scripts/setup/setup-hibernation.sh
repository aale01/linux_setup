#!/bin/bash

# Lo script va eseguito come utente normale.
if [[ "$EUID" -eq 0 ]]; then
    echo "Errore: esegui questo script senza sudo." >&2
    exit 1
fi

# Richiede i privilegi amministrativi all'inizio.
sudo -v

#REAL_USER="$(id -un)"
REAL_UID="$(id -u)"
RUNTIME_DIR="/run/user/$REAL_UID"

# === VALIDAZIONI INIZIALI ===
echo "=== VALIDAZIONI INIZIALI ==="

STATE=1

SWAP_DEV=$(swapon --show=NAME --noheadings | tail -n 1)
POWER_STATE=$(cat /sys/power/state)

if [ -z "$SWAP_DEV" ]; then
	echo "AVVISO: nessuna swap attiva. Salto tutto."
	STATE=0
else
	SWAP_UUID=$(sudo blkid -s UUID -o value "$SWAP_DEV")
	if [ -z "$SWAP_UUID" ]; then
		echo "AVVISO: UUID della swap non trovato per $SWAP_DEV. Salto tutto."
		STATE=0
	else
    if ! grep -qw "disk" <<< "$POWER_STATE"; then
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

  GRUB_FILE="/etc/default/grub"

  if ! sudo grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE"; then
      echo "ERRORE: GRUB_CMDLINE_LINUX_DEFAULT non trovato." >&2
      exit 1
  fi

  # Modifica GRUB solo se il parametro corretto non è già presente.
  if ! sudo grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE" |
      grep -Fq "resume=UUID=$SWAP_UUID"; then

      GRUB_BACKUP="${GRUB_FILE}.pre-hibernation-$(date +%Y%m%d_%H%M%S)"
      if ! sudo cp -a "$GRUB_FILE" "$GRUB_BACKUP"; then
          echo "ERRORE: backup di GRUB non riuscito." >&2
          exit 1
      fi

      echo "Backup GRUB salvato in: $GRUB_BACKUP"

      if ! sudo sed -i -E \
          -e '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/[[:space:]]resume=[^[:space:]"]+//g' \
          -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"[[:space:]]*$/ resume=UUID=$SWAP_UUID\"/" \
          "$GRUB_FILE"; then
          echo "ERRORE: modifica di GRUB non riuscita." >&2
          exit 1
      fi
  else
      echo "Il parametro resume è già corretto: nessuna modifica a GRUB."
  fi

	echo "Fatto. Verifica:"
	grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub


	# 3. update grub and initramfs
  if ! sudo update-grub; then
      echo "ERRORE: aggiornamento di GRUB fallito." >&2
      exit 1
  fi

  if ! sudo update-initramfs -u; then
      echo "ERRORE: aggiornamento di initramfs fallito." >&2
      exit 1
  fi


	# 4. enable hibernate in systemd PolicyKit
	echo "Enabling PoliicyKit for systemctl hibernate..."

  sudo install -d -o root -g root -m 755 /etc/polkit-1/rules.d

  sudo tee /etc/polkit-1/rules.d/90-enable-hibernate.rules >/dev/null <<'EOF'
polkit.addRule(function(action, subject) {
    if (
        (
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions"
        ) &&
        subject.local &&
        subject.active
    ) {
        return polkit.Result.YES;
    }
});
EOF
#	sudo systemctl restart polkit    # --> non necessario


	# 5. disabilita hybrid sleep / suspend-then-hibernate
	echo "Disabling hybrid sleep..."
	sudo systemctl mask suspend-then-hibernate.target
	sudo systemctl mask systemd-suspend-then-hibernate.service


	# 6. sleep.conf hard disable hybrid
	sudo mkdir -p /etc/systemd/sleep.conf.d
	sudo tee /etc/systemd/sleep.conf.d/disable-hybrid.conf >/dev/null <<'EOF'
[Sleep]
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF


  # 7. Extension manager
  if ! sudo apt install -y gnome-shell-extension-manager; then
      echo "ERRORE: installazione di Extension Manager fallita." >&2
      exit 1
  fi

  if ! command -v extension-manager >/dev/null 2>&1; then
      echo "ERRORE: comando extension-manager non trovato." >&2
      exit 1
  fi

  extension-manager


	# 8. GNOME power settings
  echo "[+] Configuring GNOME power settings..."

  if [[ -S "$RUNTIME_DIR/bus" ]]; then
      if ! env \
          XDG_RUNTIME_DIR="$RUNTIME_DIR" \
          DBUS_SESSION_BUS_ADDRESS="unix:path=$RUNTIME_DIR/bus" \
          gsettings set \
          org.gnome.settings-daemon.plugins.power \
          sleep-inactive-ac-type 'suspend'; then
          echo "AVVISO: impossibile impostare la sospensione su alimentazione AC."
      fi

      if ! env \
          XDG_RUNTIME_DIR="$RUNTIME_DIR" \
          DBUS_SESSION_BUS_ADDRESS="unix:path=$RUNTIME_DIR/bus" \
          gsettings set \
          org.gnome.settings-daemon.plugins.power \
          sleep-inactive-battery-type 'suspend'; then
          echo "AVVISO: impossibile impostare la sospensione a batteria."
      fi
  else
      echo "AVVISO: sessione D-Bus utente non disponibile."
      echo "Le impostazioni GNOME non sono state modificate."
  fi

	# fa il logout e fa rifare il login
	# sudo systemctl restart systemd-logind

	echo "== HIBERNATION SETUP DONE =="
else
	echo "== QUIT =="

fi
