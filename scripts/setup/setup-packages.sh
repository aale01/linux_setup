#!/usr/bin/env bash
# ==============================================================================
# setup.sh — Installazione pacchetti Ubuntu da packages.yaml
# Uso: sudo bash setup.sh [packages.yaml]
# ==============================================================================

# set -euo pipefail

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

[[ $EUID -eq 0 ]] || { error "Esegui con sudo"; exit 1; }

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
[[ -f "$PACKAGES_FILE" ]] || { error "File non trovato"; exit 1; }

safe_apt_update() {
    if ! apt-get update -qq; then
        warn "apt update fallito, continuo ignorando repo rotti"
        return 1
    fi
}

# ==============================================================================
# STEP 1 — yq
# ==============================================================================
section "STEP 1 — yq"

if ! command -v yq &>/dev/null; then
    YQ_VERSION=$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')

    curl -fsSL \
      "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
      -o /usr/local/bin/yq

    chmod +x /usr/local/bin/yq
fi

ok "yq pronto"

# ==============================================================================
# STEP 2 — APT update UNA VOLTA
# ==============================================================================
section "STEP 2 — APT update"
if ! safe_apt_update; then
    warn "Continuo in modalità degraded"
fi
apt-get upgrade -y
ok "Sistema aggiornato"

# ==============================================================================
# STEP 3 — Pacchetti APT
# ==============================================================================
section "STEP 3 — APT packages"

mapfile -t APT_GROUPS < <(yq '.apt | keys | .[]' "$PACKAGES_FILE")

for group in "${APT_GROUPS[@]}"; do
    log "Gruppo: $group"

    mapfile -t pkgs < <(yq ".apt.${group}[]" "$PACKAGES_FILE")

    for pkg in "${pkgs[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            warn "$pkg già installato"
        else
            if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
                ok "$pkg"
                ((INSTALLED_COUNT++))
            else
                error "$pkg fallito"
                FAILED_PKGS+=("$pkg")
            fi
        fi
    done
done

# ==============================================================================
# STEP 4 — External repos generici
# ==============================================================================
section "STEP 4 — External repos"

setup_external_repo() {
    local repo="$1"
    local version="$2"

    case "$repo" in
        nodesource)
	    if [[ -z "$version" ]]; then
		error "Version mancante per nodesource"
		return 1
	    fi

	    curl -fsSL "https://deb.nodesource.com/setup_${version}.x" | bash -
	    ;;
	    
	github-cli)
	    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
		| dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg

	    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

	    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
		> /etc/apt/sources.list.d/github-cli.list
	    ;;

        docker)
            : # futuro
            ;;
            
        spotify)
            warn "Spotify disabled automatically for system stability"
	    SKIP_APT_UPDATE_CHECK=1
	    return 0
	    ;;

        *)
            warn "Repo sconosciuto: $repo"
            return 1
            ;;
    esac
}

install_packages() {
    local packages=("$@")

    for pkg in "${packages[@]}"; do
        if ! apt-cache show "$pkg" &>/dev/null; then
            error "$pkg non disponibile"
            FAILED_PKGS+=("$pkg")
            continue
        fi

        if dpkg -s "$pkg" &>/dev/null; then
            warn "$pkg già installato"
            continue
        fi

        if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
            ok "$pkg installato"
            ((INSTALLED_COUNT++))
        else
            error "$pkg fallito"
            FAILED_PKGS+=("$pkg")
        fi
    done
}

mapfile -t EXTERNAL_KEYS < <(
    yq -r '.external[] | select(.enabled != false) | .id' "$PACKAGES_FILE"
)

for key in "${EXTERNAL_KEYS[@]}"; do

    [[ -z "$key" || "$key" == "null" ]] && continue

    section "Repo: $key"

    VERSION=$(yq -r ".external[] | select(.id == \"$key\") | .version // \"\"" "$PACKAGES_FILE")

    setup_external_repo "$key" "$VERSION" || {
        warn "Skip repo fallito: $key"
        continue
    }
done

if ! safe_apt_update; then
    warn "Continuo in modalità degraded"
fi

section "INSTALL EXTERNAL PACKAGES"

for key in "${EXTERNAL_KEYS[@]}"; do

    mapfile -t PKGS < <(
        yq -r ".external[] | select(.id == \"$key\") | .packages[]?" "$PACKAGES_FILE"
    )

    [[ ${#PKGS[@]} -eq 0 ]] && continue

    install_packages "${PKGS[@]}"

done

# ==============================================================================
# STEP 5 — GitHub Releases
# ==============================================================================
section "STEP 5 — GitHub Releases"

mapfile -t ITEMS < <(yq -r '.github_releases[]?.name' "$PACKAGES_FILE")

for i in "${!ITEMS[@]}"; do

    name=$(yq -r ".github_releases[$i].name" "$PACKAGES_FILE")
    repo=$(yq -r ".github_releases[$i].repo" "$PACKAGES_FILE")
    binary=$(yq -r ".github_releases[$i].binary" "$PACKAGES_FILE")
    asset_template=$(yq -r ".github_releases[$i].asset" "$PACKAGES_FILE")

    if command -v "$binary" &>/dev/null; then
        warn "$name già installato"
        continue
    fi

    version=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')

    asset="${asset_template/\{version\}/$version}"
    url="https://github.com/${repo}/releases/download/v${version}/${asset}"

    tmp=$(mktemp -d)

    if curl -fsSL "$url" -o "$tmp/$asset"; then
        tar -xzf "$tmp/$asset" -C "$tmp"
	
	FOUND=$(find "$tmp" -type f -name "$binary" | head -n 1)

	if [[ -z "$FOUND" ]]; then
	    error "$name binary non trovato"
	    FAILED_PKGS+=("$name")
	    rm -rf "$tmp"
	    continue
	fi

	install -m 755 "$FOUND" "/usr/local/bin/$binary"
        ok "$name installato"
        ((INSTALLED_COUNT++))
    else
        error "Errore $name"
        FAILED_PKGS+=("$name")
    fi
    
    rm -rf "$tmp"
done

# ==============================================================================
# STEP 6 — Groups
# ==============================================================================
section "STEP 6 — Groups"

mapfile -t GROUPS < <(yq '.groups[]?' "$PACKAGES_FILE")

for grp in "${GROUPS[@]}"; do
    if getent group "$grp" &>/dev/null; then
        usermod -aG "$grp" "$REAL_USER" || true
        ok "$REAL_USER -> $grp"
    fi
done

# ==============================================================================
# STEP 7 — Pulizia
# ==============================================================================
section "STEP 7 — Pulizia"
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
