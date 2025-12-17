#!/bin/bash

# Liste des shops PrestaShop créés

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
# On doit d'abord trouver le répertoire pour charger utils.sh
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Commande pour lister les shops
cmd_shop_list() {
    # Afficher l'aide si demandé
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Lister tous les shops PrestaShop créés avec ps_tool

Usage:
    ps_tool shop list [options]

Options:
    --help, -h          Afficher cette aide

La commande lit le registre des shops créés avec ps_tool shop install
et affiche un tableau avec le nom, la version PrestaShop et le chemin.

Exemples:
    ps_tool shop list
EOF
        exit 0
    fi

    # Charger la configuration pour obtenir le chemin du registre
    if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
        source "${SCRIPT_DIR}/lib/config.sh"
    fi

    # Utiliser la fonction read_shops_registry
    # La fonction affiche le tableau avec le chemin et définit _SHOP_COUNT
    read_shops_registry
    
    # Récupérer le nombre de shops depuis la variable globale
    local shop_count="${_SHOP_COUNT:-0}"

    echo ""
    if [ -z "$shop_count" ] || [ "$shop_count" -eq 0 ]; then
        warning "Aucun shop PrestaShop trouvé"
        info "Créez un shop avec: ps_tool shop install <nom_shop>"
    else
        success "$shop_count shop(s) trouvé(s)"
    fi
}

