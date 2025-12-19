#!/bin/bash

# Commande account - Gestion du module ps_accounts

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration ps_accounts
if [ -f "${SCRIPT_DIR}/config/ps_accounts.sh" ]; then
    source "${SCRIPT_DIR}/config/ps_accounts.sh"
fi

# Charger toutes les sous-commandes account depuis commands/account/
if [ -d "${SCRIPT_DIR}/commands/account" ]; then
    for script in "${SCRIPT_DIR}"/commands/account/*.sh; do
        if [ -f "$script" ]; then
            source "$script"
        fi
    done
fi

# Fonction d'aide pour la commande account
show_account_help() {
    cat << EOF
Gestion du module ps_accounts

Usage:
    ps_tool account <command> [options]

Commands:
    install, -i <nom_shop> [version] [options]    Installer le module ps_accounts dans un shop
    uninstall <nom_shop> [options]                Désinstaller le module ps_accounts d'un shop
    reset <nom_shop>                              Réinitialiser les données de configuration ps_accounts
    version, -v                                     Afficher les versions disponibles de ps_accounts
    help, -h                                       Afficher cette aide

Exemples:
    ps_tool account install shop18
    ps_tool account -i shop18
    ps_tool account install shop18 8.0.8
    ps_tool account -i shop18 8.0.8
    ps_tool account install shop18 --env PREPROD
    ps_tool account -i shop18 --env PREPROD
    ps_tool account uninstall shop18
    ps_tool account uninstall shop18 --files
    ps_tool account reset shop18
    ps_tool account version
    ps_tool account -v

Pour plus d'informations sur une commande:
    ps_tool account <command> --help
EOF
}

# Commande principale account
cmd_account() {
    if [ $# -eq 0 ]; then
        show_account_help
        exit 1
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        install|-i)
            if function_exists "cmd_account_install"; then
                cmd_account_install "$@"
            else
                error "La commande 'install' n'est pas disponible"
                exit 1
            fi
            ;;
        uninstall)
            if function_exists "cmd_account_uninstall"; then
                cmd_account_uninstall "$@"
            else
                error "La commande 'uninstall' n'est pas disponible"
                exit 1
            fi
            ;;
        reset)
            if function_exists "cmd_account_reset"; then
                cmd_account_reset "$@"
            else
                error "La commande 'reset' n'est pas disponible"
                exit 1
            fi
            ;;
        version|-v)
            if function_exists "cmd_account_version"; then
                cmd_account_version "$@"
            else
                error "La commande 'version' n'est pas disponible"
                exit 1
            fi
            ;;
        help|--help|-h)
            show_account_help
            exit 0
            ;;
        *)
            error "Sous-commande inconnue: $subcommand"
            show_account_help
            exit 1
            ;;
    esac
}

