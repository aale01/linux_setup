#!/bin/bash

set -e

WORKDIR="$HOME/opt"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

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
# SYSTEM UPDATE
########################################
info "Aggiornamento sistema..."
sudo apt update

info "Installazione dipendenze base..."
sudo apt install -y wget tar gzip xz-utils

########################################
# VS CODE
########################################
if command -v code >/dev/null 2>&1; then
	warning "VS Code già installato"
else
	info "Installazione VS Code..."
	wget --show-progress -O vscode.deb "https://vscode.download.prss.microsoft.com/dbazure/download/stable/7e7950df89d055b5a378379db9ee14290772148a/code_1.126.0-1782208079_amd64.deb"
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

	CLION_URL="https://download-cdn.jetbrains.com/cpp/CLion-2026.1.3.tar.gz"

	wget --show-progress -O clion.tar.gz "$CLION_URL"

	tar -xzf clion.tar.gz
	CLION_DIR=$(find . -maxdepth 1 -type d -name "clion-*")
	mv "$CLION_DIR" "$WORKDIR/clion"

	rm clion.tar.gz
	success "CLion installato"
fi

########################################
# PYCHARM
########################################
if [ -d "$WORKDIR/pycharm" ]; then
	warning "PyCharm già presente"
else
	info "Installazione PyCharm..."

	PYCHARM_URL="https://download-cdn.jetbrains.com/python/pycharm-2026.1.3.tar.gz"

	wget --show-progress -O pycharm.tar.gz "$PYCHARM_URL"

	tar -xzf pycharm.tar.gz
	PYCHARM_DIR=$(find . -maxdepth 1 -type d -name "pycharm-*")
	mv "$PYCHARM_DIR" "$WORKDIR/pycharm"

	rm pycharm.tar.gz
	success "PyCharm installato"
fi

########################################
# FIREFOX
########################################
# if [ -d "$WORKDIR/firefox" ]; then
#     warning "Firefox già presente"
# else
#     info "Installazione Firefox..."
#
#     FIREFOX_URL="https://download-installer.cdn.mozilla.net/pub/firefox/releases/152.0.3/linux-x86_64/it/firefox-152.0.3.tar.xz"
#
#     wget --show-progress -O firefox.tar.xz "$FIREFOX_URL"
#
#     tar -xf firefox.tar.xz
#     mv firefox "$WORKDIR/firefox"
#
#     rm firefox.tar.xz
#     success "Firefox installato"
# fi

########################################
# SLACK
########################################
if command -v slack >/dev/null 2>&1; then
	warning "Slack già installato"
else
	info "Installazione Slack..."

	SLACK_URL="https://downloads.slack-edge.com/desktop-releases/linux/x64/4.50.143/slack-4.50.143-0.1.el8.x86_64.rpm"

	wget --show-progress -O slack.rpm "$SLACK_URL"

	if command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y ./slack.rpm
	elif command -v yum >/dev/null 2>&1; then
		sudo yum localinstall -y ./slack.rpm
	else
		sudo apt install -y alien
		sudo alien -i slack.rpm
	fi

	rm slack.rpm
	success "Slack installato"
fi

echo ""

success "INSTALLAZIONE COMPLETATA"
