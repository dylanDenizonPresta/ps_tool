#!/bin/bash

# Configuration de l'environnement du module ps_mbo

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger les fonctions de gestion des shops
if [ -f "${SCRIPT_DIR}/lib/utils/shops.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/shops.sh"
fi

# Fonction pour obtenir les valeurs d'environnement MBO et Addons
# Usage: _get_mbo_env_values <environment>
# Retourne: mbo_env|addons_env|cdc_url|api_url|addons_url|sentry_url|sentry_env
_get_mbo_env_values() {
    local env_input=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    local mbo_env=""
    local addons_env=""
    local cdc_url=""
    local api_url=""
    local addons_url=""
    local sentry_url=""
    local sentry_env=""
    
    case "$env_input" in
        PROD)
            mbo_env="prod"
            addons_env="prod"
            cdc_url="https://assets.prestashop3.com/dst/mbo/v1/mbo-cdc.umd.js"
            api_url="https://mbo-api.prestashop.com"
            addons_url="https://api-addons.prestashop.com"
            sentry_url="https://aa99f8a351b641af994ac50b01e14e20@o298402.ingest.sentry.io/6520457"
            sentry_env="production"
            ;;
        PREPROD)
            mbo_env="preprod"
            addons_env="preprod"
            cdc_url="https://preproduction-assets.prestashop3.com/dst/mbo/v1/mbo-cdc.umd.js"
            api_url="https://mbo-api-preprod.prestashop.com"
            addons_url="https://preprod-api-addons.prestashop.com"
            sentry_url="https://aa99f8a351b641af994ac50b01e14e20@o298402.ingest.sentry.io/6520457"
            sentry_env="preproduction"
            ;;
        LOCAL)
            mbo_env="local"
            addons_env="local"
            cdc_url="http://localhost:8080/dist/mbo-cdc.umd.js"
            api_url="http://localhost:3000"
            addons_url="https://preprod-api-addons.prestashop.com"
            sentry_url=""
            sentry_env=""
            ;;
        PRESTABULLE*)
            # Extraire le numéro (PRESTABULLE1, PRESTABULLE2, etc.)
            local num=$(echo "$env_input" | grep -oE '[0-9]+' || echo "")
            if [ -z "$num" ]; then
                return 1
            fi
            mbo_env="prestabulle${num}"
            addons_env="pod${num}"
            cdc_url="https://integration-assets.prestashop3.com/dst/mbo/prestabulle${num}/mbo-cdc.umd.js"
            api_url="https://mbo-api-prestabulle${num}.prestashop.com"
            addons_url="https://addons-api-pod${num}.prestashop.com"
            sentry_url="https://aa99f8a351b641af994ac50b01e14e20@o298402.ingest.sentry.io/6520457"
            sentry_env="prestabulle${num}"
            ;;
        POD*)
            # Pour POD seul, garder MBO en prod
            local num=$(echo "$env_input" | grep -oE '[0-9]+' || echo "")
            if [ -z "$num" ]; then
                return 1
            fi
            mbo_env="prod"
            addons_env="pod${num}"
            cdc_url="https://assets.prestashop3.com/dst/mbo/v1/mbo-cdc.umd.js"
            api_url="https://mbo-api.prestashop.com"
            addons_url="https://addons-api-pod${num}.prestashop.com"
            sentry_url="https://aa99f8a351b641af994ac50b01e14e20@o298402.ingest.sentry.io/6520457"
            sentry_env="production"
            ;;
        *)
            return 1
            ;;
    esac
    
    echo "${mbo_env}|${addons_env}|${cdc_url}|${api_url}|${addons_url}|${sentry_url}|${sentry_env}"
    return 0
}

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

