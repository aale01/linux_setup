#!/usr/bin/env bash

set -Eeuo pipefail

SOURCE="$HOME/linux_setup/"
BACKUP_DIR="$HOME/.pre-setup-backup"

if [[ ! -d "$SOURCE" ]]; then
    echo "Errore: directory sorgente non trovata: $SOURCE" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"

rsync -av \
    --backup \
    --backup-dir="$BACKUP_DIR" \
    --exclude='.git/' \
    "$SOURCE" "$HOME/"
