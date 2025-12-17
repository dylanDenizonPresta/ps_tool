#!/bin/bash

# Commande version - Affiche la version actuelle

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
# On doit d'abord trouver le répertoire pour charger les fichiers
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/config.sh"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

cmd_version() {
    echo "ps_tool version $PS_TOOL_VERSION"
    echo "Répertoire d'installation: $PS_TOOL_INSTALL_DIR"
    
    # Afficher le commit Git si disponible
    if is_git_repo "$PS_TOOL_INSTALL_DIR"; then
        local original_dir=$(pwd)
        cd "$PS_TOOL_INSTALL_DIR" || exit 1
        local git_commit=$(git rev-parse --short HEAD 2>/dev/null)
        local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -n "$git_commit" ]; then
            echo "Commit: $git_commit (branche: $git_branch)"
        fi
        cd "$original_dir"
    fi
}

