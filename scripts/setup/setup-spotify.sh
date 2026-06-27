#!/bin/bash

curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc \
    | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" \
    | sudo tee /etc/apt/sources.list.d/spotify.list

# Grant write permissions to Spotify’s directory:
sudo chmod a+wr /usr/share/spotify
sudo chmod a+wr /usr/share/spotify/Apps -R

sudo apt-get update && sudo apt-get install -y spotify-client

echo "[+] Avvia Spotify e fai il login e attendi almeno 60 secondi..."

for ((i=60; i>=0; i--)); do
    printf "\r⏳ %2d secondi rimanenti" "$i"
    sleep 1
done

echo ""

until pgrep spotify >/dev/null; do
    echo "Spotify non avviato ancora..."
    sleep 3
done

echo "Spotify rilevato. Premi INVIO quando hai completato il login."
read -r
