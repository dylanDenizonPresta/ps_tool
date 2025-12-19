#!/bin/bash

# Réinitialisation des données de configuration du module ps_accounts

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger les fonctions de gestion des shops
if [ -f "${SCRIPT_DIR}/lib/utils/shops.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/shops.sh"
fi

# Commande principale pour réinitialiser ps_accounts
cmd_account_reset() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Réinitialisation des données de configuration du module ps_accounts

Usage:
    ps_tool account reset <nom_shop>

Arguments:
    nom_shop           Nom de la shop où réinitialiser ps_accounts

Options:
    --help, -h         Afficher cette aide

Exemples:
    ps_tool account reset shop18

La commande va:
    1. Supprimer toutes les clés de configuration ps_accounts de la base de données
    2. Cela inclut les tokens Firebase, OAuth2, UUID, etc.
    3. Le module reste installé mais toutes ses données sont vidées

Attention: Cette opération est irréversible. Les données de configuration seront définitivement supprimées.
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    local shop_name="$1"
    shift
    
    # Parser les options
    while [ $# -gt 0 ]; do
        case "$1" in
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
    
    info "Réinitialisation des données de configuration ps_accounts pour le shop: $shop_name"
    info "Chemin du shop: $shop_path"
    
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
            error "ddev doit être démarré pour réinitialiser les données"
            return 1
        fi
    fi
    
    # Demander confirmation avant de supprimer les données
    warning "Cette opération va supprimer toutes les données de configuration ps_accounts"
    warning "Cela inclut: tokens Firebase, OAuth2, UUID, clés RSA, etc."
    if ! confirm "Êtes-vous sûr de vouloir continuer ?"; then
        info "Opération annulée"
        return 0
    fi
    
    # Exécuter la requête SQL pour supprimer toutes les clés de configuration ps_accounts
    info "Suppression des clés de configuration ps_accounts..."
    
    # La requête SQL supprime toutes les clés de configuration ps_accounts
    # Le préfixe de table est généralement "ps_" mais peut varier selon l'installation
    # On utilise une requête qui fonctionne avec le préfixe par défaut
    # Si le préfixe est différent, l'utilisateur peut le modifier manuellement
    
    local sql_query="DELETE FROM ps_configuration WHERE name LIKE 'PS_ACCOUNTS%' OR name LIKE 'PSX_UUID_V4' OR name LIKE 'PS_CHECKOUT_SHOP_UUID_V4' OR name LIKE 'PS_PSX_%';"
    
    info "Exécution de la requête SQL..."
    local reset_output
    reset_output=$(ddev exec "mysql -e \"$sql_query\"" 2>&1)
    local reset_exit_code=$?
    
    if [ $reset_exit_code -eq 0 ]; then
        success "Données de configuration ps_accounts supprimées avec succès"
        info "Les clés suivantes ont été supprimées:"
        echo "  - PSX_UUID_V4"
        echo "  - PS_ACCOUNTS_* (toutes les clés ps_accounts)"
        echo "  - PS_CHECKOUT_SHOP_UUID_V4"
        echo "  - PS_PSX_* (toutes les clés ps_psx)"
        echo ""
        info "Le module ps_accounts reste installé mais ses données de configuration ont été vidées"
        info "Vous pouvez maintenant reconfigurer le module depuis le back-office"
    else
        error "Échec de la suppression des données de configuration"
        echo "$reset_output" | tail -10 >&2
        return 1
    fi
    
    return 0
}

