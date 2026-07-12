#!/bin/bash

set -e

# /opt e' la cartella standard (FHS) per software di terze parti installato
# manualmente, condiviso da tutti gli utenti del sistema. Per questo serve
# sudo per scrivere al suo interno: scarichiamo i file in una cartella
# temporanea dell'utente, e solo dopo li spostiamo in /opt con sudo.
WORKDIR="/opt"
TMPDIR=$(mktemp -d)
ORIGINAL_FOLDER=$(pwd)

cleanup() {
	rm -rf "$TMPDIR"
}
trap cleanup EXIT

sudo mkdir -p "$WORKDIR"
cd "$TMPDIR"

########################################
# COLORI
########################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # reset

info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
	echo -e "${GREEN}[OK]${NC} $1"
}

warning() {
	echo -e "${YELLOW}[SKIP]${NC} $1"
}

error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

########################################
# ICONE / VOCI MENU (.desktop)
########################################
# Crea una voce nel menu applicazioni per programmi installati come tarball
# "portatili" (CLion, PyCharm, Firefox), che altrimenti non compaiono tra
# le app cercabili. Chrome/VSCode/Slack creano la loro voce da soli tramite
# .deb/.rpm, quindi non serve richiamare questa funzione per loro.
create_desktop_entry() {
	local name="$1"
	local exec_path="$2"
	local search_dir="$3"
	local comment="$4"
	local desktop_file="/usr/share/applications/${name// /-}.desktop"

	# Cerca automaticamente un'icona (svg preferita, altrimenti png) dentro
	# la cartella di installazione, per non dipendere da un nome/percorso
	# fisso che può cambiare da una versione all'altra. maxdepth 8 perché,
	# ad esempio, l'icona di Firefox è a 5 livelli di profondità
	# (browser/chrome/icons/default/default128.png).
	local icon_path
	icon_path=$(find "$search_dir" -maxdepth 8 -type f -iname "*.svg" 2>/dev/null | head -1)
	if [ -z "$icon_path" ]; then
		icon_path=$(find "$search_dir" -maxdepth 8 -type f \( -iname "*128*.png" -o -iname "*256*.png" \) 2>/dev/null | sort -r | head -1)
	fi
	if [ -z "$icon_path" ]; then
		icon_path=$(find "$search_dir" -maxdepth 8 -type f -iname "*.png" 2>/dev/null | head -1)
	fi
	if [ -z "$icon_path" ]; then
		icon_path="application-x-executable"
	fi

	sudo tee "$desktop_file" >/dev/null <<EOF
[Desktop Entry]
Name=$name
Comment=$comment
Exec="$exec_path" %f
Icon=$icon_path
Terminal=false
Type=Application
Categories=Development;
StartupWMClass=$name
EOF
	success "Icona/voce menu creata per $name"
}

# Crea un comando lanciabile da terminale da qualsiasi cartella, tramite un
# symlink in /usr/local/bin (già presente nel PATH di sistema). Necessario
# solo per CLion, PyCharm e Firefox: Chrome/VSCode/Slack registrano già da
# soli il proprio comando (google-chrome, code, slack) durante l'installazione.
create_command_symlink() {
	local command_name="$1"
	local target_path="$2"

	sudo ln -sf "$target_path" "/usr/local/bin/$command_name"
	success "Comando '$command_name' disponibile da terminale"
}

########################################
# SYSTEM UPDATE
########################################
info "Aggiornamento sistema..."
sudo apt update

info "Installazione dipendenze base..."
sudo apt install -y wget tar gzip xz-utils jq

########################################
# GOOGLE CHROME
########################################
if command -v google-chrome >/dev/null 2>&1; then
	warning "Google Chrome già installato"
else
	info "Installazione Google Chrome..."
	# "..._current_amd64.deb" e' gia' un link ufficiale Google che punta
	# sempre all'ultima versione stabile: nessuna modifica necessaria qui.
	wget --show-progress -O google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
	sudo apt install -y ./google-chrome.deb
	rm google-chrome.deb
	success "Google Chrome installato"
fi

########################################
# VS CODE
########################################
if command -v code >/dev/null 2>&1; then
	warning "VS Code già installato"
else
	info "Installazione VS Code..."
	# Pre-accetto la domanda (altrimenti interattiva) di aggiungere il
	# repository Microsoft: senza questo repo, VS Code su Linux non ha un
	# updater interno e resterebbe bloccato alla versione installata ora.
	echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
	# Link ufficiale Microsoft che reindirizza sempre all'ultima release stabile.
	wget --show-progress -O vscode.deb "https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
	sudo apt install -y ./vscode.deb
	rm vscode.deb
	success "VS Code installato"
fi

########################################
# CLION
########################################
if [ -d "$WORKDIR/clion" ]; then
	warning "CLion già presente"
