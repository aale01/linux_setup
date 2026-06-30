#!/bin/bash

# Rimuove il programma
sudo apt purge -y spotify-client

# Rimuove eventuali dipendenze non più necessarie
sudo apt autoremove -y

# Elimina il repository
sudo rm -f /etc/apt/sources.list.d/spotify.list

# Elimina la chiave GPG
sudo rm -f /etc/apt/trusted.gpg.d/spotify.gpg

# Aggiorna l'indice dei pacchetti
sudo apt update

# Se vuoi eliminare anche le impostazioni utente
# Spotify salva configurazioni e cache nella tua home. Per rimuoverle:
rm -rf ~/.config/spotify
rm -rf ~/.cache/spotify

# Su alcune distribuzioni potrebbe esserci anche:
rm -rf ~/.local/share/spotify
