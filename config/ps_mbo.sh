#!/bin/sh

# Configuration des versions et URLs du module ps_mbo
# Ce fichier contient les informations pour télécharger et installer le module ps_mbo
# Module: PrestaShop Marketplace in your Back Office (MBO)
# Repository: https://github.com/PrestaShopCorp/ps_mbo

# Version par défaut (dernière version stable pour PrestaShop 9.x)
PS_MBO_DEFAULT_VERSION="5.2.1"

# Fonction pour obtenir l'URL d'une version de ps_mbo (compatible sh)
get_ps_mbo_url() {
    local version="${1:-$PS_MBO_DEFAULT_VERSION}"
    case "$version" in
        # Versions 5.x (PrestaShop 9.x)
        "5.2.1")
            echo "https://github.com/PrestaShopCorp/ps_mbo/releases/download/v5.2.1/ps_mbo.zip"
            ;;
        # Versions 4.x (PrestaShop 8.x)
        "4.14.1")
            echo "https://github.com/PrestaShopCorp/ps_mbo/releases/download/v4.14.1/ps_mbo_v4.14.1.zip"
            ;;
        "4.13.4")
            echo "https://github.com/PrestaShopCorp/ps_mbo/releases/download/v4.13.4/ps_mbo_v4.13.4.zip"
            ;;
        # Versions 3.x (PrestaShop 1.7.7 & 1.7.8)
        "3.3.1")
            echo "https://github.com/PrestaShopCorp/ps_mbo/releases/download/v3.3.1/ps_mbo.zip"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Fonction pour obtenir la version recommandée de ps_mbo selon la version de PrestaShop
get_ps_mbo_version_for_prestashop() {
    local prestashop_version="$1"
    case "$prestashop_version" in
        # PrestaShop 9.x -> ps_mbo v5.x
        "9.0.2"|"9.0.1"|"9.0.0")
            echo "5.2.1"
            ;;
        # PrestaShop 8.x -> ps_mbo v4.x
        "8.2.3"|"8.2.2"|"8.2.1"|"8.2.0")
            echo "4.14.1"
            ;;
        "8.1.7"|"8.1.6"|"8.1.5"|"8.1.4"|"8.1.3"|"8.1.2"|"8.1.1"|"8.1.0"|"8.0.7"|"8.0.6"|"8.0.5"|"8.0.4"|"8.0.3"|"8.0.2"|"8.0.1"|"8.0.0")
            echo "4.13.4"
            ;;
        # PrestaShop 1.7.x -> ps_mbo v3.x
        "1.7.8.10"|"1.7.8.9"|"1.7.8.8"|"1.7.7"|"1.7.8")
            echo "3.3.1"
            ;;
        *)
            # Par défaut, utiliser la version pour PrestaShop 9.x
            echo "$PS_MBO_DEFAULT_VERSION"
            ;;
    esac
}

# Fonction pour vérifier si une version existe
ps_mbo_version_exists() {
    local version="$1"
    local url=$(get_ps_mbo_url "$version")
    [ -n "$url" ]
}

# Fonction pour lister toutes les versions disponibles
list_ps_mbo_versions() {
    echo "5.2.1"
    echo "5.2.0"
    echo "5.1.1"
    echo "5.1.0"
    echo "5.0.1"
    echo "5.0.0"
    echo "4.14.1"
    echo "4.14.0"
    echo "4.13.4"
    echo "4.13.3"
    echo "4.13.2"
    echo "4.13.1"
    echo "4.13.0"
    echo "4.12.4"
    echo "4.12.3"
    echo "4.12.2"
    echo "4.12.1"
    echo "4.12.0"
    echo "4.11.4"
    echo "4.11.3"
    echo "4.11.2"
    echo "4.11.1"
    echo "4.11.0"
    echo "4.10.4"
    echo "4.10.3"
    echo "4.10.2"
    echo "4.10.1"
    echo "4.10.0"
    echo "4.9.4"
    echo "4.9.3"
    echo "4.9.2"
    echo "4.9.1"
    echo "4.9.0"
    echo "4.8.4"
    echo "4.8.3"
    echo "4.8.2"
    echo "4.8.1"
    echo "4.8.0"
    echo "4.7.4"
    echo "4.7.3"
    echo "4.7.2"
    echo "4.7.1"
    echo "4.7.0"
    echo "4.6.1"
    echo "4.6.0"
    echo "4.5.1"
    echo "4.5.0"
    echo "4.4.1"
    echo "4.4.0"
    echo "4.3.1"
    echo "4.3.0"
    echo "4.2.1"
    echo "4.2.0"
    echo "4.1.1"
    echo "4.1.0"
    echo "4.0.1"
    echo "4.0.0"
    echo "3.3.1"
    echo "3.3.0"
    echo "3.2.1"
    echo "3.2.0"
    echo "3.1.1"
    echo "3.1.0"
    echo "3.0.1"
    echo "3.0.0"
}
