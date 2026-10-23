#!/bin/bash

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
# SOFTWARES
# =========================
echo "[+] Installing additional softwares..."

bash ./setup-softwares.sh

# =========================
# DAILY APT / MAINTENANCE
# =========================
echo "[+] Configuring daily APT and maintenance scripts..."

bash ./setup-maintenance.sh

# =========================
# CLEANUP
# =========================
echo "[+] Cleaning up..."

sudo apt autoremove -y
sudo apt autoclean


echo "=== DONE ==="
echo "[+] Setup completed successfully."
echo ""
echo "[+] Backup pre-setup saved in: $HOME/.pre-setup-backup"
echo ""
echo "*** REBOOT REQUIRED ***"
echo ""
