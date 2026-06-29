#!/bin/bash

# =========================
# Spotify
# =========================
echo "[+] Installing Spotify..."

sudo bash ./setup-spotify.sh

# =========================
# Spicetify
# =========================
# NOTA: questo script modifica e lancia un installer esterno.
# Verifica il contenuto prima di eseguire in ambienti critici.
echo "[+] Installing Spicetify..."

sudo bash setup-spicetify.sh

# =========================
# Spicetify - History in Sidebar
# =========================

echo "[+] Installazione Spicetify history-in-sidebar..."

sudo bash setup-history-in-sidebar.sh

# =========================
# HIBERNATION
# =========================
echo "[+] Setting up hibernation..."

sudo bash ./setup-hibernation.sh

# =========================
# SOFTWARES
# =========================
echo "[+] Installing additional softwares..."

sudo bash ./setup-softwares.sh

# =========================
# CLEANUP
# =========================
echo "[+] Cleaning up..."

sudo apt autoremove -y
sudo apt autoclean

# =========================
# FIX PERMISSIONS
# =========================
sudo chown -R $USER:$USER "$HOME"

echo "=== DONE ==="
echo "[+] Setup completed successfully."
echo ""
echo "[+] Backup pre-setup saved in: $HOME/.pre-setup-backup"
echo ""
echo "*** REBOOT REQUIRED ***"
echo ""
