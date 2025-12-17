#!/bin/bash

# Installation de ddev

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
# On doit d'abord trouver le répertoire pour charger utils.sh
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 1

# Installation de ddev
install_ddev() {
    if command_exists ddev; then
        info "ddev est déjà installé"
        ddev version
        return 0
    fi

    info "Installation de ddev..."
    
    # Vérifier que Homebrew est installé
    if ! command_exists brew; then
        error "Homebrew n'est pas installé"
        error "Veuillez installer Homebrew manuellement avant de continuer"
        return 1
    fi

    # Installer ddev via Homebrew
    info "Installation de ddev via Homebrew..."
    if run_command "brew install ddev/ddev/ddev"; then
        success "ddev installé avec succès"
        info "Vous devrez peut-être redémarrer votre terminal pour utiliser ddev"
        return 0
    else
        error "Échec de l'installation de ddev"
        return 1
    fi
}

