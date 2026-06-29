#!/bin/bash

# =========================
# SYSTEM UPDATE
# =========================
sudo apt update && sudo apt upgrade -y

# =========================
# BASE SYSTEM
# =========================
echo "[+] Installing base tools..."

sudo bash ./setup-packages.sh

sudo exec ./setup-3.sh
