#!/bin/bash

# Fonctions d'exécution de commandes et interactions utilisateur

# Fonction pour exécuter une commande avec logging
run_command() {
    local cmd="$1"
    local description="${2:-Exécution de la commande}"
    
    info "$description..."
    if eval "$cmd"; then
        success "$description terminé"
        return 0
    else
        error "Échec: $description"
        return 1
    fi
}

# Fonction pour exécuter une commande nécessitant sudo
run_sudo() {
    local cmd="$1"
    local description="${2:-Exécution de la commande avec sudo}"
    
    info "$description (nécessite sudo)..."
    if sudo bash -c "$cmd"; then
        success "$description terminé"
        return 0
    else
        error "Échec: $description"
        return 1
    fi
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour demander confirmation à l'utilisateur
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        local options="[Y/n]"
    else
        local options="[y/N]"
    fi
    
    read -p "$prompt $options: " response
    response=${response:-$default}
    
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

