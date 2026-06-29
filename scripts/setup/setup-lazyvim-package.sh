#!/bin/bash

sudo apt install -y xclip fzf \
	imagemagick \
	texlive-latex-base \
	python3-pynvim \
	latexmk zathura \
	zathura-pdf-poppler \
	biber xdotool

sudo apt install -y npm

# install tree-sitter-cli
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=$HOME/.npm-global/bin:$PATH' >>~/.bashrc
source ~/.bashrc
npm install -g tree-sitter-cli

npm install -g @mermaid-js/mermaid-cli

sudo apt install -y fd-find
mkdir -p ~/.local/bin
ln -sf $(which fdfind) ~/.local/bin/fd
