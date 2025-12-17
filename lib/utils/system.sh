#!/bin/bash

# Utilitaires système et détection d'environnement

# Fonction pour vérifier si on est sur macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Fonction pour vérifier si le répertoire est un repo git
is_git_repo() {
    [ -d "$1/.git" ]
}

# Fonction pour vérifier si une fonction existe
function_exists() {
    declare -f "$1" > /dev/null
}

# Fonction pour initialiser SCRIPT_DIR
# Usage: init_script_dir [niveau]
# niveau: nombre de niveaux à remonter depuis le fichier appelant
#   - 2 pour lib/commands/ (défaut)
#   - 1 pour commands/
#   - 0 pour fichiers à la racine
init_script_dir() {
    local levels="${1:-2}"
    
    # Si SCRIPT_DIR est déjà défini, ne rien faire
    if [ -n "$SCRIPT_DIR" ]; then
        return 0
    fi
    
    # Trouver le fichier appelant
    # BASH_SOURCE[2] car:
    #   [0] = utils.sh (ce fichier)
    #   [1] = le fichier qui a chargé utils.sh (ex: shop.sh)
    #   [2] = le fichier qui a appelé init_script_dir (si appelé depuis un autre script)
    local script_path="${BASH_SOURCE[2]}"
    
    # Si pas trouvé, utiliser BASH_SOURCE[1] (fichier qui a chargé utils.sh)
    if [ -z "$script_path" ]; then
        script_path="${BASH_SOURCE[1]}"
    fi
    
    # Si toujours pas trouvé, utiliser BASH_SOURCE[0] (fichier courant)
    if [ -z "$script_path" ]; then
        script_path="${BASH_SOURCE[0]}"
    fi
    
    # Construire le chemin en remontant les niveaux spécifiés
    local dir_path="$(cd "$(dirname "$script_path")" && pwd)"
    local i=0
    while [ $i -lt $levels ]; do
        dir_path="$(cd "$dir_path/.." && pwd)"
        i=$((i + 1))
    done
    SCRIPT_DIR="$dir_path"
    
    # Si SCRIPT_DIR pointe vers /usr/local/bin ou /usr/bin, utiliser PS_TOOL_INSTALL_DIR
    if [ "$SCRIPT_DIR" = "/usr/local/bin" ] || [ "$SCRIPT_DIR" = "/usr/bin" ]; then
        if [ -n "$PS_TOOL_INSTALL_DIR" ] && [ -d "$PS_TOOL_INSTALL_DIR" ]; then
            SCRIPT_DIR="$PS_TOOL_INSTALL_DIR"
        else
            # Fallback vers le répertoire par défaut
            SCRIPT_DIR="${HOME}/.ps_tool"
        fi
    fi
    
    export SCRIPT_DIR
}

