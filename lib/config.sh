#!/bin/bash

# Configuration du CLI ps_tool

# Version du CLI
PS_TOOL_VERSION="1.0.0"

# Répertoire d'installation (sera défini lors de l'installation)
PS_TOOL_INSTALL_DIR="${PS_TOOL_INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# URL du repository GitHub
PS_TOOL_GIT_REPO="${PS_TOOL_GIT_REPO:-https://github.com/USERNAME/ps_tool.git}"

# Répertoire de configuration utilisateur
PS_TOOL_CONFIG_DIR="${HOME}/.ps_tool"

# Fichier de configuration
PS_TOOL_CONFIG_FILE="${PS_TOOL_CONFIG_DIR}/config"

# Fichier de registre des shops créés
PS_TOOL_SHOPS_REGISTRY="${PS_TOOL_CONFIG_DIR}/shops.txt"

# Créer le répertoire de configuration s'il n'existe pas
mkdir -p "${PS_TOOL_CONFIG_DIR}"

