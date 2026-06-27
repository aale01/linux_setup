#!/bin/bash

rsync -a -v --backup --backup-dir="$HOME/.pre-setup-backup" --exclude=".git/" "$HOME/linux_backup/" "$HOME/"
