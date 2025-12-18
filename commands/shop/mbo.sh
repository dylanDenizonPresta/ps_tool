#!/bin/bash

# Installation du module ps_mbo dans un shop PrestaShop

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

# Charger la configuration ps_mbo
if [ -f "${SCRIPT_DIR}/config/ps_mbo.sh" ]; then
    source "${SCRIPT_DIR}/config/ps_mbo.sh"
fi


# Commande principale pour installer ps_mbo
cmd_shop_mbo_install() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Installation du module ps_mbo dans un shop PrestaShop

Usage:
    ps_tool mbo install <nom_shop> [version]

Arguments:
    nom_shop          Nom de la shop où installer ps_mbo
    version           Version de ps_mbo à installer (optionnel)
                      Par défaut: version recommandée selon PrestaShop

Options:
    --help, -h        Afficher cette aide

Exemples:
    ps_tool mbo install shop18
    ps_tool mbo install shop18 5.2.1

La commande va:
    1. Récupérer la version PrestaShop depuis le registre
    2. Télécharger la version recommandée de ps_mbo (ou celle spécifiée)
    3. Extraire le module dans modules/ps_mbo/
    4. Installer le module via la console Symfony
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    local shop_name="$1"
    local mbo_version=""
    
    # Parser les arguments
    shift
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                # Aide déjà affichée au début
                return 0
                ;;
            -*)
                warning "Option inconnue: $1"
                shift
                ;;
            *)
                # Si ce n'est pas une option, c'est probablement la version ps_mbo
                if [ -z "$mbo_version" ] && [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    mbo_version="$1"
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
    
    info "Installation de ps_mbo dans le shop: $shop_name"
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
    
    # Déterminer la version de ps_mbo à installer
    if [ -z "$mbo_version" ]; then
        mbo_version=$(get_ps_mbo_version_for_prestashop "$prestashop_version")
        if [ -z "$mbo_version" ]; then
            error "Aucune version recommandée de ps_mbo trouvée pour PrestaShop $prestashop_version"
            return 1
        fi
        info "Version ps_mbo recommandée: $mbo_version"
    else
        # Vérifier que la version spécifiée existe
        if ! ps_mbo_version_exists "$mbo_version"; then
            error "Version ps_mbo invalide: $mbo_version"
            return 1
        fi
        info "Version ps_mbo spécifiée: $mbo_version"
    fi
    
    # Obtenir l'URL de téléchargement
    local download_url=$(get_ps_mbo_url "$mbo_version")
    if [ -z "$download_url" ]; then
        error "Impossible d'obtenir l'URL de téléchargement pour ps_mbo $mbo_version"
        return 1
    fi
    
    # Créer un répertoire temporaire pour le téléchargement
    local temp_dir=$(mktemp -d)
    local zip_file="$temp_dir/ps_mbo.zip"
    
    # Télécharger ps_mbo
    info "Téléchargement de ps_mbo $mbo_version..."
    if command_exists curl; then
        if ! curl -fsSL -o "$zip_file" "$download_url"; then
            error "Échec du téléchargement de ps_mbo"
            rm -rf "$temp_dir"
            return 1
        fi
    elif command_exists wget; then
        if ! wget -q -O "$zip_file" "$download_url"; then
            error "Échec du téléchargement de ps_mbo"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        error "curl ou wget est requis pour télécharger ps_mbo"
        rm -rf "$temp_dir"
        return 1
    fi
    
    success "ps_mbo téléchargé avec succès"
    
    # Vérifier que le fichier ZIP existe et n'est pas vide
    if [ ! -f "$zip_file" ] || [ ! -s "$zip_file" ]; then
        error "Le fichier téléchargé est invalide ou vide"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extraire le module
    info "Extraction de ps_mbo..."
    local extract_dir="$temp_dir/extract"
    mkdir -p "$extract_dir"
    
    if command_exists unzip; then
        if ! unzip -q "$zip_file" -d "$extract_dir"; then
            error "Échec de l'extraction de ps_mbo"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        error "unzip est requis pour extraire ps_mbo"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Trouver le répertoire ps_mbo dans l'extraction
    local module_dir=""
    if [ -d "$extract_dir/ps_mbo" ]; then
        module_dir="$extract_dir/ps_mbo"
    elif [ -d "$extract_dir" ] && [ -f "$extract_dir/config.xml" ] || [ -f "$extract_dir/index.php" ]; then
        # Le module est directement dans le répertoire d'extraction
        module_dir="$extract_dir"
    else
        # Chercher un répertoire contenant ps_mbo
        module_dir=$(find "$extract_dir" -type d -name "ps_mbo" | head -1)
    fi
    
    if [ -z "$module_dir" ] || [ ! -d "$module_dir" ]; then
        error "Impossible de trouver le répertoire du module ps_mbo dans l'archive"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Vérifier que le module contient les fichiers nécessaires
    if [ ! -f "$module_dir/index.php" ] && [ ! -f "$module_dir/ps_mbo.php" ]; then
        error "Le module ps_mbo ne semble pas être valide"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Créer le répertoire modules s'il n'existe pas
    local modules_dir="$shop_path/modules"
    if [ ! -d "$modules_dir" ]; then
        mkdir -p "$modules_dir"
    fi
    
    # Supprimer l'ancienne installation si elle existe
    local target_module_dir="$modules_dir/ps_mbo"
    if [ -d "$target_module_dir" ]; then
        warning "Le module ps_mbo existe déjà, suppression de l'ancienne version..."
        rm -rf "$target_module_dir"
    fi
    
    # Copier le module dans modules/ps_mbo/
    info "Installation du module dans modules/ps_mbo/..."
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
    if ! ddev exec "php bin/console prestashop:module install ps_mbo"; then
        error "Échec de l'installation du module via la console"
        warning "Le module a été copié dans modules/ps_mbo/ mais n'a pas été installé"
        warning "Vous pouvez l'installer manuellement depuis le back-office ou avec:"
        warning "  cd $shop_path && ddev exec php bin/console prestashop:module install ps_mbo"
        return 1
    fi
    
    success "Module ps_mbo installé avec succès !"
    info "Version installée: $mbo_version"
    info "Le module est maintenant disponible dans votre back-office PrestaShop"
}

