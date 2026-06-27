#!/bin/bash

set -e

WORKDIR="$HOME/opt"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "=== Aggiornamento sistema ==="
sudo apt update

echo "=== Installazione dipendenze base ==="
sudo apt install -y wget tar gzip xz-utils gdebi-core

########################################
# VS CODE (.deb)
########################################
echo "=== Installazione VS Code ==="
wget -O vscode.deb "https://vscode.download.prss.microsoft.com/dbazure/download/stable/7e7950df89d055b5a378379db9ee14290772148a/code_1.126.0-1782208079_amd64.deb"
sudo apt install -y ./vscode.deb
rm vscode.deb

########################################
# CLION (.tar.gz)
########################################
echo "=== Installazione CLion ==="
wget -O clion.tar.gz "https://www.jetbrains.com/clion/download/download-thanks.html?platform=linux"

tar -xzf clion.tar.gz
CLION_DIR=$(find . -maxdepth 1 -type d -name "clion-*")
mv $CLION_DIR "$WORKDIR/clion"
rm clion.tar.gz

########################################
# PYCHARM (.tar.gz)
########################################
echo "=== Installazione PyCharm ==="
wget -O pycharm.tar.gz "https://www.jetbrains.com/pycharm/download/download-thanks.html?platform=linux"

tar -xzf pycharm.tar.gz
PYCHARM_DIR=$(find . -maxdepth 1 -type d -name "pycharm-*")
mv $PYCHARM_DIR "$WORKDIR/pycharm"
rm pycharm.tar.gz

########################################
# FIREFOX (.tar.xz)
########################################
# echo "=== Installazione Firefox ==="
# wget -O firefox.tar.xz "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=it"
#
# tar -xf firefox.tar.xz
# mv firefox "$WORKDIR/firefox"
# rm firefox.tar.xz

########################################
# SLACK (.rpm RHEL / Fedora)
########################################
echo "=== Installazione Slack ==="

SLACK_URL="https://downloads.slack-edge.com/desktop-releases/linux/x64/4.50.143/slack-4.50.143-0.1.el8.x86_64.rpm"

wget -O slack.rpm "$SLACK_URL"

# installazione (Debian/Ubuntu NON nativo RPM → serve alien o conversione)
if command -v dnf >/dev/null 2>&1; then
	sudo dnf install -y ./slack.rpm
elif command -v yum >/dev/null 2>&1; then
	sudo yum localinstall -y ./slack.rpm
else
	echo "Sistema non RPM-based: installo alien per conversione .deb"
	sudo apt install -y alien
	sudo alien -i slack.rpm
fi

rm slack.rpm
