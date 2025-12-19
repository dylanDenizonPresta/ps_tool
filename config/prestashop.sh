#!/bin/sh

# Configuration des versions et URLs de PrestaShop
# Ce fichier contient les informations pour télécharger et installer PrestaShop

# Version par défaut (dernière version stable)
PRESTASHOP_DEFAULT_VERSION="9.0.2"

# Fonction pour obtenir l'URL d'une version (compatible sh)
get_prestashop_url() {
    local version="${1:-$PRESTASHOP_DEFAULT_VERSION}"
    case "$version" in
        # Versions 9.x
        "9.0.2")
            echo "https://assets.prestashop3.com/dst/edition/corporate/9.0.2-2.1/prestashop_edition_basic_version_9.0.2-2.1.zip"
            ;;
        "9.0.1")
            echo "https://github.com/PrestaShop/PrestaShop/archive/refs/tags/9.0.1.zip"
            ;;
        "9.0.0")
            echo "https://github.com/PrestaShop/PrestaShop/archive/refs/tags/9.0.0.zip"
            ;;
        # Versions 8.2.x
        "8.2.3")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.2.3/prestashop_8.2.3.zip"
            ;;
        "8.2.2")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.2.2/prestashop_8.2.2.zip"
            ;;
        "8.2.1")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.2.1/prestashop_8.2.1.zip"
            ;;
        "8.2.0")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.2.0/prestashop_8.2.0.zip"
            ;;
        # Versions 8.1.x
        "8.1.7")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.1.7/prestashop_8.1.7.zip"
            ;;
        "8.1.6")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.1.6/prestashop_8.1.6.zip"
            ;;
        "8.1.5")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.1.5/prestashop_8.1.5.zip"
            ;;
        "8.1.4")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.1.4/prestashop_8.1.4.zip"
            ;;
        "8.1.3")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.1.3/prestashop_8.1.3.zip"
            ;;
        "8.1.2")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.1.2/prestashop_8.1.2.zip"
            ;;
        "8.1.1")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.1.1/prestashop_8.1.1.zip"
            ;;
        "8.1.0")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.1.0/prestashop_8.1.0.zip"
            ;;
        # Versions 8.0.x
        "8.0.7")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.0.7/prestashop_8.0.7.zip"
            ;;
        "8.0.6")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.0.6/prestashop_8.0.6.zip"
            ;;
        "8.0.5")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.0.5/prestashop_8.0.5.zip"
            ;;
        "8.0.4")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.0.4/prestashop_8.0.4.zip"
            ;;
        "8.0.3")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.0.3/prestashop_8.0.3.zip"
            ;;
        "8.0.2")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.0.2/prestashop_8.0.2.zip"
            ;;
        "8.0.1")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.0.1/prestashop_8.0.1.zip"
            ;;
        "8.0.0")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/8.0.0/prestashop_8.0.0.zip"
            ;;
        # Versions 1.7.x
        "1.7.8.10")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/1.7.8.10/prestashop_1.7.8.10.zip"
            ;;
        "1.7.8.9")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/1.7.8.9/prestashop_1.7.8.9.zip"
            ;;
        "1.7.8.8")
            echo "https://github.com/PrestaShop/PrestaShop/releases/download/1.7.8.8/prestashop_1.7.8.8.zip"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Fonction pour vérifier si une version existe
prestashop_version_exists() {
    local version="$1"
    local url=$(get_prestashop_url "$version")
    [ -n "$url" ]
}

# Fonction pour obtenir la version PHP requise pour une version de PrestaShop
get_prestashop_php_version() {
    local version="${1:-$PRESTASHOP_DEFAULT_VERSION}"
    case "$version" in
        # Versions 9.x nécessitent PHP 8.2
        "9.0.2"|"9.0.1"|"9.0.0")
            echo "8.2"
            ;;
        # Versions 8.x nécessitent PHP 8.1
        "8.2.3"|"8.2.2"|"8.2.1"|"8.2.0"|"8.1.7"|"8.1.6"|"8.1.5"|"8.1.4"|"8.1.3"|"8.1.2"|"8.1.1"|"8.1.0"|"8.0.7"|"8.0.6"|"8.0.5"|"8.0.4"|"8.0.3"|"8.0.2"|"8.0.1"|"8.0.0")
            echo "8.1"
            ;;
        # Versions 1.7.x nécessitent PHP 7.4 ou 8.0
        "1.7.8.10"|"1.7.8.9"|"1.7.8.8")
            echo "8.0"
            ;;
        *)
            # Par défaut, utiliser PHP 8.1
            echo "8.1"
            ;;
    esac
}

# Fonction pour lister toutes les versions disponibles
list_prestashop_versions() {
    echo "9.0.2"
    echo "9.0.1"
    echo "9.0.0"
    echo "8.2.3"
    echo "8.2.2"
    echo "8.2.1"
    echo "8.2.0"
    echo "8.1.7"
    echo "8.1.6"
    echo "8.1.5"
    echo "8.1.4"
    echo "8.1.3"
    echo "8.1.2"
    echo "8.1.1"
    echo "8.1.0"
    echo "8.0.7"
    echo "8.0.6"
    echo "8.0.5"
    echo "8.0.4"
    echo "8.0.3"
    echo "8.0.2"
    echo "8.0.1"
    echo "8.0.0"
    echo "1.7.8.10"
    echo "1.7.8.9"
    echo "1.7.8.8"
}

