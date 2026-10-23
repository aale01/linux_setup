# linux_setup
Script personali per automatizzare il provisioning di una workstation Linux, con focus su Ubuntu/Debian-based desktop.
Il progetto installa pacchetti di sistema, strumenti di sviluppo, Neovim/LazyVim, Spotify/Spicetify, ibernazione, manutenzione APT giornaliera e alcune configurazioni utente.
> Nota: questi script sono pensati per un setup personale e sono forniti così come sono. Leggili prima di eseguirli, soprattutto perché modificano configurazioni di sistema e file nella home.
```text
linux_setup/
├── grub
├── LICENSE
├── README.md
├── project_structure
└── scripts/
    ├── bin/
    │   ├── apt-daily-update.sh
    │   └── clean-cache.sh
    ├── config/
    │   ├── autostart/
    │   └── systemd/user/
    ├── setup/
    │   ├── packages.yaml
    │   ├── setup-1.sh
    │   ├── setup-2.sh
    │   ├── setup-3.sh
    │   ├── setup-4.sh
    │   ├── setup-5.sh
    │   ├── setup-hibernation.sh
    │   ├── setup-history-in-sidebar.sh
    │   ├── setup-lazyvim-package.sh
    │   ├── setup-maintenance.sh
    │   ├── setup-packages.sh
    │   ├── setup-softwares.sh
    │   ├── setup-spicetify.sh
    │   ├── setup-spotify.sh
    │   ├── uninstall-spiceticy.sh
    │   └── uninstall-spotify.sh
    ├── system/
    │   ├── apt-update-resume-hook
    │   └── apt-update-upgrade
    ├── deb-install
    └── monitoring.sh
```
Il flusso principale parte da:
```bash
scripts/setup/setup-1.sh
```
e prosegue automaticamente con gli script successivi.
1. `setup-1.sh`
   - Verifica che lo script sia eseguito da utente normale, non da root.
   - Richiede `sudo` quando necessario.
   - Installa prerequisiti minimi.
   - Configura layout tastiera GNOME.
   - Configura Git globale.
   - Tenta il restore dal repository privato `linux_backup`, se accessibile.
   - Installa la configurazione GRUB presente nel file `grub`.
   - Crea alcune directory personali.
   - Clona la configurazione Bash personale.
   - Avvia `setup-2.sh`.
2. `setup-2.sh`
   - Aggiorna il sistema con APT.
   - Avvia `setup-packages.sh`.
3. `setup-packages.sh`
   - Installa i pacchetti definiti in `scripts/setup/packages.yaml`.
   - Configura repository esterni, ad esempio NodeSource e GitHub CLI.
   - Installa pacchetti aggiuntivi.
   - Aggiunge l’utente ai gruppi configurati.
   - Scrive un log in `/var/log/setup_YYYYMMDD_HHMMSS.log`.
4. `setup-3.sh`
   - Installa Neovim dalla release ufficiale.
   - Installa pacchetti necessari a LazyVim tramite `setup-lazyvim-package.sh`.
5. `setup-4.sh`
   - Esegue backup delle directory Neovim esistenti.
   - Clona LazyVim starter in `~/.config/nvim`.
   - Sostituisce la configurazione Lua con il repository personale `LazyVim_config`.
   - Installa Meslo Nerd Font.
6. `setup-5.sh`
   - Installa Spotify.
   - Installa e applica Spicetify.
   - Installa la configurazione history/sidebar per Spicetify.
   - Configura ibernazione.
   - Installa software aggiuntivi.
   - Configura manutenzione APT giornaliera.
   - Esegue pulizia finale con `apt autoremove` e `apt autoclean`.
