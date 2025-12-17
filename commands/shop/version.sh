#!/bin/bash

# Affichage des versions PrestaShop disponibles

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
# On doit d'abord trouver le répertoire pour charger utils.sh
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration PrestaShop
if [ -f "${SCRIPT_DIR}/config/prestashop.sh" ]; then
    source "${SCRIPT_DIR}/config/prestashop.sh"
fi

# Commande pour afficher les versions disponibles
cmd_shop_version() {
    # Afficher l'aide si demandé
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Afficher la liste des versions PrestaShop disponibles

Usage:
    ps_tool shop version

Affiche toutes les versions PrestaShop disponibles avec leur version PHP requise
au format: Prestashop X.X.X (PHP X.X)

Exemples:
    ps_tool shop version
EOF
        exit 0
    fi

    info "Versions PrestaShop disponibles :"
    echo ""
    
    # Parcourir toutes les versions et afficher avec leur version PHP
    while IFS= read -r version; do
        if [ -n "$version" ]; then
            local php_version=$(get_prestashop_php_version "$version")
            echo "  Prestashop $version (PHP $php_version)"
        fi
    done <<< "$(list_prestashop_versions)"
    
    echo ""
    info "Version par défaut: $PRESTASHOP_DEFAULT_VERSION"
}

