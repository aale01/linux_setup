#!/bin/bash

curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh -o /tmp/spicetify_install.sh
sed -i 's/read -r choice < \/dev\/tty/choice="y"/' /tmp/spicetify_install.sh
sh /tmp/spicetify_install.sh
rm -f /tmp/spicetify_install.sh

spicetify backup apply

sleep 1
