#!/usr/bin/env bash
# Script de nettoyage pour Linux (Debian/Ubuntu)
# Usage : ./nettoyage.sh  ou  sudo ./nettoyage.sh --tout

set -euo pipefail

COULEUR_VERTE=$'\e[1;32m'
COULEUR_ROUGE=$'\e[1;31m'
COULEUR_JAUNE=$'\e[1;33m'
COULEUR_RESET=$'\e[0m'

[[ $EUID -eq 0 ]] && PRIVELEGES=1 || PRIVELEGES=0

info()  { echo "${COULEUR_VERTE}[INFO]${COULEUR_RESET} $1"; }
alerte(){ echo "${COULEUR_JAUNE}[ATTENTION]${COULEUR_RESET} $1"; }
err()   { echo "${COULEUR_ROUGE}[ERREUR]${COULEUR_RESET} $1"; }

demande() {
    local question="$1"
    local reponse
    read -rp "${COULEUR_JAUNE}[?]${COULEUR_RESET} ${question} (o/N) " reponse
    [[ "${reponse,,}" == "o" ]]
}

# ------------------------------------------------------------
nettoyer_apt() {
    [[ $PRIVELEGES -eq 0 ]] && { err "apt requiert sudo. Relancez avec sudo."; return 1; }
    info "Nettoyage des paquets apt..."
    apt-get clean
    apt-get autoremove --purge -y
    rm -rf /var/lib/apt/lists/*
    apt-get update
}

nettoyer_journaux() {
    [[ $PRIVELEGES -eq 0 ]] && { err "journalctl requiert sudo." ; return 1; }
    info "Nettoyage des journaux système (journalctl)..."
    journalctl --vacuum-time=7d
}

nettoyer_fichiers_temporaires() {
    info "Suppression des fichiers temporaires utilisateurs..."
    rm -rf "${HOME}/.cache/thumbnails/"*
    rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
    # Vide les données mises en cache (mettront un peu de temps à se reconstruire)
    find "${HOME}/.cache" -type f -atime +30 -delete 2>/dev/null || true
}

nettoyer_corbeille() {
    info "Vidage de la corbeille..."
    rm -rf "${HOME}/.local/share/Trash/"* 2>/dev/null || true
    find /tmp -user "$USER" -delete 2>/dev/null || true
}

# ------------------------------------------------------------
main() {
    echo "${COULEUR_VERTE}===== Nettoyage du système =====${COULEUR_RESET}"

    if demande "Nettoyer les paquets apt (apt clean / autoremove) ?"; then
        nettoyer_apt || true
    fi

    if demande "Purger les journaux système de plus de 7 jours ?"; then
        nettoyer_journaux || true
    fi

    if demande "Supprimer les fichiers temporaires et caches ?"; then
        nettoyer_fichiers_temporaires
    fi

    if demande "Vider la corbeille ?"; then
        nettoyer_corbeille
    fi

    info "Nettoyage terminé."
}

# Mode silencieux / automatique : ./nettoyage.sh --tout
if [[ "${1:-}" == "--tout" ]]; then
    nettoyer_apt        && info "apt nettoyé"
    nettoyer_journaux   && info "journaux purgés"
    nettoyer_fichiers_temporaires
    nettoyer_corbeille
    info "Nettoyage complet terminé."
    exit 0
fi

main