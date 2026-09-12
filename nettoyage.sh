#!/usr/bin/env bash
# Script de nettoyage pour Linux (multi-distributions)
# Usage : ./nettoyage.sh | sudo ./nettoyage.sh --tout

set -euo pipefail

VERT="$'\e[1;32m'"
JAUNE="$'\e[1;33m'"
ROUGE="$'\e[1;31m'"
CYAN="$'\e[1;36m'"
RESET="$'\e[0m'"

[[ $EUID -eq 0 ]] && PRIVELEGES=1 || PRIVELEGES=0

command -v systemctl >/dev/null 2>&1 && SYSTEMD=1 || SYSTEMD=0

info()   { echo "${VERT}[INFO]${RESET} $1"; }
alerte() { echo "${JAUNE}[ATTENTION]${RESET} $1"; }
err()    { echo "${ROUGE}[ERREUR]${RESET} $1"; }
titre()  { echo; echo "${CYAN}===== $1 =====${RESET}"; }

demande() {
    local question="$1"
    local reponse
    read -rp "${JAUNE}[?]${RESET} ${question} (o/N) " reponse
    [[ "${reponse,,}" == "o" ]]
}

detecter_gestionnaire() {
    if command -v apt-get >/dev/null 2>&1; then GESTIONNAIRE="apt";
    elif command -v dnf     >/dev/null 2>&1; then GESTIONNAIRE="dnf";
    elif command -v pacman  >/dev/null 2>&1; then GESTIONNAIRE="pacman";
    elif command -v apk     >/dev/null 2>&1; then GESTIONNAIRE="apk";
    elif command -v zypper  >/dev/null 2>&1; then GESTIONNAIRE="zypper";
    else GESTIONNAIRE="inconnu"; fi
}

detecter_distro() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO="${PRETTY_NAME:-inconnue}"
    else
        DISTRO="inconnue"
    fi
    DISTRO="${DISTRO%%\"*}"
}

espace_libre() { df -Pk / | awk 'NR==2 {print $4}'; }

afficher_gain() {
    local gain="$1" texte
    if [[ "$gain" -le 0 ]]; then
        texte="0"
    elif command -v numfmt >/dev/null 2>&1; then
        texte="$(numfmt --to=iec "$gain")"
    else
        texte="${gain} Ko"
    fi
    info "Espace libéré sur / : ${texte}"
}

