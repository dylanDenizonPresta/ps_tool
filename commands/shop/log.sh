#!/bin/bash

# Afficher les logs d'un shop PrestaShop

SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"
init_script_dir 2

if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
    source "${SCRIPT_DIR}/lib/config.sh"
fi

cmd_shop_log() {
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Afficher les logs d'un shop PrestaShop

Usage:
    ps_tool shop log <nom_shop> [options]

Arguments:
    nom_shop          Nom du shop

Options:
    --follow, -f      Suivre les logs en temps réel (tail -f)
    --web             Logs du service web uniquement
    --db              Logs de la base de données uniquement
    --help, -h        Afficher cette aide

Exemples:
    ps_tool shop log shop9
    ps_tool shop log shop9 --follow
    ps_tool shop log shop9 --web --follow
    ps_tool shop log shop9 --db
EOF
        exit 0
    fi

    if [ $# -eq 0 ]; then
        error "Nom du shop requis"
        info "Usage: ps_tool shop log <nom_shop> [--follow] [--web|--db]"
        exit 1
    fi

    local shop_name="$1"
    shift

    local follow=false
    local service=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --follow|-f) follow=true ;;
            --web)       service="web" ;;
            --db)        service="db" ;;
            *) warning "Option inconnue: $1" ;;
        esac
        shift
    done

    if ! validate_shop "$shop_name"; then
        exit 1
    fi
    local shop_path="$_SHOP_PATH"

    # Construire la commande ddev logs
    local ddev_args=("ddev" "logs")
    [ -n "$service" ]    && ddev_args+=("-s" "$service")
    [ "$follow" = true ] && ddev_args+=("-f")

    info "Logs de '$shop_name'${service:+ (service: $service)}${follow:+ — Ctrl+C pour quitter}"
    echo ""

    (cd "$shop_path" && "${ddev_args[@]}")
}
