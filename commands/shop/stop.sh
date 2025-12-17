#!/bin/bash

# Arrêter un shop PrestaShop

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
# On doit d'abord trouver le répertoire pour charger utils.sh
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration
if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
    source "${SCRIPT_DIR}/lib/config.sh"
fi

# Commande pour arrêter un shop
cmd_shop_stop() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Arrêter un shop PrestaShop avec ddev

Usage:
    ps_tool shop stop <nom_shop>

Arguments:
    nom_shop          Nom du shop à arrêter

Exemples:
    ps_tool shop stop shop18
    ps_tool shop stop shop19

La commande va arrêter l'environnement ddev du shop spécifié.
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            exit 0
        else
            exit 1
        fi
    fi

    local shop_name="$1"
    
    # Valider le shop (vérifie ddev, existence, répertoire, config)
    if ! validate_shop "$shop_name"; then
        exit 1
    fi
    
    local shop_path="$_SHOP_PATH"
    
    # Se déplacer dans le répertoire du shop et arrêter ddev
    info "Arrêt du shop: $shop_name"
    info "Répertoire: $shop_path"
    
    if (cd "$shop_path" && ddev stop); then
        success "Shop $shop_name arrêté avec succès"
    else
        error "Échec de l'arrêt du shop: $shop_name"
        exit 1
    fi
}

