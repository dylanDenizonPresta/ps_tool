#!/bin/bash

# Affichage des versions disponibles de ps_mbo

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration ps_mbo
if [ -f "${SCRIPT_DIR}/config/ps_mbo.sh" ]; then
    source "${SCRIPT_DIR}/config/ps_mbo.sh"
fi

# Commande principale pour afficher les versions disponibles
cmd_mbo_version() {
    # Afficher l'aide si demandé
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Afficher la liste des versions de ps_mbo disponibles

Usage:
    ps_tool mbo version

Affiche toutes les versions de ps_mbo disponibles avec leur compatibilité PrestaShop

Exemples:
    ps_tool mbo version
EOF
        exit 0
    fi
    
    info "Versions ps_mbo disponibles :"
    echo ""
    
    # Obtenir toutes les versions depuis la fonction list_ps_mbo_versions
    local versions=$(list_ps_mbo_versions)
    
    if [ -z "$versions" ]; then
        warning "Aucune version trouvée"
        return 1
    fi
    
    # Grouper par version majeure pour un affichage plus lisible
    echo "Versions 5.x (PrestaShop 9.x):"
    echo "$versions" | grep "^5\." | while IFS= read -r version; do
        if [ -n "$version" ]; then
            echo "  ps_mbo $version"
        fi
    done
    echo ""
    
    echo "Versions 4.x (PrestaShop 8.x):"
    echo "$versions" | grep "^4\." | while IFS= read -r version; do
        if [ -n "$version" ]; then
            echo "  ps_mbo $version"
        fi
    done
    echo ""
    
    echo "Versions 3.x (PrestaShop 1.7.x):"
    echo "$versions" | grep "^3\." | while IFS= read -r version; do
        if [ -n "$version" ]; then
            echo "  ps_mbo $version"
        fi
    done
    echo ""
    
    info "Version par défaut: $PS_MBO_DEFAULT_VERSION"
    echo ""
    info "Pour installer une version spécifique:"
    echo "  ps_tool mbo install <nom_shop> <version>"
}