- Distribuzione Linux Debian/Ubuntu-based.
- Bash.
- Connessione Internet.
- Utente con privilegi `sudo`.
- Ambiente desktop GNOME per alcune configurazioni utente.
- Git e SSH configurati se vuoi accedere ai repository privati personali usati dagli script.
Questi script possono modificare o sovrascrivere configurazioni esistenti, tra cui:
- `~/.bashrc`
- `~/.bashrc.d`
- `~/.config/nvim`
- `~/.local/share/nvim`
- `~/.local/state/nvim`
- `~/.cache/nvim`
- `/etc/default/grub`
- `/etc/initramfs-tools/conf.d/resume`
- `/etc/polkit-1/rules.d/90-enable-hibernate.rules`
- `/etc/systemd/sleep.conf.d/disable-hybrid.conf`
- `/usr/local/bin`
- `/usr/local/sbin`
- `/usr/lib/systemd/system-sleep`
Lo script crea backup per alcune configurazioni, ad esempio GRUB e directory Neovim, ma è comunque consigliato fare un backup completo prima dell’esecuzione.
Clona il repository:
```bash
git clone https://github.com/aale01/linux_setup.git
cd linux_setup
```
Rendi eseguibili gli script, se necessario:
```bash
chmod +x scripts/setup/*.sh
chmod +x scripts/bin/*.sh
chmod +x scripts/system/*
```
Avvia il setup principale come utente normale:
```bash
cd scripts/setup
./setup-1.sh
```
Non eseguire `setup-1.sh` con `sudo`: lo script controlla esplicitamente che venga avviato da utente normale e richiede `sudo` solo quando serve.
Per installare soltanto i pacchetti definiti in `packages.yaml`:
```bash
cd scripts/setup
sudo bash ./setup-packages.sh
```
Oppure specificando un file YAML diverso:
```bash
sudo bash ./setup-packages.sh ./packages.yaml
```
Il file `scripts/setup/packages.yaml` contiene i gruppi di pacchetti installati da APT.
Categorie principali:
- `base_system`
- `development`
- `python`
- `shell_terminal`
- `editors_git`
- `cli_modern`
- `network_security`
- `monitoring`
- `virtualization`
- `multimedia`
- `desktop`
Contiene anche sezioni per:
- repository esterni;
- pacchetti npm;
- gruppi di sistema a cui aggiungere l’utente.
Lo script `setup-softwares.sh` installa diversi software desktop e di sviluppo, tra cui:
- Google Chrome
- Visual Studio Code
- JetBrains CLion
- JetBrains PyCharm Professional
- Firefox
- Slack
Alcuni software vengono installati in `/opt` e collegati in `/usr/local/bin`.
Il setup installa Neovim in:
```text
/opt/nvim-linux-x86_64
```
La configurazione LazyVim viene installata in:
```text
~/.config/nvim
```
Prima dell’installazione vengono rinominate eventuali directory esistenti con suffisso `.bak_TIMESTAMP`.
Il setup installa Spotify dal repository ufficiale e poi configura Spicetify.
Durante l’installazione di Spotify viene richiesto di:
1. avviare Spotify;
2. fare login;
3. confermare premendo `INVIO`.
Lo script Spicetify scarica ed esegue l’installer ufficiale da GitHub e applica la configurazione con:
```bash
spicetify backup apply
```
Lo script `setup-hibernation.sh` prova a configurare l’ibernazione usando la swap attiva.
Operazioni principali:
- rileva il device di swap;
- legge l’UUID della swap;
- configura `/etc/initramfs-tools/conf.d/resume`;
- aggiunge `resume=UUID=...` alla configurazione GRUB;
- esegue `update-grub`;
- esegue `update-initramfs -u`;
- abilita l’ibernazione tramite regola PolicyKit;
- disabilita hybrid sleep e suspend-then-hibernate;
- installa `gnome-shell-extension-manager`;
- modifica alcune impostazioni GNOME di alimentazione, se la sessione D-Bus utente è disponibile.
Se non viene trovata una swap valida o se il sistema non supporta `disk` in `/sys/power/state`, lo script salta la configurazione.
Lo script `setup-maintenance.sh` installa script e hook per la manutenzione del sistema.
Installa script utente in:
```text
~/.local/bin
```
Installa configurazioni utente in:
```text
~/.config/autostart
~/.config/systemd/user
```
Installa script amministrativi in:
```text
/usr/local/sbin
```
Configura inoltre un hook systemd sleep in:
```text
/usr/lib/systemd/system-sleep/apt-update-resume-hook
```
| Script | Descrizione |
| --- | --- |
| `scripts/setup/setup-1.sh` | Entry point del setup completo. |
| `scripts/setup/setup-2.sh` | Aggiornamento sistema e installazione pacchetti base. |
| `scripts/setup/setup-3.sh` | Installazione Neovim e pacchetti LazyVim. |
| `scripts/setup/setup-4.sh` | Installazione LazyVim, configurazione personale e font Meslo Nerd Font. |
| `scripts/setup/setup-5.sh` | Spotify, Spicetify, ibernazione, software extra e manutenzione. |
| `scripts/setup/setup-packages.sh` | Installazione pacchetti da `packages.yaml`. |
| `scripts/setup/setup-softwares.sh` | Installazione software desktop aggiuntivi. |
| `scripts/setup/setup-hibernation.sh` | Configurazione ibernazione. |
| `scripts/setup/setup-maintenance.sh` | Installazione script di manutenzione APT. |
| `scripts/setup/setup-spotify.sh` | Installazione Spotify. |
| `scripts/setup/setup-spicetify.sh` | Installazione e applicazione Spicetify. |
| `scripts/setup/uninstall-spotify.sh` | Rimozione Spotify. |
| `scripts/setup/uninstall-spiceticy.sh` | Rimozione Spicetify. |
Alcuni script fanno riferimento a repository personali:
- `git@github.com:aale01/linux_backup.git`
- `https://github.com/aale01/BASH_config.git`
- `git@github.com:aale01/LazyVim_config.git`
Il restore da `linux_backup` viene saltato automaticamente se il repository privato non è accessibile.
Per i repository SSH privati serve una chiave SSH configurata e autorizzata su GitHub.
Lo script `setup-packages.sh` scrive un log in:
```text
/var/log/setup_YYYYMMDD_HHMMSS.log
```
In caso di pacchetti falliti, controlla il log indicato a fine esecuzione.
Prima di avviare il setup:
```bash
git status
find scripts -type f -name "*.sh" -maxdepth 3 -print
sed -n '1,160p' scripts/setup/setup-1.sh
sed -n '1,200p' scripts/setup/packages.yaml
```
Consigliato eseguire il tutto prima in una VM o su un sistema sacrificabile.
Sono presenti script dedicati per rimuovere Spotify e Spicetify:
```bash
cd scripts/setup
./uninstall-spotify.sh
./uninstall-spiceticy.sh
```
> Nota: questo progetto è distribuito sotto licenza MIT. Vedi il file [LICENSE](LICENSE) per i dettagli.
