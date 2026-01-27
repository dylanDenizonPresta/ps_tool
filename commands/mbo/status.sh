#!/bin/bash

# Affichage du statut de la configuration ps_mbo

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger les fonctions de gestion des shops
if [ -f "${SCRIPT_DIR}/lib/utils/shops.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/shops.sh"
fi

# Fonction pour trouver le fichier .env dans le module ps_mbo
# Usage: _find_env_file <shop_path>
# Retourne le chemin du fichier .env ou vide si non trouvé
_find_env_file() {
    local shop_path="$1"
    local mbo_module_path="${shop_path}/modules/ps_mbo"
    
    # Chercher dans cet ordre : .env, .env.local, .env.dist
    for env_file in ".env" ".env.local" ".env.dist"; do
        local env_path="${mbo_module_path}/${env_file}"
        if [ -f "$env_path" ]; then
            echo "$env_path"
            return 0
        fi
    done
    
    return 1
}

# Fonction pour lire une variable depuis le fichier .env
# Usage: _read_env_var <env_file> <var_name>
_read_env_var() {
    local env_file="$1"
    local var_name="$2"
    
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    
    # Chercher la variable dans le fichier .env
    local value=$(grep -E "^${var_name}=" "$env_file" 2>/dev/null | head -1 | sed "s|^${var_name}=\"\(.*\)\"|\1|" | sed "s|^${var_name}=\(.*\)|\1|")
    echo "$value"
}

# Fonction pour déterminer l'environnement depuis les URLs
# Usage: _detect_environment <cdc_url> <api_url> <addons_url>
_detect_environment() {
    local cdc_url="$1"
    local api_url="$2"
    local addons_url="$3"
    
    # Détecter l'environnement MBO
    local mbo_env=""
    if echo "$cdc_url" | grep -qi "localhost"; then
        mbo_env="LOCAL"
    elif echo "$cdc_url" | grep -qi "prestabulle"; then
        local num=$(echo "$cdc_url" | grep -oE "prestabulle[0-9]+" | grep -oE "[0-9]+" | head -1)
        if [ -n "$num" ]; then
            mbo_env="PRESTABULLE${num}"
        else
            mbo_env="PRESTABULLE"
        fi
    elif echo "$cdc_url" | grep -qi "preprod"; then
        mbo_env="PREPROD"
    elif echo "$cdc_url" | grep -qi "assets.prestashop3.com"; then
        mbo_env="PROD"
    else
        mbo_env="INCONNU"
    fi
    
    # Détecter l'environnement Addons
    local addons_env=""
    if echo "$addons_url" | grep -qi "localhost\|local"; then
        addons_env="LOCAL"
    elif echo "$addons_url" | grep -qi "pod"; then
        local num=$(echo "$addons_url" | grep -oE "pod[0-9]+" | grep -oE "[0-9]+" | head -1)
        if [ -n "$num" ]; then
            addons_env="POD${num}"
        else
            addons_env="POD"
        fi
    elif echo "$addons_url" | grep -qi "preprod"; then
        addons_env="PREPROD"
    elif echo "$addons_url" | grep -qi "api-addons.prestashop.com"; then
        addons_env="PROD"
    else
        addons_env="INCONNU"
    fi
    
    echo "${mbo_env}|${addons_env}"
}

# Commande principale pour afficher le statut de ps_mbo
cmd_mbo_status() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Affichage du statut de la configuration ps_mbo

Usage:
    ps_tool mbo status <nom_shop>

Arguments:
    nom_shop           Nom de la shop où vérifier la configuration ps_mbo

Options:
    --help, -h        Afficher cette aide

Exemples:
    ps_tool mbo status shop18

La commande affiche:
    - L'environnement MBO configuré
    - L'environnement Addons configuré
    - Les URLs de configuration (CDC, API, Addons)
    - L'état Sentry (si configuré)
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    local shop_name="$1"
    
    # Valider le shop
    if ! validate_shop "$shop_name"; then
        return 1
    fi
    
    local shop_path="$_SHOP_PATH"
    
    info "Statut de la configuration ps_mbo pour le shop: $shop_name"
    info "Chemin du shop: $shop_path"
    echo ""
    
    # Vérifier que le module ps_mbo est installé
    local mbo_module_path="${shop_path}/modules/ps_mbo"
    if [ ! -d "$mbo_module_path" ]; then
        error "Le module ps_mbo n'est pas installé dans ce shop"
        info "Installez-le d'abord avec: ps_tool mbo install $shop_name"
        return 1
    fi
    
    # Trouver le fichier .env
    local env_file
    env_file=$(_find_env_file "$shop_path")
    
    if [ $? -ne 0 ] || [ -z "$env_file" ]; then
        error "Impossible de trouver le fichier .env dans modules/ps_mbo/"
        warning "Les fichiers suivants ont été cherchés:"
        warning "  - ${mbo_module_path}/.env"
        warning "  - ${mbo_module_path}/.env.local"
        warning "  - ${mbo_module_path}/.env.dist"
        return 1
    fi
    
    info "Fichier .env trouvé: $env_file"
    echo ""
    
    # Lire les variables d'environnement
    local cdc_url=$(_read_env_var "$env_file" "MBO_CDC_URL")
    local api_url=$(_read_env_var "$env_file" "DISTRIBUTION_API_URL")
    local addons_url=$(_read_env_var "$env_file" "ADDONS_API_URL")
    local sentry_credentials=$(_read_env_var "$env_file" "SENTRY_CREDENTIALS")
    local sentry_env=$(_read_env_var "$env_file" "SENTRY_ENVIRONMENT")
    
    # Détecter les environnements
    local env_info
    env_info=$(_detect_environment "$cdc_url" "$api_url" "$addons_url")
    local mbo_env=$(echo "$env_info" | cut -d'|' -f1)
    local addons_env=$(echo "$env_info" | cut -d'|' -f2)
    
    # Afficher les informations
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Configuration ps_mbo"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "Environnements:"
    echo "  MBO:    $mbo_env"
    echo "  Addons: $addons_env"
    echo ""
    
    echo "URLs de configuration:"
    if [ -n "$cdc_url" ]; then
        echo "  CDC URL:     $cdc_url"
    else
        echo "  CDC URL:     (non configuré)"
    fi
    
    if [ -n "$api_url" ]; then
        echo "  API URL:     $api_url"
    else
        echo "  API URL:     (non configuré)"
    fi
    
    if [ -n "$addons_url" ]; then
        echo "  Addons URL:  $addons_url"
    else
        echo "  Addons URL:  (non configuré)"
    fi
    echo ""
    
    echo "Sentry:"
    if [ -n "$sentry_credentials" ] && [ "$sentry_credentials" != '""' ] && [ "$sentry_credentials" != "" ]; then
        echo "  Credentials:  Configuré"
        if [ -n "$sentry_env" ] && [ "$sentry_env" != '""' ] && [ "$sentry_env" != "" ]; then
            echo "  Environment:  $sentry_env"
        else
            echo "  Environment:  (non configuré)"
        fi
    else
        echo "  Credentials:  Non configuré"
        echo "  Environment:  Non configuré"
    fi
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    return 0
}




