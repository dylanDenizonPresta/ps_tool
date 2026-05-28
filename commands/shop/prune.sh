#!/bin/bash

# Nettoyage du registre des shops (suppression des entrées orphelines)

SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"
init_script_dir 2

if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
    source "${SCRIPT_DIR}/lib/config.sh"
fi

cmd_shop_prune() {
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Nettoyer le registre des shops

Usage:
    ps_tool shop prune [options]

Options:
    --dry-run     Afficher ce qui serait supprimé sans rien modifier
    --help, -h    Afficher cette aide

Supprime du registre les entrées dont le répertoire n'existe plus.
Les shops toujours présents sur le disque ne sont pas affectés.

Exemples:
    ps_tool shop prune
    ps_tool shop prune --dry-run
EOF
        exit 0
    fi

    local dry_run=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run) dry_run=true ;;
            *) warning "Option inconnue: $1" ;;
        esac
        shift
    done

    if [ -z "$PS_TOOL_SHOPS_REGISTRY" ]; then
        PS_TOOL_SHOPS_REGISTRY="${HOME}/.ps_tool/shops.txt"
    fi

    if [ ! -f "$PS_TOOL_SHOPS_REGISTRY" ]; then
        info "Le registre est vide, rien à nettoyer"
        exit 0
    fi

    local orphans=()
    local valid=()

    while IFS='|' read -r shop_name shop_path rest; do
        [ -z "$shop_name" ] && continue
        if [ ! -d "$shop_path" ]; then
            orphans+=("$shop_name|$shop_path")
        else
            valid+=("${shop_name}|${shop_path}|${rest}")
        fi
    done < "$PS_TOOL_SHOPS_REGISTRY"

    if [ ${#orphans[@]} -eq 0 ]; then
        success "Registre propre — aucune entrée orpheline trouvée"
        exit 0
    fi

    echo ""
    warning "${#orphans[@]} entrée(s) orpheline(s) détectée(s) :"
    for entry in "${orphans[@]}"; do
        local name path
        name=$(echo "$entry" | cut -d'|' -f1)
        path=$(echo "$entry" | cut -d'|' -f2)
        echo "  ✗ $name  ($path)"
    done
    echo ""

    if [ "$dry_run" = true ]; then
        info "Mode dry-run : aucune modification effectuée"
        exit 0
    fi

    # Réécrire le registre sans les orphelins
    local temp_file
    temp_file=$(mktemp)

    for entry in "${valid[@]}"; do
        echo "$entry" >> "$temp_file"
    done

    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$PS_TOOL_SHOPS_REGISTRY"
    else
        rm -f "$temp_file" "$PS_TOOL_SHOPS_REGISTRY"
    fi

    success "${#orphans[@]} entrée(s) supprimée(s) du registre"
    [ ${#valid[@]} -gt 0 ] && info "${#valid[@]} shop(s) conservé(s)"
}
