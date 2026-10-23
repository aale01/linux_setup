#!/bin/bash

# File che registra l'ultima richiesta
STATE_FILE="$HOME/.last-apt-update-prompt"

TODAY=$(date +%F)

# Funzione per centrare la finestra di dialogo nello schermo
center_zenity() {
	local title="$1"
	local window=""
	local screen_w screen_h win_w win_h x y

	# Attende fino a 3 secondi la comparsa della finestra
	for _ in {1..30}; do
		window=$(wmctrl -l | grep -F "$title" | head -n 1 | awk '{print $1}')
		[[ -n "$window" ]] && break
		sleep 0.1
	done

	[[ -z "$window" ]] && return

	# Dimensioni dello schermo principale
	read -r screen_w screen_h < <(
		xrandr | awk '/\*/ {split($1,a,"x"); print a[1],a[2]; exit}'
	)

	# Dimensioni correnti della finestra
	read -r win_w win_h < <(
		wmctrl -lG | awk -v id="$window" '$1 == id {print $5, $6; exit}'
	)

	[[ -z "$screen_w" || -z "$screen_h" ||
		-z "$win_w" || -z "$win_h" ]] && return

	# Calcola le coordinate centrali
	x=$(((screen_w - win_w) / 2))
	y=$(((screen_h - win_h) / 2))

	wmctrl -ir "$window" -e "0,$x,$y,-1,-1"
}

# Se abbiamo già chiesto oggi, termina
if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "$TODAY" ]]; then
	exit 0
fi

# Registra la data prima di mostrare la richiesta
echo "$TODAY" >"$STATE_FILE"

# Mostra la finestra e salva il suo PID
zenity --question \
	--title="Aggiornamenti di sistema" \
	--width=300 \
	--text="<b>Vuoi aggiornare tutti i pacchetti oggi?</b>\n\nVerranno eseguiti:\n\n<b>sudo apt update &amp;&amp; sudo apt upgrade</b>" \
	--ok-label="Sì, aggiorna" \
	--cancel-label="No, grazie" &

ZENITY_PID=$!
center_zenity "Aggiornamenti di sistema"
wait "$ZENITY_PID"
RESULT=$?

# Se l'utente ha confermato
if [[ "$RESULT" -eq 0 ]]; then

	# Avvia direttamente il terminale di aggiornamento
  STATUS_FILE=$(mktemp "$HOME/.apt-update-status.XXXXXX")

  # Apre il terminale e avvia l'aggiornamento
  gnome-terminal --title="Aggiornamento Ubuntu" --wait -- bash -c '
          STATUS_FILE="$1"

          pkexec /usr/local/sbin/apt-update-upgrade
          status=$?

          printf "%s\n" "$status" > "$STATUS_FILE"

          if [[ "$status" -ne 0 ]]; then
              echo
              echo "Aggiornamento non riuscito."
              echo "L output e gli eventuali errori sono visibili qui."
              echo
              read -r -p "Premi Invio per chiudere il terminale..."
          fi

          exit "$status"
      ' _ "$STATUS_FILE" &

  TERMINAL_PID=$!

  # Attende che l'aggiornamento comunichi il risultato
  while [[ ! -s "$STATUS_FILE" ]]; do
    if ! kill -0 "$TERMINAL_PID" 2>/dev/null; then
      break
    fi
    sleep 0.2
  done

  UPDATE_RESULT=$(cat "$STATUS_FILE" 2>/dev/null)
  rm -f "$STATUS_FILE"

  if [[ "$UPDATE_RESULT" == "0" ]]; then

    # Attende la chiusura automatica del terminale
    wait "$TERMINAL_PID"

    zenity --info \
      --title="Aggiornamenti completati" \
      --width=350 \
      --text="L'aggiornamento è terminato correttamente." &
    ZENITY_PID=$!
    center_zenity "Aggiornamenti completati"
    wait "$ZENITY_PID"

  else

    # Il terminale rimane aperto mentre appare l'errore
    zenity --error \
      --title="Aggiornamento non riuscito" \
      --width=350 \
      --text="Si è verificato un errore durante l'aggiornamento.\n\nIl terminale contiene i dettagli.\n\nLog completo:\n/var/log/apt-manual-upgrade.log" &
    ZENITY_PID=$!
    center_zenity "Aggiornamento non riuscito"
    wait "$ZENITY_PID"

    # Non chiude il terminale finché non lo chiudi tu
    wait "$TERMINAL_PID"
  fi
fi
