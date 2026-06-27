#!/bin/bash


# Config directory fissa
CONFIG_DIR="/home/alebe/.config/spicetify"
CUSTOM_APPS_DIR="$CONFIG_DIR/CustomApps"
APP_NAME="history-in-sidebar"

ZIP_URL="https://github.com/Bergbok/Spicetify-Creations/archive/refs/heads/dist/history-in-sidebar.zip"
TMP_DIR=$(mktemp -d)
ZIP_FILE="$TMP_DIR/history-in-sidebar.zip"

echo "Download in corso..."
curl -L "$ZIP_URL" -o "$ZIP_FILE"

echo "Estrazione..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

# Trova cartella estratta
EXTRACTED_FOLDER=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [ -z "$EXTRACTED_FOLDER" ]; then
  echo "Errore: zip non valido"
  exit 1
fi

# Crea CustomApps se non esiste
mkdir -p "$CUSTOM_APPS_DIR"

DEST_DIR="$CUSTOM_APPS_DIR/$APP_NAME"

echo "Installazione in $DEST_DIR..."
rm -rf "$DEST_DIR"
mv "$EXTRACTED_FOLDER" "$DEST_DIR"

echo "Configurazione Spicetify..."
spicetify config custom_apps "$APP_NAME"

echo "Applicazione modifiche..."
spicetify apply

rm -rf "$TMP_DIR"

echo "Fatto."