# Fonction pour mettre à jour le fichier .env
# Usage: _update_env_file <env_file_path> <cdc_url> <api_url> <addons_url> <sentry_url> <sentry_env>
_update_env_file() {
    local env_file="$1"
    local cdc_url="$2"
    local api_url="$3"
    local addons_url="$4"
    local sentry_url="$5"
    local sentry_env="$6"
    
    # Lire le contenu du fichier
    local env_data=$(cat "$env_file")
    
    # Mettre à jour les variables avec sed (remplace si existe, sinon ajoute)
    # MBO_CDC_URL
    if echo "$env_data" | grep -q "^MBO_CDC_URL="; then
        env_data=$(echo "$env_data" | sed "s|^MBO_CDC_URL=\"[^\"]*\"|MBO_CDC_URL=\"${cdc_url}\"|")
    else
        env_data="${env_data}"$'\n'"MBO_CDC_URL=\"${cdc_url}\""
    fi
    
    # DISTRIBUTION_API_URL
    if echo "$env_data" | grep -q "^DISTRIBUTION_API_URL="; then
        env_data=$(echo "$env_data" | sed "s|^DISTRIBUTION_API_URL=\"[^\"]*\"|DISTRIBUTION_API_URL=\"${api_url}\"|")
    else
        env_data="${env_data}"$'\n'"DISTRIBUTION_API_URL=\"${api_url}\""
    fi
    
    # ADDONS_API_URL
    if echo "$env_data" | grep -q "^ADDONS_API_URL="; then
        env_data=$(echo "$env_data" | sed "s|^ADDONS_API_URL=\"[^\"]*\"|ADDONS_API_URL=\"${addons_url}\"|")
    else
        env_data="${env_data}"$'\n'"ADDONS_API_URL=\"${addons_url}\""
    fi
    
    # Gérer Sentry (peut être vide pour local)
    # SENTRY_CREDENTIALS
    if echo "$env_data" | grep -q "^SENTRY_CREDENTIALS="; then
        if [ -n "$sentry_url" ]; then
            env_data=$(echo "$env_data" | sed "s|^SENTRY_CREDENTIALS=\"[^\"]*\"|SENTRY_CREDENTIALS=\"${sentry_url}\"|")
        else
            env_data=$(echo "$env_data" | sed "s|^SENTRY_CREDENTIALS=\"[^\"]*\"|SENTRY_CREDENTIALS=\"\"|")
        fi
    else
        env_data="${env_data}"$'\n'"SENTRY_CREDENTIALS=\"${sentry_url}\""
    fi
    
    # SENTRY_ENVIRONMENT
    if echo "$env_data" | grep -q "^SENTRY_ENVIRONMENT="; then
        if [ -n "$sentry_env" ]; then
            env_data=$(echo "$env_data" | sed "s|^SENTRY_ENVIRONMENT=\"[^\"]*\"|SENTRY_ENVIRONMENT=\"${sentry_env}\"|")
        else
            env_data=$(echo "$env_data" | sed "s|^SENTRY_ENVIRONMENT=\"[^\"]*\"|SENTRY_ENVIRONMENT=\"\"|")
        fi
    else
        env_data="${env_data}"$'\n'"SENTRY_ENVIRONMENT=\"${sentry_env}\""
    fi
    
    # Écrire le fichier modifié
    echo "$env_data" > "$env_file"
}

# Fonction pour reset le module
# Usage: _reset_mbo_module <shop_path>
_reset_mbo_module() {
    local shop_path="$1"
    
    cd "$shop_path" || return 1
    
    # Vérifier que ddev est démarré
    if ! ddev describe > /dev/null 2>&1; then
        warning "ddev n'est pas démarré pour ce shop"
        if confirm "Voulez-vous démarrer ddev maintenant ?"; then
            info "Démarrage de ddev..."
            if ! ddev start; then
                error "Échec du démarrage de ddev"
                return 1
            fi
            success "ddev démarré avec succès"
        else
            error "ddev doit être démarré pour reset le module"
            return 1
        fi
    fi
    
    # Reset le module ps_mbo
    info "Reset du module ps_mbo..."
    local reset_output
    reset_output=$(ddev exec "php bin/console prestashop:module install ps_mbo 2>&1" 2>&1)
    local reset_exit_code=$?
    
    if [ $reset_exit_code -eq 0 ]; then
        success "Module ps_mbo reset avec succès"
    else
        # Vérifier si c'est parce que le module est déjà installé
        if echo "$reset_output" | grep -qiE "already installed|déjà installé|already enabled"; then
            info "Le module ps_mbo est déjà installé et configuré"
            success "Configuration terminée"
        elif echo "$reset_output" | grep -qiE "success|installed|enabled"; then
            # Le module a été installé malgré le code d'erreur (peut-être des warnings)
            success "Module ps_mbo reset avec succès"
        else
            # Vraie erreur
            error "Échec du reset du module ps_mbo"
            echo "$reset_output" | tail -15 >&2
            return 1
        fi
    fi
    
    return 0
}

# Commande principale pour configurer l'environnement MBO
cmd_mbo_use() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Configuration de l'environnement du module ps_mbo

Usage:
    ps_tool mbo use <environment> <nom_shop>

Arguments:
    environment        Environnement à utiliser (PROD, PREPROD, LOCAL, PRESTABULLE1-9, POD1-9)
    nom_shop           Nom de la shop où configurer ps_mbo

