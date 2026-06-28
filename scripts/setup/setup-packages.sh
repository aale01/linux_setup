#!/usr/bin/env bash
# ==============================================================================
# setup.sh — Installazione pacchetti Ubuntu da packages.yaml
# Uso: sudo bash setup.sh [packages.yaml]
# ==============================================================================

set -euo pipefail

PACKAGES_FILE="${1:-packages.yaml}"

# ------------------------------------------------------------------------------
# Colori e helper
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

LOG_FILE="/var/log/setup_$(date +%Y%m%d_%H%M%S).log"
FAILED_PKGS=()
INSTALLED_COUNT=0

log()     { echo -e "${BLUE}[INFO]${RESET}  $*" | tee -a "$LOG_FILE"; }
ok()      { echo -e "${GREEN}[OK]${RESET}    $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*" | tee -a "$LOG_FILE"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" | tee -a "$LOG_FILE"; }
section() { echo -e "\n${BOLD}━━━  $*  ━━━${RESET}\n" | tee -a "$LOG_FILE"; }

# ------------------------------------------------------------------------------
# Controllo root
# ------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    error "Esegui lo script come root: sudo bash $0"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║        Setup Ubuntu — $(date +%Y-%m-%d)         ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"
log "Log: $LOG_FILE"
log "Pacchetti da: $PACKAGES_FILE"
log "Utente: $REAL_USER"

# ------------------------------------------------------------------------------
# Controllo file YAML
# ------------------------------------------------------------------------------
if [[ ! -f "$PACKAGES_FILE" ]]; then
    error "File non trovato: $PACKAGES_FILE"
    exit 1
fi

# ==============================================================================
# STEP 1 — Bootstrap: installa yq (necessario per leggere il YAML)
# ==============================================================================
section "STEP 1 — Bootstrap yq"

if command -v yq &>/dev/null && yq --version 2>&1 | grep -q "mikefarah"; then
    ok "yq già installato ($(yq --version))"
else
    log "Installo yq (mikefarah) da GitHub..."
    YQ_VERSION=$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
        -o /usr/local/bin/yq
    chmod +x /usr/local/bin/yq
    ok "yq $YQ_VERSION installato"
fi

# ==============================================================================
# STEP 2 — Aggiornamento sistema
# ==============================================================================
section "STEP 2 — Aggiornamento sistema"
apt-get update -qq  | tee -a "$LOG_FILE"
apt-get upgrade -y  | tee -a "$LOG_FILE"
ok "Sistema aggiornato"

# ==============================================================================
# STEP 3 — Pacchetti APT (letti da YAML)
# ==============================================================================
section "STEP 3 — Pacchetti APT"

mapfile -t APT_GROUPS < <(yq '.apt | keys | .[]' "$PACKAGES_FILE")

for group in "${APT_GROUPS[@]}"; do
    log "Gruppo: $group"
    mapfile -t pkgs < <(yq ".apt.${group}[]" "$PACKAGES_FILE")

    for pkg in "${pkgs[@]}"; do
        if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
            ok "$pkg"
            (( INSTALLED_COUNT++ )) || true
        else
            error "$pkg — fallito"
            FAILED_PKGS+=("$pkg")
        fi
    done
done

# ==============================================================================
# STEP 4 — Node.js via NodeSource PPA (versione da YAML)
# ==============================================================================
section "STEP 4 — Node.js (NodeSource)"

if command -v node &>/dev/null; then
    warn "Node.js già installato ($(node --version)) — salto"
else
    NODE_VER=$(yq '.external.nodesource.version' "$PACKAGES_FILE")
    log "Aggiungo NodeSource PPA per Node.js ${NODE_VER}.x..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VER}.x" | bash - >> "$LOG_FILE" 2>&1

    mapfile -t NODE_PKGS < <(yq '.external.nodesource.packages[]' "$PACKAGES_FILE")
    for pkg in "${NODE_PKGS[@]}"; do
        if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
            ok "$pkg"
            (( INSTALLED_COUNT++ )) || true
        else
            error "$pkg — fallito"
            FAILED_PKGS+=("$pkg")
        fi
    done
fi

# ==============================================================================
# STEP 5 — GitHub CLI (repo ufficiale)
# ==============================================================================
section "STEP 5 — GitHub CLI"

if command -v gh &>/dev/null; then
    warn "GitHub CLI già installato — salto"
else
    log "Aggiungo repo GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >> "$LOG_FILE" 2>&1
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list >> "$LOG_FILE"
    apt-get update -qq >> "$LOG_FILE" 2>&1

    mapfile -t GH_PKGS < <(yq '.external.github_cli.packages[]' "$PACKAGES_FILE")
    for pkg in "${GH_PKGS[@]}"; do
        if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
            ok "$pkg"
            (( INSTALLED_COUNT++ )) || true
        else
            error "$pkg — fallito"
            FAILED_PKGS+=("$pkg")
        fi
    done
fi

# ==============================================================================
# STEP 6 — Binari da GitHub Releases (letti da YAML)
# ==============================================================================
section "STEP 6 — GitHub Releases"

mapfile -t RELEASE_NAMES < <(yq '.external.github_releases[].name' "$PACKAGES_FILE")

for i in "${!RELEASE_NAMES[@]}"; do
    name=$(yq ".external.github_releases[${i}].name"   "$PACKAGES_FILE")
    repo=$(yq ".external.github_releases[${i}].repo"   "$PACKAGES_FILE")
    binary=$(yq ".external.github_releases[${i}].binary" "$PACKAGES_FILE")
    asset_template=$(yq ".external.github_releases[${i}].asset" "$PACKAGES_FILE")

    if command -v "$binary" &>/dev/null; then
        warn "$name già installato — salto"
        continue
    fi

    log "Scarico $name da $repo..."
    version=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')

    if [[ -z "$version" ]]; then
        error "Impossibile recuperare versione di $name — skip"
        FAILED_PKGS+=("$name")
        continue
    fi

    asset="${asset_template/\{version\}/$version}"
    url="https://github.com/${repo}/releases/download/v${version}/${asset}"

    TMP=$(mktemp -d)
    if curl -fsSL "$url" -o "${TMP}/${asset}"; then
        tar -xzf "${TMP}/${asset}" -C "$TMP"
        install -m 755 "${TMP}/${binary}" "/usr/local/bin/${binary}"
        rm -rf "$TMP"
        ok "$name $version installato in /usr/local/bin/$binary"
        (( INSTALLED_COUNT++ )) || true
    else
        error "Download fallito per $name"
        FAILED_PKGS+=("$name")
        rm -rf "$TMP"
    fi
done

# ==============================================================================
# STEP 7 — Gruppi utente (letti da YAML)
# ==============================================================================
section "STEP 7 — Gruppi utente"

mapfile -t GROUPS < <(yq '.external.libvirt_groups[]' "$PACKAGES_FILE")
for grp in "${GROUPS[@]}"; do
    if getent group "$grp" &>/dev/null; then
        usermod -aG "$grp" "$REAL_USER" 2>/dev/null && \
            ok "Utente '$REAL_USER' aggiunto al gruppo '$grp'" || \
            warn "Impossibile aggiungere '$REAL_USER' a '$grp'"
    else
        warn "Gruppo '$grp' non esiste — salto"
    fi
done

# ==============================================================================
# STEP 8 — Pulizia
# ==============================================================================
section "STEP 8 — Pulizia"
apt-get autoremove -y >> "$LOG_FILE" 2>&1
apt-get autoclean  -y >> "$LOG_FILE" 2>&1
ok "Cache apt ripulita"

# ==============================================================================
# RIEPILOGO
# ==============================================================================
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗"
echo -e "║              RIEPILOGO FINALE            ║"
echo -e "╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${GREEN}✔ Installati: ${INSTALLED_COUNT} pacchetti${RESET}"

if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}✘ Falliti (${#FAILED_PKGS[@]}):${RESET}"
    for p in "${FAILED_PKGS[@]}"; do
        echo -e "  ${RED}•${RESET} $p"
    done
    echo ""
    warn "Dettagli nel log: $LOG_FILE"
else
    echo -e "${GREEN}✔ Nessun errore!${RESET}"
fi

echo ""
echo -e "${YELLOW}⚠  Riavvio consigliato.${RESET}"
echo ""
