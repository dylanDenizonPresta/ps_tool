#!/bin/bash

# Affichage des versions disponibles de ps_accounts

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration ps_accounts
if [ -f "${SCRIPT_DIR}/config/ps_accounts.sh" ]; then
    source "${SCRIPT_DIR}/config/ps_accounts.sh"
fi

# Commande pour afficher les versions ps_accounts disponibles
cmd_account_version() {
    # Afficher l'aide si demandé
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Afficher les versions disponibles de ps_accounts

Usage:
    ps_tool account version

Options:
    --help, -h        Afficher cette aide

Exemples:
    ps_tool account version
EOF
        return 0
    fi
    
    info "Versions ps_accounts disponibles :"
    echo ""
    
    local versions=$(list_ps_accounts_versions)
    if [ -z "$versions" ]; then
        warning "Aucune version trouvée"
        return 1
    fi

    # Afficher toutes les versions disponibles
    echo "$versions" | while IFS= read -r version; do
        if [ -n "$version" ]; then
            echo "  ps_accounts $version"
        fi
    done
    echo ""
    
    info "Version par défaut: $PS_ACCOUNTS_DEFAULT_VERSION"
    echo ""
    info "Compatibilité PrestaShop:"
    echo "  - PrestaShop 9.x (9.0.0, 9.0.1, 9.0.2)"
    echo "  - PrestaShop 8.x (8.0.0 - 8.2.3)"
    echo "  - PrestaShop 1.7.x (1.7.7, 1.7.8, 1.7.8.x)"
    echo ""
    info "Environnements disponibles:"
    echo "  - PROD (production)"
    echo "  - PREPROD (préproduction)"
    echo ""
    info "Pour installer une version spécifique:"
    echo "  ps_tool account install <nom_shop> [version] [--env PROD|PREPROD]"
}

