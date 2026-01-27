#!/bin/bash

# Nettoyage du cache et des fichiers temporaires d'un shop

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger les fonctions de gestion des shops
if [ -f "${SCRIPT_DIR}/lib/utils/shops.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/shops.sh"
fi

# Commande principale pour nettoyer un shop
cmd_shop_clean() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Nettoyage du cache et des fichiers temporaires d'un shop PrestaShop

Usage:
    ps_tool shop clean <nom_shop> [options]

Arguments:
    nom_shop           Nom de la shop à nettoyer

Options:
    --cache-only       Nettoyer uniquement le cache Symfony
    --files-only       Nettoyer uniquement les fichiers temporaires
    --all              Nettoyer le cache ET les fichiers temporaires (défaut)
    --help, -h         Afficher cette aide

Exemples:
    ps_tool shop clean shop18
    ps_tool shop clean shop18 --cache-only
    ps_tool shop clean shop18 --files-only

La commande va:
    1. Vider le cache Symfony (var/cache/)
    2. Supprimer les fichiers temporaires (var/logs/, var/tmp/)
    3. Nettoyer le cache Smarty (var/cache/smarty/)
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    local shop_name="$1"
    shift
    
    # Options par défaut
    local clean_cache=true
    local clean_files=true
    
    # Parser les options
    while [ $# -gt 0 ]; do
        case "$1" in
            --cache-only)
                clean_cache=true
                clean_files=false
                shift
                ;;
            --files-only)
                clean_cache=false
                clean_files=true
                shift
                ;;
            --all)
                clean_cache=true
                clean_files=true
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
    
    info "Nettoyage du shop: $shop_name"
    info "Chemin du shop: $shop_path"
    echo ""
    
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
            error "ddev doit être démarré pour nettoyer le shop"
            return 1
        fi
    fi
    
    local cleaned=false
    
    # Nettoyer le cache Symfony
    if [ "$clean_cache" = true ]; then
        info "Nettoyage du cache Symfony..."
        
        # Vider le cache via la console Symfony
        local cache_output
        cache_output=$(ddev exec "php bin/console cache:clear --no-warmup 2>&1" 2>&1)
        local cache_exit_code=$?
        
        if [ $cache_exit_code -eq 0 ]; then
            success "Cache Symfony vidé avec succès"
            cleaned=true
        else
            # Vérifier si c'est juste un warning
            if echo "$cache_output" | grep -qiE "cleared|success|done" || echo "$cache_output" | grep -qiE "warning.*filemtime"; then
                success "Cache Symfony vidé (avec warnings non-critiques)"
                cleaned=true
            else
                warning "Le vidage du cache Symfony a généré des messages"
            fi
        fi
        
        # Supprimer aussi le répertoire var/cache/ directement
        if [ -d "$shop_path/var/cache" ]; then
            info "Suppression du répertoire var/cache/..."
            if ddev exec "rm -rf var/cache/*" 2>/dev/null; then
                success "Répertoire var/cache/ nettoyé"
                cleaned=true
            fi
        fi
    fi
    
    # Nettoyer les fichiers temporaires
    if [ "$clean_files" = true ]; then
        info "Nettoyage des fichiers temporaires..."
        
        # Nettoyer var/logs/ (garder la structure mais vider les fichiers)
        if [ -d "$shop_path/var/logs" ]; then
            info "Nettoyage de var/logs/..."
            if ddev exec "find var/logs -type f -name '*.log' -delete 2>/dev/null || true"; then
                success "Fichiers de logs supprimés"
                cleaned=true
            fi
        fi
        
        # Nettoyer var/tmp/ si existe
        if [ -d "$shop_path/var/tmp" ]; then
            info "Nettoyage de var/tmp/..."
            if ddev exec "rm -rf var/tmp/* 2>/dev/null || true"; then
                success "Répertoire var/tmp/ nettoyé"
                cleaned=true
            fi
        fi
        
        # Nettoyer le cache Smarty
        if [ -d "$shop_path/var/cache/smarty" ]; then
            info "Nettoyage du cache Smarty..."
            if ddev exec "rm -rf var/cache/smarty/* 2>/dev/null || true"; then
                success "Cache Smarty nettoyé"
                cleaned=true
            fi
        fi
        
        # Nettoyer les fichiers temporaires PHP
        info "Nettoyage des fichiers temporaires PHP..."
        if ddev exec "find var -type f -name '*.tmp' -delete 2>/dev/null || true"; then
            success "Fichiers temporaires PHP supprimés"
            cleaned=true
        fi
    fi
    
    if [ "$cleaned" = true ]; then
        success "Nettoyage terminé avec succès !"
    else
        warning "Aucun nettoyage effectué"
    fi
    
    return 0
}




