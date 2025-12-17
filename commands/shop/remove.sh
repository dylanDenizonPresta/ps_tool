#!/bin/bash

# Supprimer un shop PrestaShop

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
# On doit d'abord trouver le répertoire pour charger utils.sh
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration
if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
    source "${SCRIPT_DIR}/lib/config.sh"
fi

# Commande pour supprimer un shop
cmd_shop_remove() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Supprimer un shop PrestaShop

Usage:
    ps_tool shop remove <nom_shop> [options]

Arguments:
    nom_shop          Nom du shop à supprimer

Options:
    --force, -f       Supprimer sans demander de confirmation
    --files           Supprimer également les fichiers du shop
    --help, -h        Afficher cette aide

Exemples:
    ps_tool shop remove shop18
    ps_tool shop remove shop18 --force
    ps_tool shop remove shop18 --files

Par défaut, la commande supprime uniquement le shop du registre.
Utilisez --files pour supprimer également les fichiers du répertoire.
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            exit 0
        else
            exit 1
        fi
    fi

    local shop_name="$1"
    shift
    
    local force=false
    local remove_files=false
    
    # Parser les options
    while [ $# -gt 0 ]; do
        case "$1" in
            --force|-f)
                force=true
                ;;
            --files)
                remove_files=true
                ;;
            *)
                warning "Option inconnue: $1"
                ;;
        esac
        shift
    done
    
    # Trouver le chemin du shop dans le registre
    local shop_path=$(get_shop_path "$shop_name")
    
    if [ -z "$shop_path" ]; then
        error "Shop non trouvé: $shop_name"
        info "Listez les shops disponibles avec: ps_tool shop list"
        exit 1
    fi
    
    # Vérifier que le répertoire existe (pour remove, on accepte qu'il n'existe plus)
    if [ ! -d "$shop_path" ]; then
        warning "Le répertoire du shop n'existe plus: $shop_path"
        info "Suppression du shop du registre uniquement"
        remove_files=false
    fi
    
    # Afficher les informations du shop
    info "Shop à supprimer: $shop_name"
    info "Répertoire: $shop_path"
    
    if [ "$remove_files" = true ]; then
        warning "ATTENTION: Cette action va supprimer définitivement les fichiers du shop !"
    else
        info "Seul le registre sera mis à jour (les fichiers seront conservés)"
    fi
    
    # Demander confirmation si --force n'est pas utilisé
    if [ "$force" = false ]; then
        if ! confirm "Voulez-vous vraiment supprimer ce shop ?"; then
            info "Suppression annulée"
            exit 0
        fi
    fi
    
    # Arrêter le shop s'il est démarré et le retirer de la liste ddev
    if command_exists ddev; then
        # Obtenir le nom du projet ddev depuis le registre ou depuis la config
        local ddev_project_name="$shop_name"
        if [ -d "$shop_path" ] && [ -f "$shop_path/.ddev/config.yaml" ]; then
            # Lire le nom du projet depuis la config ddev (au cas où il serait différent)
            local config_name=$(grep -E "^name:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/^name:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"' | tr -d "'" || echo "")
            if [ -n "$config_name" ]; then
                ddev_project_name="$config_name"
            fi
            
            local status=$(get_shop_status "$shop_path")
            if [ "$status" = "Démarré" ]; then
                info "Arrêt du shop avant suppression..."
                # Arrêter ET retirer de la liste ddev en une seule commande
                (cd "$shop_path" && ddev stop --unlist 2>/dev/null) || true
            else
                # Si le projet est arrêté, juste le retirer de la liste
                info "Retrait du projet '$ddev_project_name' de la liste ddev..."
                (cd "$shop_path" && ddev stop --unlist 2>/dev/null) || true
            fi
        else
            # Si le répertoire n'existe plus, essayer de retirer avec le nom du projet
            # Note: ddev stop --unlist nécessite généralement d'être dans le répertoire du projet
            # On essaie quand même au cas où ddev accepterait le nom
            info "Tentative de retrait du projet '$ddev_project_name' de la liste ddev..."
            # Chercher le projet dans ddev list et essayer de le retirer
            local project_exists=$(ddev list 2>/dev/null | grep -E "^[[:space:]]*${ddev_project_name}[[:space:]]" || echo "")
            if [ -n "$project_exists" ]; then
                warning "Le projet existe toujours dans ddev mais le répertoire n'existe plus"
                info "Vous pouvez le retirer manuellement avec: cd <chemin_du_projet> && ddev stop --unlist"
                info "Ou supprimer complètement avec: ddev delete $ddev_project_name"
            fi
        fi
    fi
    
    # Supprimer le shop du registre
    info "Suppression du shop du registre..."
    
    if [ -z "$PS_TOOL_SHOPS_REGISTRY" ]; then
        if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
            source "${SCRIPT_DIR}/lib/config.sh"
        else
            PS_TOOL_SHOPS_REGISTRY="${HOME}/.ps_tool/shops.txt"
        fi
    fi
    
    if [ -f "$PS_TOOL_SHOPS_REGISTRY" ]; then
        local temp_file=$(mktemp)
        grep -v "^${shop_name}|" "$PS_TOOL_SHOPS_REGISTRY" > "$temp_file" 2>/dev/null || true
        
        if [ -s "$temp_file" ]; then
            mv "$temp_file" "$PS_TOOL_SHOPS_REGISTRY"
        else
            # Si le fichier est vide, le supprimer
            rm -f "$PS_TOOL_SHOPS_REGISTRY"
            rm -f "$temp_file"
        fi
        
        success "Shop supprimé du registre"
    fi
    
    # Supprimer les fichiers si demandé
    if [ "$remove_files" = true ] && [ -d "$shop_path" ]; then
        info "Suppression des fichiers du shop..."
        
        # Demander une confirmation supplémentaire pour la suppression des fichiers
        if [ "$force" = false ]; then
            if ! confirm "Confirmez la suppression définitive des fichiers ?"; then
                warning "Suppression des fichiers annulée"
                info "Le shop a été retiré du registre mais les fichiers sont conservés"
                exit 0
            fi
        fi
        
        if rm -rf "$shop_path"; then
            success "Fichiers du shop supprimés"
        else
            error "Erreur lors de la suppression des fichiers"
            warning "Le shop a été retiré du registre mais certains fichiers peuvent encore exister"
            exit 1
        fi
    fi
    
    success "Shop $shop_name supprimé avec succès"
}

