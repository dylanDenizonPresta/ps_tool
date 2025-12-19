#!/bin/bash

# Commande shop - Gestion des shops PrestaShop

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

# Charger toutes les sous-commandes shop depuis commands/shop/
if [ -d "${SCRIPT_DIR}/commands/shop" ]; then
    for script in "${SCRIPT_DIR}"/commands/shop/*.sh; do
        if [ -f "$script" ]; then
            source "$script"
        fi
    done
fi

# Fonction d'aide pour la commande shop
show_shop_help() {
    cat << EOF
Gestion des shops PrestaShop

Usage:
    ps_tool shop <command> [options]

Commands:
    install, -i <nom_shop> [version]    Installer une shop PrestaShop
    list                                 Lister tous les shops créés
    start <nom_shop>                     Démarrer un shop PrestaShop
    stop <nom_shop>                      Arrêter un shop PrestaShop
    remove <nom_shop> [options]          Supprimer un shop PrestaShop
    clean <nom_shop> [options]           Nettoyer le cache et fichiers temporaires
    version, -v                          Afficher les versions PrestaShop disponibles
    help, -h                             Afficher cette aide

Exemples:
    ps_tool shop install shop18
    ps_tool shop -i shop18
    ps_tool shop install shop18 9.0.2
    ps_tool shop -i shop18 9.0.2
    ps_tool shop list
    ps_tool shop start shop18
    ps_tool shop stop shop18
    ps_tool shop remove shop18
    ps_tool shop remove shop18 --files
    ps_tool shop clean shop18
    ps_tool shop clean shop18 --cache-only

Pour plus d'informations sur une commande:
    ps_tool shop <command> --help
EOF
}

# Commande principale shop
cmd_shop() {
    if [ $# -eq 0 ]; then
        show_shop_help
        exit 1
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        install|-i)
            if function_exists "cmd_shop_install"; then
                cmd_shop_install "$@"
            else
                error "La commande 'install' n'est pas disponible"
                exit 1
            fi
            ;;
        list)
            if function_exists "cmd_shop_list"; then
                cmd_shop_list "$@"
            else
                error "La commande 'list' n'est pas disponible"
                exit 1
            fi
            ;;
        start)
            if function_exists "cmd_shop_start"; then
                cmd_shop_start "$@"
            else
                error "La commande 'start' n'est pas disponible"
                exit 1
            fi
            ;;
        stop)
            if function_exists "cmd_shop_stop"; then
                cmd_shop_stop "$@"
            else
                error "La commande 'stop' n'est pas disponible"
                exit 1
            fi
            ;;
        remove)
            if function_exists "cmd_shop_remove"; then
                cmd_shop_remove "$@"
            else
                error "La commande 'remove' n'est pas disponible"
                exit 1
            fi
            ;;
        version|-v)
            if function_exists "cmd_shop_version"; then
                cmd_shop_version "$@"
            else
                error "La commande 'version' n'est pas disponible"
                exit 1
            fi
            ;;
        clean)
            if function_exists "cmd_shop_clean"; then
                cmd_shop_clean "$@"
            else
                error "La commande 'clean' n'est pas disponible"
                exit 1
            fi
            ;;
        help|--help|-h)
            show_shop_help
            exit 0
            ;;
        *)
            error "Sous-commande inconnue: $subcommand"
            show_shop_help
            exit 1
            ;;
    esac
}

