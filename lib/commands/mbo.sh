#!/bin/bash

# Commande mbo - Gestion du module ps_mbo

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration ps_mbo
if [ -f "${SCRIPT_DIR}/config/ps_mbo.sh" ]; then
    source "${SCRIPT_DIR}/config/ps_mbo.sh"
fi

# Charger le script d'installation depuis commands/shop/mbo.sh
if [ -f "${SCRIPT_DIR}/commands/shop/mbo.sh" ]; then
    source "${SCRIPT_DIR}/commands/shop/mbo.sh"
fi

# Charger toutes les sous-commandes mbo depuis commands/mbo/
if [ -d "${SCRIPT_DIR}/commands/mbo" ]; then
    for script in "${SCRIPT_DIR}"/commands/mbo/*.sh; do
        if [ -f "$script" ]; then
            source "$script"
        fi
    done
fi

# Fonction d'aide pour la commande mbo
show_mbo_help() {
    cat << EOF
Gestion du module ps_mbo

Usage:
    ps_tool mbo <command> [options]

Commands:
    install <nom_shop> [version]    Installer le module ps_mbo dans un shop
    use <environment> <nom_shop>     Configurer l'environnement du module ps_mbo
    help                             Afficher cette aide

Exemples:
    ps_tool mbo install shop18
    ps_tool mbo install shop18 5.2.1
    ps_tool mbo use PROD shop18
    ps_tool mbo use PREPROD shop18

Pour plus d'informations sur une commande:
    ps_tool mbo <command> --help
EOF
}

# Commande principale mbo
cmd_mbo() {
    if [ $# -eq 0 ]; then
        show_mbo_help
        exit 1
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        install)
            if function_exists "cmd_shop_mbo_install"; then
                cmd_shop_mbo_install "$@"
            else
                error "La commande 'install' n'est pas disponible"
                exit 1
            fi
            ;;
        use)
            if function_exists "cmd_mbo_use"; then
                cmd_mbo_use "$@"
            else
                error "La commande 'use' n'est pas disponible"
                exit 1
            fi
            ;;
        help|--help|-h)
            show_mbo_help
            exit 0
            ;;
        *)
            error "Sous-commande inconnue: $subcommand"
            show_mbo_help
            exit 1
            ;;
    esac
}

