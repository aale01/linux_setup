#!/bin/bash

# =========================
# SCRIPT PATHS
# =========================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || exit 1
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)" || exit 1

cd "$SCRIPT_DIR" || exit 1

# Dati git (modificali qui se cambiano)
GIT_NAME="Alessandro Becucci"
GIT_EMAIL="alebecu01@gmail.com"

# Repo privato: il restore viene fatto solo se si hanno i permessi
BACKUP_REPO="git@github.com:aale01/linux_backup.git"

# Serve a far terminare immediatamente lo script se qualunque comando fallisce
# set -e

echo "=== Ubuntu Provisioning Script ==="

# =========================
# UTENTE: solo utente normale, senza sudo
# =========================
if ((EUID == 0)); then
	echo "ERRORE: esegui lo script come utente normale, senza sudo." >&2
	exit 1
fi

TARGET_USER="$(id -un)"

if [[ -z "$HOME" || ! -d "$HOME" ]]; then
	echo "ERRORE: home directory non valida per $TARGET_USER." >&2
	exit 1
fi

# Richiedi sudo subito
sudo -v

# =========================
# PREREQUISITI
# (su un sistema appena installato git potrebbe non essere presente)
# =========================
echo "[+] Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y curl git rsync openssh-client

# =========================
# FUNZIONI
# =========================

# Clona solo se la cartella non esiste già (lo script si può rilanciare)
clone_or_skip() {
	local url="$1" dest="$2"

	if [[ -d "$dest/.git" ]]; then
		echo "[=] $dest già presente, skip."
		return 0
	fi

	git clone "$url" "$dest"
}

# Verifica, senza prompt, se si può leggere il repo privato.
# Copre sia "nessuna chiave SSH" sia "chiave presente ma senza permessi".
has_repo_access() {
	GIT_TERMINAL_PROMPT=0 \
		GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10" \
		timeout 30 git ls-remote "$1" HEAD &>/dev/null
}

# =========================
# KEYBOARD LAYOUT
# =========================
read -r -p "Choose keyboard layout (it/us) [us]: " LAYOUT

case "${LAYOUT:-us}" in
it) SOURCES="[('xkb', 'it')]" ;;
*) SOURCES="[('xkb', 'us')]" ;;
esac

echo "[+] Applying keyboard layout: $SOURCES"
if ! gsettings set org.gnome.desktop.input-sources sources "$SOURCES"; then
	echo "AVVISO: impossibile applicare il layout (sessione grafica assente?)."
fi

# =========================
# Git global config
# =========================
git config --global init.defaultBranch master
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# =========================
# LINUX BACKUP REPO (privato: solo se si hanno i permessi)
# =========================
if has_repo_access "$BACKUP_REPO"; then
	echo "[+] Restoring from linux_backup..."

	if clone_or_skip "$BACKUP_REPO" "$HOME/linux_backup"; then
		RESTORE_BACKUP_DIR="$HOME/.pre-setup-backup/restore-$(date +%Y%m%d_%H%M%S)"
		mkdir -p "$RESTORE_BACKUP_DIR"

		rsync -av \
			--backup \
			--backup-dir="$RESTORE_BACKUP_DIR" \
			--exclude='/.git/' \
			"$HOME/linux_backup/" \
			"$HOME/"
	else
		echo "AVVISO: clone di linux_backup non riuscito, restore saltato."
	fi
else
	echo "[=] Nessun accesso a linux_backup (repo privato): restore saltato."
fi

# =========================
# GRUB CONFIGURATION
# =========================
echo "[+] Configuring GRUB..."

GRUB_FILE="/etc/default/grub"
GRUB_SOURCE="$REPO_ROOT/grub"
GRUB_BACKUP="${GRUB_FILE}.pre-setup-$(date +%Y%m%d_%H%M%S)"

if [[ -f "$GRUB_SOURCE" ]]; then
	# Salva la configurazione attualmente installata
	if [[ -f "$GRUB_FILE" ]]; then
		if sudo test -e "$GRUB_BACKUP"; then
			GRUB_BACKUP="${GRUB_BACKUP}-$$"
		fi

		if ! sudo cp -a "$GRUB_FILE" "$GRUB_BACKUP"; then
			echo "ERRORE: impossibile salvare la configurazione GRUB precedente."
			exit 1
		fi

		echo "[+] Previous GRUB configuration saved to:"
		echo "    $GRUB_BACKUP"
	fi

	# Applica la configurazione generica della repository
	if ! sudo install -o root -g root -m 0644 "$GRUB_SOURCE" "$GRUB_FILE"; then
		echo "ERRORE: impossibile installare la configurazione GRUB."
		exit 1
	fi

	# Rigenera la configurazione di GRUB
	if ! sudo update-grub; then
		echo "ERRORE: aggiornamento di GRUB non riuscito."
		exit 1
	fi
else
	echo "AVVISO: $GRUB_SOURCE non trovato, configurazione GRUB invariata."
fi

# =========================
# Directories
# =========================
mkdir -p "$HOME/scripts"
mkdir -p "$HOME/Desktop/42"
mkdir -p "$HOME/Desktop/42/examshell/"
mkdir -p "$HOME/Desktop/42/projects/"
mkdir -p "$HOME/.config"

# =========================
# BASH CONFIG REPO (pubblico: HTTPS)
# =========================
if clone_or_skip https://github.com/aale01/BASH_config.git "$HOME/.bashrc.d"; then
	BASHRC_LINE='source ~/.bashrc.d/.bashrc'

	if ! grep -Fqx "$BASHRC_LINE" "$HOME/.bashrc" 2>/dev/null; then
		echo "$BASHRC_LINE" >>"$HOME/.bashrc"
	fi
else
	echo "AVVISO: clone di BASH_config non riuscito, .bashrc invariato."
fi

# Nota: la nuova configurazione bash verrà applicata al prossimo login

exec ./setup-2.sh
