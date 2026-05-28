#!/bin/bash

# Démarrer un shop PrestaShop

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

# Commande pour démarrer un shop
cmd_shop_start() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Démarrer un shop PrestaShop avec ddev

Usage:
    ps_tool shop start <nom_shop>
    ps_tool shop start --all

Arguments:
    nom_shop          Nom du shop à démarrer

Options:
    --all             Démarrer tous les shops du registre
    --help, -h        Afficher cette aide

Exemples:
    ps_tool shop start shop18
    ps_tool shop start --all
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            exit 0
        else
            exit 1
        fi
    fi

    # Mode --all : démarrer tous les shops du registre
    if [ "$1" = "--all" ]; then
        if [ ! -f "$PS_TOOL_SHOPS_REGISTRY" ]; then
            warning "Aucun shop trouvé dans le registre"
            exit 0
        fi

        local started=0 failed=0
        while IFS='|' read -r shop_name shop_path _rest; do
            { [ -z "$shop_name" ] || [ ! -d "$shop_path" ]; } && continue
            info "Démarrage de '$shop_name'..."
            if (cd "$shop_path" && ddev start 2>/dev/null); then
                success "  ✓ $shop_name démarré"
                started=$((started + 1))
            else
                warning "  ✗ $shop_name — échec"
                failed=$((failed + 1))
            fi
        done < "$PS_TOOL_SHOPS_REGISTRY"

        echo ""
        [ $started -gt 0 ] && success "$started shop(s) démarré(s)"
        [ $failed  -gt 0 ] && warning "$failed shop(s) en échec"
        exit 0
    fi

    local shop_name="$1"

    # Valider le shop (vérifie ddev, existence, répertoire, config)
    if ! validate_shop "$shop_name"; then
        exit 1
    fi

    local shop_path="$_SHOP_PATH"

    info "Démarrage du shop: $shop_name"
    if (cd "$shop_path" && ddev start); then
        success "Shop $shop_name démarré avec succès"
        info "Accédez au shop avec: ps_tool shop open $shop_name"
    else
        error "Échec du démarrage du shop: $shop_name"
        exit 1
    fi
}

