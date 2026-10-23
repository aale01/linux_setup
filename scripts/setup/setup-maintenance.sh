#!/usr/bin/env bash

set -Eeuo pipefail

# Eseguire come utente normale, non come root.
if [[ "$EUID" -eq 0 ]]; then
	echo "Errore: esegui questo script senza sudo."
	exit 1
fi

USER_HOME="$HOME"

# Directory .../linux_setup/scripts/setup
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Directory .../linux_setup/scripts
SCRIPTS_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

SRC_BIN="$SCRIPTS_DIR/bin"
SRC_SYSTEM="$SCRIPTS_DIR/system"
SRC_AUTOSTART="$SCRIPTS_DIR/config/autostart"
SRC_SYSTEMD_USER="$SCRIPTS_DIR/config/systemd/user"

# Controlla le sorgenti prima di modificare il sistema.
FILES=(
	"$SRC_BIN/apt-daily-update.sh"
	"$SRC_BIN/clean-cache.sh"
	"$SRC_SYSTEM/apt-update-upgrade"
	"$SRC_SYSTEM/apt-update-resume-hook"
	"$SRC_AUTOSTART/apt-daily-update.desktop"
	"$SRC_SYSTEMD_USER/apt-daily-update-resume.service"
)

for file in "${FILES[@]}"; do
	if [[ ! -f "$file" ]]; then
		echo "Errore: file sorgente mancante: $file"
		exit 1
	fi
done

# Richiede sudo solo per le operazioni amministrative.
sudo -v

echo "[+] Installazione degli script utente..."

install -d -m 755 \
	"$USER_HOME/.local/bin" \
	"$USER_HOME/.config/autostart" \
	"$USER_HOME/.config/systemd/user"

install -m 755 \
	"$SRC_BIN/apt-daily-update.sh" \
	"$USER_HOME/.local/bin/apt-daily-update.sh"

install -m 755 \
	"$SRC_BIN/clean-cache.sh" \
	"$USER_HOME/.local/bin/clean-cache.sh"

install -m 644 \
	"$SRC_AUTOSTART/apt-daily-update.desktop" \
	"$USER_HOME/.config/autostart/apt-daily-update.desktop"

install -m 644 \
	"$SRC_SYSTEMD_USER/apt-daily-update-resume.service" \
	"$USER_HOME/.config/systemd/user/apt-daily-update-resume.service"

echo "[+] Installazione degli script amministrativi..."

sudo install -o root -g root -m 755 \
	"$SRC_SYSTEM/apt-update-upgrade" \
	/usr/local/sbin/apt-update-upgrade

sudo install -o root -g root -m 755 \
	"$SRC_SYSTEM/apt-update-resume-hook" \
	/usr/local/sbin/apt-update-resume-hook

# Collega l'hook nella posizione già utilizzata dal sistema.
SYSTEM_SLEEP_DIR="/usr/lib/systemd/system-sleep"
RESUME_HOOK="/usr/local/sbin/apt-update-resume-hook"
RESUME_HOOK_LINK="$SYSTEM_SLEEP_DIR/apt-update-resume-hook"

sudo install -d -o root -g root -m 755 "$SYSTEM_SLEEP_DIR"

if [[ -L "$RESUME_HOOK_LINK" ]]; then
	CURRENT_LINK="$(sudo readlink "$RESUME_HOOK_LINK")"

	if [[ "$CURRENT_LINK" != "$RESUME_HOOK" ]]; then
		sudo ln -sfn "$RESUME_HOOK" "$RESUME_HOOK_LINK"
	fi
elif [[ -e "$RESUME_HOOK_LINK" ]]; then
	echo "ERRORE: esiste già un file non simbolico in $RESUME_HOOK_LINK." >&2
	echo "Non verrà sovrascritto automaticamente." >&2
	exit 1
else
	sudo ln -s "$RESUME_HOOK" "$RESUME_HOOK_LINK"
fi

echo "[+] Ricaricamento del gestore systemd utente..."

systemctl --user daemon-reload

echo
echo "Configurazione della manutenzione installata correttamente."
