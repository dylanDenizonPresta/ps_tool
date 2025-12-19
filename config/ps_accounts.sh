#!/bin/sh

# Configuration des versions et URLs du module ps_accounts
# Ce fichier contient les informations pour télécharger et installer le module ps_accounts
# Module: PrestaShop Accounts
# Repository: https://github.com/PrestaShopCorp/ps_accounts

# Version par défaut (dernière version stable)
PS_ACCOUNTS_DEFAULT_VERSION="8.0.8"

# Fonction pour obtenir l'URL d'une version de ps_accounts selon l'environnement (compatible sh)
get_ps_accounts_url() {
    local version="${1:-$PS_ACCOUNTS_DEFAULT_VERSION}"
    local environment="${2:-PROD}"
    
    case "$version" in
        "8.0.8")
            if [ "$environment" = "PREPROD" ]; then
                echo "https://github.com/PrestaShopCorp/ps_accounts/releases/download/v8.0.8/ps_accounts_preprod-8.0.8.zip"
            else
                echo "https://github.com/PrestaShopCorp/ps_accounts/releases/download/v8.0.8/ps_accounts-8.0.8.zip"
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# Fonction pour obtenir la version recommandée de ps_accounts selon la version de PrestaShop
get_ps_accounts_version_for_prestashop() {
    local prestashop_version="$1"
    case "$prestashop_version" in
        # PrestaShop 9.x -> ps_accounts v2.x
        "9.0.2"|"9.0.1"|"9.0.0"|"8.2.3"|"8.2.2"|"8.2.1"|"8.2.0"|"8.1.7"|"8.1.6"|"8.1.5"|"8.1.4"|"8.1.3"|"8.1.2"|"8.1.1"|"8.1.0"|"8.0.7"|"8.0.6"|"8.0.5"|"8.0.4"|"8.0.3"|"8.0.2"|"8.0.1"|"8.0.0"|"1.7.8.10"|"1.7.8.9"|"1.7.8.8"|"1.7.7"|"1.7.8")
            echo "8.0.8"
            ;;
        *)
            # Par défaut, utiliser la version par défaut
            echo "$PS_ACCOUNTS_DEFAULT_VERSION"
            ;;
    esac
}

# Fonction pour vérifier si une version existe
ps_accounts_version_exists() {
    local version="$1"
    local url=$(get_ps_accounts_url "$version")
    [ -n "$url" ]
}

# Fonction pour lister toutes les versions disponibles
list_ps_accounts_versions() {
    echo "8.0.8"
}

