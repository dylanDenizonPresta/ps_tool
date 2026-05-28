#!/bin/bash

# Mise à jour de ps_tool

SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/config.sh"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"
init_script_dir 2

cmd_upgrade() {
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Mettre à jour ps_tool depuis GitHub

Usage:
    ps_tool upgrade

Options:
    --help, -h    Afficher cette aide

La commande télécharge la dernière version depuis :
    $PS_TOOL_GIT_REPO

puis réinstalle ps_tool en conservant vos données (shops, config).
EOF
        exit 0
    fi

    # Vérifier que git est disponible
    if ! command_exists git; then
        error "git n'est pas installé — impossible de mettre à jour"
        exit 1
    fi

    # Afficher la version actuelle
    info "Version actuelle : $PS_TOOL_VERSION"

    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Nettoyer le dossier temporaire à la sortie (succès ou erreur)
    trap 'rm -rf "$tmp_dir"' EXIT

    info "Téléchargement de la dernière version..."
    if ! git clone --depth=1 "$PS_TOOL_GIT_REPO" "$tmp_dir" 2>/dev/null; then
        error "Impossible de cloner le dépôt : $PS_TOOL_GIT_REPO"
        info "Vérifiez votre connexion internet"
        exit 1
    fi

    # Lire la nouvelle version
    local new_version
    new_version=$(grep -E '^PS_TOOL_VERSION=' "$tmp_dir/lib/config.sh" 2>/dev/null | cut -d'"' -f2)

    if [ -n "$new_version" ] && [ "$new_version" = "$PS_TOOL_VERSION" ]; then
        success "ps_tool est déjà à jour (version $PS_TOOL_VERSION)"
        exit 0
    fi

    if [ -n "$new_version" ]; then
        info "Mise à jour : $PS_TOOL_VERSION → $new_version"
    fi

    info "Installation..."
    if ! bash "$tmp_dir/install.sh"; then
        error "L'installation a échoué"
        exit 1
    fi

    echo ""
    success "ps_tool mis à jour avec succès !"
    if [ -n "$new_version" ]; then
        info "Nouvelle version : $new_version"
    fi
    info "Rechargez votre shell : source ~/.zshrc"
}