else
	info "Installazione CLion..."

	# API pubblica (non ufficialmente documentata, ma stabile e usata da anni)
	# di JetBrains: restituisce sempre il link alla build Linux più recente.
	CLION_URL=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=CL&latest=true&type=release" | jq -r '.CL[0].downloads.linux.link')

	wget --show-progress -O clion.tar.gz "$CLION_URL"
	tar -xzf clion.tar.gz
	CLION_DIR=$(find . -maxdepth 1 -type d -name "clion-*")

	sudo mv "$CLION_DIR" "$WORKDIR/clion"
	rm clion.tar.gz

	# L'IDE ha un self-updater interno (Help > Check for Updates) che deve
	# poter scrivere nella propria cartella per applicare le patch. Restando
	# di proprieta' di root fallirebbe con "installation path is not
	# writable": la rendo quindi di proprieta' dell'utente che lancia lo
	# script (la cartella /opt resta comunque root, solo il suo contenuto
	# diventa scrivibile da te).
	sudo chown -R "$(id -u):$(id -g)" "$WORKDIR/clion"

	chmod +x "$WORKDIR/clion/bin/clion.sh"

	# Dalle versioni recenti JetBrains affianca allo script legacy
	# (bin/clion.sh) un launcher nativo (bin/clion) più veloce e ora
	# raccomandato: uso quello se presente, altrimenti ripiego sullo script.
	CLION_LAUNCHER="$WORKDIR/clion/bin/clion.sh"
	if [ -x "$WORKDIR/clion/bin/clion" ]; then
		CLION_LAUNCHER="$WORKDIR/clion/bin/clion"
	fi

	create_command_symlink "clion" "$CLION_LAUNCHER"

	# Decommentare per creare un icona nelle applicazioni ----------------------------------------------------------------------------
	# create_desktop_entry "CLion" "$CLION_LAUNCHER" "$WORKDIR/clion" "JetBrains CLion IDE"

	success "CLion installato"
fi

########################################
# PYCHARM
########################################
if [ -d "$WORKDIR/pycharm" ]; then
	warning "PyCharm già presente"
else
	info "Installazione PyCharm..."

	# code=PCP -> PyCharm Professional (stesso pacchetto che scaricava lo
	# script originale). Per la versione Community gratuita usa PCC.
	PYCHARM_URL=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&type=release" | jq -r '.PCP[0].downloads.linux.link')

	wget --show-progress -O pycharm.tar.gz "$PYCHARM_URL"
	tar -xzf pycharm.tar.gz
	PYCHARM_DIR=$(find . -maxdepth 1 -type d -name "pycharm-*")

	sudo mv "$PYCHARM_DIR" "$WORKDIR/pycharm"
	rm pycharm.tar.gz

	# Vedi commento equivalente nella sezione CLion: serve per il self-updater
	# interno dell'IDE.
	sudo chown -R "$(id -u):$(id -g)" "$WORKDIR/pycharm"

	chmod +x "$WORKDIR/pycharm/bin/pycharm.sh"

	# Stesso discorso di CLion: preferisco il launcher nativo se disponibile.
	PYCHARM_LAUNCHER="$WORKDIR/pycharm/bin/pycharm.sh"
	if [ -x "$WORKDIR/pycharm/bin/pycharm" ]; then
		PYCHARM_LAUNCHER="$WORKDIR/pycharm/bin/pycharm"
	fi

	create_command_symlink "pycharm" "$PYCHARM_LAUNCHER"

	# Decommentare per creare un icona nelle applicazioni ----------------------------------------------------------------------------
	# create_desktop_entry "PyCharm" "$PYCHARM_LAUNCHER" "$WORKDIR/pycharm" "JetBrains PyCharm IDE"

	success "PyCharm installato"
fi

########################################
# FIREFOX
########################################
if [ -d "$WORKDIR/firefox" ]; then
	warning "Firefox già presente"
else
	info "Installazione Firefox..."

	# Link ufficiale Mozilla che reindirizza sempre all'ultima release stabile
	# in italiano per Linux 64bit (formato archivio .tar.xz o .tar.bz2 a seconda
	# della build corrente: "tar -xf" rileva il formato automaticamente).
	FIREFOX_URL="https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=it"

	wget --show-progress -O firefox.tar.xz "$FIREFOX_URL"
	tar -xf firefox.tar.xz
	# L'archivio si estrae sempre in una cartella chiamata "firefox",
	# indipendentemente dalla lingua scelta.
	sudo mv firefox "$WORKDIR/firefox"
	rm firefox.tar.xz

	chmod +x "$WORKDIR/firefox/firefox"
	create_desktop_entry "Firefox" "$WORKDIR/firefox/firefox" "$WORKDIR/firefox" "Mozilla Firefox Web Browser"
	# /usr/local/bin ha priorità su /usr/bin nel PATH di sistema: se Ubuntu
	# aveva già un comando "firefox" di sistema (es. il pacchetto-ponte che
	# installa lo snap), da qui in poi digitando "firefox" da terminale
	# partirà invece questa versione installata manualmente.
	create_command_symlink "firefox" "$WORKDIR/firefox/firefox"

	success "Firefox installato"
fi

########################################
# SLACK
########################################
# Slack non offre un link diretto "sempre ultima versione" per .deb/.rpm
# (bisogna prendere ogni volta il numero di versione dalla pagina di
# download). Lo snap ufficiale invece punta sempre alla build più recente
# e si aggiorna da solo in background: nessun URL da mantenere aggiornato,
# e l'icona/voce di menu viene creata automaticamente da snapd.
if command -v slack >/dev/null 2>&1 || snap list slack >/dev/null 2>&1; then
	warning "Slack già installato"
else
	info "Installazione Slack (snap)..."
	sudo snap install slack
	success "Slack installato"
fi

########################################
# AGGIORNAMENTO CACHE MENU/ICONE
########################################
info "Aggiornamento database applicazioni..."
sudo update-desktop-database /usr/share/applications 2>/dev/null || true

echo ""
success "INSTALLAZIONE COMPLETATA"

cd "$ORIGINAL_FOLDER"
	success "Slack installato"
fi

########################################
# AGGIORNAMENTO CACHE MENU/ICONE
########################################
info "Aggiornamento database applicazioni..."
sudo update-desktop-database /usr/share/applications 2>/dev/null || true

echo ""
success "INSTALLAZIONE COMPLETATA"

cd "$ORIGINAL_FOLDER"
