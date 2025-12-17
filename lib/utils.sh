#!/bin/bash

# Fichier principal des utilitaires ps_tool
# Charge tous les modules dans le bon ordre de dépendance

# Déterminer le répertoire du script pour charger les modules
# Si SCRIPT_DIR n'est pas défini, on essaie de le déterminer
if [ -z "$SCRIPT_DIR" ]; then
    # Utiliser BASH_SOURCE[0] pour trouver le répertoire de ce fichier
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Si SCRIPT_DIR pointe vers /usr/local/bin ou /usr/bin, utiliser PS_TOOL_INSTALL_DIR
    if [ "$SCRIPT_DIR" = "/usr/local/bin" ] || [ "$SCRIPT_DIR" = "/usr/bin" ]; then
        if [ -n "$PS_TOOL_INSTALL_DIR" ] && [ -d "$PS_TOOL_INSTALL_DIR" ]; then
            SCRIPT_DIR="$PS_TOOL_INSTALL_DIR"
        else
            # Fallback vers le répertoire par défaut
            SCRIPT_DIR="${HOME}/.ps_tool"
        fi
    fi
fi

# Charger les modules dans l'ordre de dépendance
# 1. logging.sh - fonctions de base (pas de dépendances)
if [ -f "${SCRIPT_DIR}/lib/utils/logging.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/logging.sh"
fi

# 2. commands.sh - dépend de logging
if [ -f "${SCRIPT_DIR}/lib/utils/commands.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/commands.sh"
fi

# 3. system.sh - dépend de commands et logging
if [ -f "${SCRIPT_DIR}/lib/utils/system.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/system.sh"
fi

# 4. shops.sh - dépend de system, commands, logging
if [ -f "${SCRIPT_DIR}/lib/utils/shops.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/shops.sh"
fi

# 5. ports.sh - dépend de shops, commands, logging
if [ -f "${SCRIPT_DIR}/lib/utils/ports.sh" ]; then
    source "${SCRIPT_DIR}/lib/utils/ports.sh"
fi
