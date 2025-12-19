#!/bin/bash

# Installation du module ps_accounts dans un shop PrestaShop

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration PrestaShop
if [ -f "${SCRIPT_DIR}/config/prestashop.sh" ]; then
    source "${SCRIPT_DIR}/config/prestashop.sh"
fi

# Charger la configuration ps_accounts
if [ -f "${SCRIPT_DIR}/config/ps_accounts.sh" ]; then
    source "${SCRIPT_DIR}/config/ps_accounts.sh"
fi

# Charger les fonctions de gestion des shops
if [ -f "${SCRIPT_DIR}/lib/utils/shops.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/shops.sh"
fi

# Commande principale pour installer ps_accounts
cmd_account_install() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Installation du module ps_accounts dans un shop PrestaShop

Usage:
    ps_tool account install <nom_shop> [version] [options]

Arguments:
    nom_shop          Nom de la shop où installer ps_accounts
    version           Version de ps_accounts à installer (optionnel)
                      Par défaut: version recommandée selon PrestaShop

Options:
    --env <PROD|PREPROD>  Environnement à installer (PROD par défaut)
    --help, -h            Afficher cette aide

Exemples:
    ps_tool account install shop18
    ps_tool account install shop18 8.0.8
    ps_tool account install shop18 --env PREPROD
    ps_tool account install shop18 8.0.8 --env PREPROD

La commande va:
    1. Récupérer la version PrestaShop depuis le registre
    2. Télécharger la version recommandée de ps_accounts (ou celle spécifiée)
    3. Extraire le module dans modules/ps_accounts/
    4. Installer le module via la console Symfony
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    local shop_name="$1"
    local accounts_version=""
    local environment="PROD"
    
    # Parser les arguments
    shift
    while [ $# -gt 0 ]; do
        case "$1" in
            --env|--environment)
                if [ $# -lt 2 ]; then
                    error "Option --env nécessite un environnement (PROD ou PREPROD)"
                    return 1
                fi
                if [ "$2" != "PROD" ] && [ "$2" != "PREPROD" ]; then
                    error "Environnement invalide: $2. Utilisez 'PROD' ou 'PREPROD'."
                    return 1
                fi
                environment="$2"
                shift 2
                ;;
            --help|-h)
                # Aide déjà affichée au début
                return 0
                ;;
            -*)
                warning "Option inconnue: $1"
                shift
                ;;
            *)
                # Si ce n'est pas une option, c'est probablement la version ps_accounts
                if [ -z "$accounts_version" ] && [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    accounts_version="$1"
                else
                    warning "Argument ignoré: $1"
                fi
                shift
                ;;
        esac
    done
    
    # Valider le shop
    if ! validate_shop "$shop_name"; then
        return 1
    fi
    
    local shop_path="$_SHOP_PATH"
    
    info "Installation de ps_accounts dans le shop: $shop_name"
    info "Chemin du shop: $shop_path"
    
    # Récupérer la version de PrestaShop depuis le registre
    info "Récupération de la version PrestaShop depuis le registre..."
    local prestashop_version=$(get_shop_prestashop_version "$shop_name")
    
    if [ -z "$prestashop_version" ]; then
        error "Impossible de récupérer la version PrestaShop depuis le registre"
        warning "Le shop n'a peut-être pas été créé avec ps_tool"
        return 1
    fi
    
    info "Version PrestaShop: $prestashop_version"
    
    # Déterminer la version de ps_accounts à installer
    if [ -z "$accounts_version" ]; then
        accounts_version=$(get_ps_accounts_version_for_prestashop "$prestashop_version")
        if [ -z "$accounts_version" ]; then
            error "Aucune version recommandée de ps_accounts trouvée pour PrestaShop $prestashop_version"
            return 1
        fi
        info "Version ps_accounts recommandée: $accounts_version"
    else
        # Vérifier que la version spécifiée existe
        if ! ps_accounts_version_exists "$accounts_version"; then
            error "Version ps_accounts invalide: $accounts_version"
            return 1
        fi
        info "Version ps_accounts spécifiée: $accounts_version"
    fi
    
    info "Environnement: $environment"
    
    # Obtenir l'URL de téléchargement selon l'environnement
    local download_url=$(get_ps_accounts_url "$accounts_version" "$environment")
    if [ -z "$download_url" ]; then
        error "Impossible d'obtenir l'URL de téléchargement pour ps_accounts $accounts_version"
        return 1
    fi
    
    # Créer un répertoire temporaire pour le téléchargement
    local temp_dir=$(mktemp -d)
    local zip_file="$temp_dir/ps_accounts.zip"
    
    # Télécharger ps_accounts
    info "Téléchargement de ps_accounts $accounts_version ($environment)..."
    if command_exists curl; then
        if ! curl -fsSL -o "$zip_file" "$download_url"; then
            error "Échec du téléchargement de ps_accounts"
            rm -rf "$temp_dir"
            return 1
        fi
    elif command_exists wget; then
        if ! wget -q -O "$zip_file" "$download_url"; then
            error "Échec du téléchargement de ps_accounts"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        error "curl ou wget est requis pour télécharger ps_accounts"
        rm -rf "$temp_dir"
        return 1
    fi
    
    success "ps_accounts téléchargé avec succès"
    
    # Vérifier que le fichier ZIP existe et n'est pas vide
    if [ ! -f "$zip_file" ] || [ ! -s "$zip_file" ]; then
        error "Le fichier téléchargé est invalide ou vide"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extraire le module
    info "Extraction de ps_accounts..."
    local extract_dir="$temp_dir/extract"
    mkdir -p "$extract_dir"
    
    if command_exists unzip; then
        if ! unzip -q "$zip_file" -d "$extract_dir"; then
            error "Échec de l'extraction de ps_accounts"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        error "unzip est requis pour extraire ps_accounts"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Trouver le répertoire ps_accounts dans l'extraction
    local module_dir=""
    if [ -d "$extract_dir/ps_accounts" ]; then
        module_dir="$extract_dir/ps_accounts"
    elif [ -d "$extract_dir" ] && ([ -f "$extract_dir/config.xml" ] || [ -f "$extract_dir/index.php" ] || [ -f "$extract_dir/ps_accounts.php" ]); then
        # Le module est directement dans le répertoire d'extraction
        module_dir="$extract_dir"
    else
        # Chercher un répertoire contenant ps_accounts
        module_dir=$(find "$extract_dir" -type d -name "ps_accounts" | head -1)
    fi
    
    if [ -z "$module_dir" ] || [ ! -d "$module_dir" ]; then
        error "Impossible de trouver le répertoire du module ps_accounts dans l'archive"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Vérifier que le module contient les fichiers nécessaires
    if [ ! -f "$module_dir/index.php" ] && [ ! -f "$module_dir/ps_accounts.php" ]; then
        error "Le module ps_accounts ne semble pas être valide"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Créer le répertoire modules s'il n'existe pas
    local modules_dir="$shop_path/modules"
    if [ ! -d "$modules_dir" ]; then
        mkdir -p "$modules_dir"
    fi
    
    # Supprimer l'ancienne installation si elle existe
    local target_module_dir="$modules_dir/ps_accounts"
    if [ -d "$target_module_dir" ]; then
        warning "Le module ps_accounts existe déjà, suppression de l'ancienne version..."
        rm -rf "$target_module_dir"
    fi
    
    # Copier le module dans modules/ps_accounts/
    info "Installation du module dans modules/ps_accounts/..."
    if ! cp -R "$module_dir" "$target_module_dir"; then
        error "Échec de la copie du module"
        rm -rf "$temp_dir"
        return 1
    fi
    
    success "Module copié avec succès"
    
    # Nettoyer le répertoire temporaire
    rm -rf "$temp_dir"
    
    # Vérifier que ddev est démarré
    info "Vérification de l'état de ddev..."
    cd "$shop_path" || return 1
    
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
            error "ddev doit être démarré pour installer le module"
            return 1
        fi
    fi
    
    # Installer le module via la console Symfony
    info "Installation du module via la console Symfony..."
    if ! ddev exec "php bin/console prestashop:module install ps_accounts"; then
        error "Échec de l'installation du module via la console"
        warning "Le module a été copié dans modules/ps_accounts/ mais n'a pas été installé"
        warning "Vous pouvez l'installer manuellement depuis le back-office ou avec:"
        warning "  cd $shop_path && ddev exec php bin/console prestashop:module install ps_accounts"
        return 1
    fi
    
    success "Module ps_accounts installé avec succès !"
    info "Version installée: $accounts_version"
    info "Environnement: $environment"
    info "Le module est maintenant disponible dans votre back-office PrestaShop"
}