# ------------------------------------------------------------
# Paquets du système
nettoyer_paquets() {
    case "$GESTIONNAIRE" in
        apt)
            [[ $PRIVELEGES -eq 0 ]] && { err "apt requiert sudo."; return 1; }
            info "Nettoyage des paquets (apt)..."
            apt-get clean
            apt-get autoremove --purge -y
            rm -rf /var/lib/apt/lists/*
            apt-get update
            ;;
        dnf)
            [[ $PRIVELEGES -eq 0 ]] && { err "dnf requiert sudo."; return 1; }
            info "Nettoyage des paquets (dnf)..."
            dnf clean all
            dnf autoremove -y
            ;;
        pacman)
            [[ $PRIVELEGES -eq 0 ]] && { err "pacman requiert sudo."; return 1; }
            info "Nettoyage des paquets (pacman)..."
            command -v paccache >/dev/null 2>&1 && paccache -rk1
            local orphelins
            orphelins="$(pacman -Qtdq 2>/dev/null)" || true
            if [[ -n "$orphelins" ]]; then
                pacman -Rns --noconfirm $orphelins || true
            fi
            pacman -Scc --noconfirm
            ;;
        apk)
            [[ $PRIVELEGES -eq 0 ]] && { err "apk requiert sudo."; return 1; }
            info "Nettoyage des paquets (apk)..."
            apk cache clean 2>/dev/null || true
            ;;
        zypper)
            [[ $PRIVELEGES -eq 0 ]] && { err "zypper requiert sudo."; return 1; }
            info "Nettoyage des paquets (zypper)..."
            zypper clean --all 2>/dev/null || true
            ;;
        *)
            alerte "Gestionnaire de paquets non reconnu, étape ignorée."
            return 1
            ;;
    esac
}

# Snap : révisions désactivées
nettoyer_snap() {
    command -v snap >/dev/null 2>&1 || return 1
    [[ $PRIVELEGES -eq 0 ]] && { err "snap requiert sudo."; return 1; }
    info "Nettoyage des snaps (révisions désactivées)..."
    snap list --all | awk '/disabled/ {print $1, $3}' | while read -r sn rev; do
        snap remove "$sn" --revision "$rev" || true
    done
}

# Flatpak : runtimes inutilisés
nettoyer_flatpak() {
    command -v flatpak >/dev/null 2>&1 || return 1
    info "Nettoyage des runtimes Flatpak inutilisés..."
    flatpak uninstall --unused -y || true
}

# Docker : éléments non utilisés
nettoyer_docker() {
    command -v docker >/dev/null 2>&1 || return 1
    docker info >/dev/null 2>&1 || { alerte "Docker n'est pas lancé, étape ignorée."; return 1; }
    info "Nettoyage de Docker (images / conteneurs / cache de build inutilisés)..."
    docker system prune -af || true
}

# ------------------------------------------------------------
# Journaux système
nettoyer_journaux() {
    if [[ $SYSTEMD -eq 1 ]]; then
        [[ $PRIVELEGES -eq 0 ]] && { err "journalctl requiert sudo."; return 1; }
        info "Purge des journaux système (journalctl, plus de 7 jours)..."
        journalctl --vacuum-time=7d
    else
        [[ $PRIVELEGES -eq 0 ]] && { err "nettoyage de /var/log requiert sudo."; return 1; }
        info "Purge des journaux système (fichiers /var/log de plus de 30 jours)..."
        find /var/log -type f -name "*.log*" -mtime +30 -delete 2>/dev/null || true
    fi
}

# ------------------------------------------------------------
# Fichiers temporaires et caches utilisateur
nettoyer_temporaires() {
    info "Suppression des fichiers temporaires et caches utilisateur..."
    rm -rf "${HOME}/.cache/thumbnails/"* 2>/dev/null || true
    rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
    # Caches non consultés depuis plus de 30 jours (reconstruits à la demande)
    find "${HOME}/.cache" -type f -atime +30 -delete 2>/dev/null || true
}

# Corbeille
nettoyer_corbeille() {
    info "Vidage de la corbeille..."
    rm -rf "${HOME}/.local/share/Trash/"* 2>/dev/null || true
    # Fichiers de /tmp appartenant à l'utilisateur, inactifs depuis 7 jours
    find /tmp -user "$USER" -mtime +7 -delete 2>/dev/null || true
}

# ------------------------------------------------------------
aide() {
    cat <<'EOF'
Usage : ./nettoyage.sh [OPTION]

  (sans option)  Mode interactif : confirmation avant chaque étape
  --tout         Nettoie tout sans confirmation (sudo requis pour les étapes système)
  --aide         Affiche cette aide

Étapes proposées :
  - Paquets du système   (détection automatique : apt / dnf / pacman / apk / zypper)
  - Snap       (révisions désactivées)     si snap est installé
  - Flatpak    (runtimes inutilisés)       si flatpak est installé
  - Docker     (images / cache de build)   si docker est lancé
  - Journaux système     (journalctl > 7 jours, ou logs /var/log > 30 jours)
  - Fichiers temporaires et caches utilisateur
  - Corbeille

L'espace disque est mesuré avant / après, le gain est affiché à la fin.
EOF
}

# ------------------------------------------------------------
main() {
    titre "Nettoyage du système — ${DISTRO} (paquets : ${GESTIONNAIRE})"
    local ESPACE_AVANT ESPACE_APRES GAIN
    ESPACE_AVANT="$(espace_libre)"

    if demande "Nettoyer les paquets du système (${GESTIONNAIRE}) ?"; then
        nettoyer_paquets || true
    fi
    if command -v snap >/dev/null 2>&1 && demande "Nettoyer les snaps inutilisés ?"; then
        nettoyer_snap || true
    fi
    if command -v flatpak >/dev/null 2>&1 && demande "Nettoyer les runtimes Flatpak inutilisés ?"; then
        nettoyer_flatpak || true
    fi
    if command -v docker >/dev/null 2>&1 && demande "Nettoyer Docker (système) ?"; then
        nettoyer_docker || true
    fi
    if demande "Purger les journaux système ?"; then
        nettoyer_journaux || true
    fi
    if demande "Supprimer les fichiers temporaires et caches ?"; then
        nettoyer_temporaires
    fi
    if demande "Vider la corbeille ?"; then
        nettoyer_corbeille
    fi

    ESPACE_APRES="$(espace_libre)"
    GAIN=$((ESPACE_APRES - ESPACE_AVANT))
    afficher_gain "$GAIN"
    info "Nettoyage terminé."
}

# ------------------------------------------------------------
detecter_distro
detecter_gestionnaire

case "${1:-}" in
    --aide|-h|--help)
        aide
        ;;
    --tout)
        local ESPACE_AVANT ESPACE_APRES GAIN
        ESPACE_AVANT="$(espace_libre)"
        nettoyer_paquets          || true
        nettoyer_snap             || true
        nettoyer_flatpak          || true
        nettoyer_docker           || true
        nettoyer_journaux         || true
        nettoyer_temporaires
        nettoyer_corbeille
        ESPACE_APRES="$(espace_libre)"
        GAIN=$((ESPACE_APRES - ESPACE_AVANT))
        afficher_gain "$GAIN"
        info "Nettoyage terminé."
        ;;
    "")
        main
        ;;
    *)
        alerte "Option inconnue : $1"
        aide
        exit 1
        ;;
esac