Environnements disponibles:
    PROD              Production (MBO: prod, Addons: prod)
    PREPROD           Préproduction (MBO: preprod, Addons: preprod)
    LOCAL             Local (MBO: local, Addons: local)
    PRESTABULLE1-9    Prestabulle 1 à 9 (MBO: prestabulleN, Addons: podN)
    POD1-9            Pod 1 à 9 (MBO: prod, Addons: podN)

Options:
    --help, -h        Afficher cette aide

Exemples:
    ps_tool mbo use PROD shop18
    ps_tool mbo use PREPROD shop18
    ps_tool mbo use LOCAL shop18
    ps_tool mbo use PRESTABULLE1 shop18
    ps_tool mbo use POD2 shop18

La commande va:
    1. Trouver le fichier .env dans modules/ps_mbo/
    2. Mettre à jour les variables d'environnement (MBO_CDC_URL, DISTRIBUTION_API_URL, ADDONS_API_URL, SENTRY_CREDENTIALS, SENTRY_ENVIRONMENT)
    3. Reset le module ps_mbo
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    if [ $# -lt 2 ]; then
        error "Usage: ps_tool mbo use <environment> <nom_shop>"
        echo ""
        echo "Environnements disponibles: PROD, PREPROD, LOCAL, PRESTABULLE1-9, POD1-9"
        return 1
    fi
    
    local environment="$1"
    local shop_name="$2"
    
    # Valider le shop
    if ! validate_shop "$shop_name"; then
        return 1
    fi
    
    local shop_path="$_SHOP_PATH"
    
    info "Configuration de l'environnement MBO pour le shop: $shop_name"
    info "Environnement demandé: $environment"
    info "Chemin du shop: $shop_path"
    
    # Obtenir les valeurs d'environnement
    local env_values
    env_values=$(_get_mbo_env_values "$environment")
    
    if [ $? -ne 0 ] || [ -z "$env_values" ]; then
        error "Environnement non reconnu: $environment"
        echo ""
        echo "Environnements disponibles:"
        echo "  PROD              - Production"
        echo "  PREPROD           - Préproduction"
        echo "  LOCAL             - Local"
        echo "  PRESTABULLE1-9    - Prestabulle 1 à 9"
        echo "  POD1-9            - Pod 1 à 9"
        return 1
    fi
    
    # Extraire les valeurs
    local mbo_env=$(echo "$env_values" | cut -d'|' -f1)
    local addons_env=$(echo "$env_values" | cut -d'|' -f2)
    local cdc_url=$(echo "$env_values" | cut -d'|' -f3)
    local api_url=$(echo "$env_values" | cut -d'|' -f4)
    local addons_url=$(echo "$env_values" | cut -d'|' -f5)
    local sentry_url=$(echo "$env_values" | cut -d'|' -f6)
    local sentry_env=$(echo "$env_values" | cut -d'|' -f7)
    
    info "Configuration:"
    info "  MBO Environment: $mbo_env"
    info "  Addons Environment: $addons_env"
    
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
    
    # Créer une sauvegarde du fichier .env
    local backup_file="${env_file}.backup.$(date +%Y%m%d_%H%M%S)"
    if cp "$env_file" "$backup_file"; then
        info "Sauvegarde créée: $backup_file"
    else
        warning "Impossible de créer une sauvegarde"
    fi
    
    # Mettre à jour le fichier .env
    info "Mise à jour du fichier .env..."
    if ! _update_env_file "$env_file" "$cdc_url" "$api_url" "$addons_url" "$sentry_url" "$sentry_env"; then
        error "Échec de la mise à jour du fichier .env"
        # Restaurer la sauvegarde en cas d'erreur
        if [ -f "$backup_file" ]; then
            mv "$backup_file" "$env_file"
            info "Fichier .env restauré depuis la sauvegarde"
        fi
        return 1
    fi
    
    success "Fichier .env mis à jour avec succès"
    
    # Reset le module
    if ! _reset_mbo_module "$shop_path"; then
        warning "La configuration a été mise à jour mais le reset du module a échoué"
        warning "Vous pouvez reset le module manuellement avec:"
        warning "  cd $shop_path && ddev exec php bin/console prestashop:module install ps_mbo"
        return 1
    fi
    
    success "Configuration de l'environnement MBO terminée avec succès !"
    info "Environnement: $environment"
    info "MBO: $mbo_env"
    info "Addons: $addons_env"
}

