#!/bin/bash

# Désinstallation du module ps_mbo

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger les fonctions de gestion des shops
if [ -f "${SCRIPT_DIR}/lib/utils/shops.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/shops.sh"
fi

# Commande principale pour désinstaller ps_mbo
cmd_mbo_uninstall() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Désinstallation du module ps_mbo d'un shop PrestaShop

Usage:
    ps_tool mbo uninstall <nom_shop> [options]

Arguments:
    nom_shop           Nom de la shop où désinstaller ps_mbo

Options:
    --files            Supprimer aussi les fichiers du module (modules/ps_mbo/)
    --help, -h         Afficher cette aide

Exemples:
    ps_tool mbo uninstall shop18
    ps_tool mbo uninstall shop18 --files

La commande va:
    1. Désinstaller le module ps_mbo via la console Symfony
    2. Optionnellement supprimer les fichiers du module si --files est spécifié
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    local shop_name="$1"
    shift
    
    # Options
    local remove_files=false
    
    # Parser les options
    while [ $# -gt 0 ]; do
        case "$1" in
            --files)
                remove_files=true
                shift
                ;;
            --help|-h)
                # Aide déjà affichée au début
                return 0
                ;;
            *)
                warning "Option inconnue: $1"
                shift
                ;;
        esac
    done
    
    # Valider le shop
    if ! validate_shop "$shop_name"; then
        return 1
    fi
    
    local shop_path="$_SHOP_PATH"
    
    info "Désinstallation de ps_mbo du shop: $shop_name"
    info "Chemin du shop: $shop_path"
    
    # Vérifier que le module ps_mbo est installé
    local mbo_module_path="${shop_path}/modules/ps_mbo"
    if [ ! -d "$mbo_module_path" ]; then
        warning "Le module ps_mbo n'est pas installé dans ce shop"
        return 0
    fi
    
    # Vérifier que ddev est démarré
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
            if [ "$remove_files" = true ]; then
                # Si on veut supprimer les fichiers, on peut le faire même sans ddev
                info "Suppression des fichiers du module..."
                if rm -rf "$mbo_module_path"; then
                    success "Fichiers du module supprimés"
                    return 0
                else
                    error "Échec de la suppression des fichiers"
                    return 1
                fi
            else
                error "ddev doit être démarré pour désinstaller le module"
                return 1
            fi
        fi
    fi
    
    # Désinstaller le module via la console Symfony
    info "Désinstallation du module via la console Symfony..."
    local uninstall_output
    uninstall_output=$(ddev exec "php bin/console prestashop:module uninstall ps_mbo 2>&1" 2>&1)
    local uninstall_exit_code=$?
    
    if [ $uninstall_exit_code -eq 0 ]; then
        success "Module ps_mbo désinstallé avec succès"
    else
        # Vérifier si c'est parce que le module n'est pas installé
        if echo "$uninstall_output" | grep -qiE "not installed|non installé|not found"; then
            info "Le module ps_mbo n'est pas installé"
        elif echo "$uninstall_output" | grep -qiE "success|uninstalled|désinstallé"; then
            # Le module a été désinstallé malgré le code d'erreur (peut-être des warnings)
            success "Module ps_mbo désinstallé avec succès"
        else
            # Vraie erreur
            error "Échec de la désinstallation du module ps_mbo"
            echo "$uninstall_output" | tail -15 >&2
            if [ "$remove_files" = false ]; then
                return 1
            fi
            # Continuer pour supprimer les fichiers même en cas d'erreur
        fi
    fi
    
    # Supprimer les fichiers du module si demandé
    if [ "$remove_files" = true ]; then
        info "Suppression des fichiers du module..."
        if [ -d "$mbo_module_path" ]; then
            if rm -rf "$mbo_module_path"; then
                success "Fichiers du module supprimés"
            else
                warning "Échec de la suppression des fichiers du module"
                return 1
            fi
        else
            info "Le répertoire du module n'existe plus"
        fi
    fi
    
    success "Désinstallation de ps_mbo terminée avec succès !"
    return 0
}

