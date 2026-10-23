#!/bin/bash

if zenity --question \
	--title="Pulizia cache APT" \
	--text="Vuoi pulire la cache dei pacchetti?\n\nVerranno eseguiti:\nsudo apt clean\nsudo apt autoclean" \
	--ok-label="Sì, pulisci" \
	--cancel-label="Annulla"; then

	x-terminal-emulator -e bash -c '
        echo "Pulizia cache APT..."
        sudo apt clean && sudo apt autoclean
        echo
        echo "Pulizia completata."
        read -p "Premi INVIO per chiudere..."
    '
fi
