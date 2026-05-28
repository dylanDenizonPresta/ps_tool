#!/bin/bash

# Ouvrir un shop PrestaShop dans le navigateur

SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"
init_script_dir 2

if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
    source "${SCRIPT_DIR}/lib/config.sh"
fi

cmd_shop_open() {
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Ouvrir un shop PrestaShop dans le navigateur

Usage:
    ps_tool shop open <nom_shop> [options]

Arguments:
    nom_shop          Nom du shop à ouvrir

Options:
    --admin, -a       Ouvrir le back-office directement
    --help, -h        Afficher cette aide

Exemples:
    ps_tool shop open shop9
    ps_tool shop open shop9 --admin
EOF
        exit 0
    fi

    if [ $# -eq 0 ]; then
        error "Nom du shop requis"
        info "Usage: ps_tool shop open <nom_shop>"
        exit 1
    fi

    local shop_name="$1"
    shift

    local open_admin=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --admin|-a) open_admin=true ;;
            *) warning "Option inconnue: $1" ;;
        esac
        shift
    done

    # Récupérer les infos du registre
    local shop_path
    shop_path=$(get_shop_path "$shop_name")
    if [ -z "$shop_path" ] || [ ! -d "$shop_path" ]; then
        error "Shop non trouvé: $shop_name"
        info "Listez les shops avec: ps_tool shop list"
        exit 1
    fi

    # Construire l'URL depuis les ports du registre
    local registry_ports
    registry_ports=$(get_shop_ports_from_registry "$shop_name")
    local https_port
    https_port=$(echo "$registry_ports" | cut -d'|' -f2)
    local http_port
    http_port=$(echo "$registry_ports" | cut -d'|' -f1)

    local base_url
    if [ -n "$https_port" ] && [[ "$https_port" =~ ^[0-9]+$ ]]; then
        if [ "$https_port" = "443" ]; then
            base_url="https://${shop_name}.ddev.site"
        else
            base_url="https://${shop_name}.ddev.site:${https_port}"
        fi
    elif [ -n "$http_port" ] && [[ "$http_port" =~ ^[0-9]+$ ]]; then
        if [ "$http_port" = "80" ]; then
            base_url="http://${shop_name}.ddev.site"
        else
            base_url="http://${shop_name}.ddev.site:${http_port}"
        fi
    else
        error "Impossible de déterminer l'URL du shop (ports manquants dans le registre)"
        exit 1
    fi

    local url="$base_url"
    if [ "$open_admin" = true ]; then
        # Détecter le vrai dossier admin (renommé par PS pour la sécurité, ex: admin4k2p9x)
        # PS 9+ place les fichiers dans public/, PS 8.x et antérieur à la racine
        local admin_folder=""
        for search_path in "$shop_path/public" "$shop_path"; do
            if [ -d "$search_path" ]; then
                # Cherche un dossier admin* contenant index.php (exclut admin-api, etc.)
                local found
                found=$(find "$search_path" -maxdepth 1 -type d -name "admin*" 2>/dev/null \
                    | grep -v -- '-' \
                    | while IFS= read -r dir; do
                        [ -f "$dir/index.php" ] && echo "$dir" && break
                    done)
                if [ -n "$found" ]; then
                    admin_folder=$(basename "$found")
                    break
                fi
            fi
        done

        if [ -z "$admin_folder" ]; then
            warning "Dossier admin introuvable dans $shop_path"
            info "Ouverture de la page d'accueil à la place"
        else
            url="${base_url}/${admin_folder}"
            info "Dossier admin détecté : $admin_folder"
        fi
    fi

    # Vérifier que le shop est démarré
    local ddev_list_output
    ddev_list_output=$(ddev list 2>/dev/null)
    if ! echo "$ddev_list_output" | grep " ${shop_name} " | grep -qiE "(running|ok)"; then
        warning "Le shop '$shop_name' semble arrêté"
        if ! confirm "Voulez-vous l'ouvrir quand même ?"; then
            info "Démarrez d'abord le shop avec: ps_tool shop start $shop_name"
            exit 0
        fi
    fi

    info "Ouverture de: $url"
    if command_exists open; then
        open "$url"
    elif command_exists xdg-open; then
        xdg-open "$url"
    else
        error "Impossible d'ouvrir le navigateur automatiquement"
        info "URL: $url"
        exit 1
    fi

    success "Shop '$shop_name' ouvert dans le navigateur"
}
