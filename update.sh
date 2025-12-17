#!/bin/bash

# Script de mise à jour de ps_tool
# Ce script peut être exécuté directement pour mettre à jour le CLI

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Répertoire d'installation par défaut
INSTALL_DIR="${PS_TOOL_INSTALL_DIR:-${HOME}/.ps_tool}"

info "Mise à jour de ps_tool..."

# Vérifier si le répertoire d'installation existe
if [ ! -d "$INSTALL_DIR" ]; then
    error "Le répertoire d'installation n'existe pas: $INSTALL_DIR"
    error "Le CLI n'est peut-être pas installé. Utilisez ./install.sh pour l'installer."
    exit 1
fi

warning "La fonctionnalité de mise à jour via Git n'est pas activée pour le moment"
info ""
info "Pour mettre à jour le CLI:"
info "  1. Réinstallez-le avec ./install.sh"
info "  2. Ou copiez manuellement les nouveaux fichiers dans: $INSTALL_DIR"
info ""
info "Répertoire d'installation: $INSTALL_DIR"
exit 0

