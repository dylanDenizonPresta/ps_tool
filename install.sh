#!/bin/bash

# Script d'installation de ps_tool

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

# Répertoire d'installation par défaut
INSTALL_DIR="${HOME}/.ps_tool"
BIN_DIR="/usr/local/bin"

info "Installation de ps_tool..."

# Déterminer le répertoire source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "Installation depuis: $SCRIPT_DIR"

# Créer le répertoire d'installation
info "Création du répertoire d'installation: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Copier les fichiers (sans le dossier .git)
info "Copie des fichiers..."
cp -R "$SCRIPT_DIR"/* "$INSTALL_DIR/" 2>/dev/null || true

# Rendre le script principal exécutable
chmod +x "$INSTALL_DIR/ps_tool"

# Créer le lien symbolique dans /usr/local/bin
info "Création du lien symbolique dans $BIN_DIR..."

# Vérifier si /usr/local/bin existe, sinon le créer
if [ ! -d "$BIN_DIR" ]; then
    info "Création du répertoire $BIN_DIR..."
    sudo mkdir -p "$BIN_DIR"
fi

# Supprimer l'ancien lien s'il existe
if [ -L "$BIN_DIR/ps_tool" ] || [ -f "$BIN_DIR/ps_tool" ]; then
    warning "Un lien/binaire ps_tool existe déjà, suppression..."
    sudo rm -f "$BIN_DIR/ps_tool"
fi

# Créer le nouveau lien symbolique
sudo ln -s "$INSTALL_DIR/ps_tool" "$BIN_DIR/ps_tool"

# Définir la variable d'environnement pour le répertoire d'installation
# Ajouter à ~/.zshrc si elle n'existe pas déjà
if ! grep -q "PS_TOOL_INSTALL_DIR" ~/.zshrc 2>/dev/null; then
    info "Ajout de PS_TOOL_INSTALL_DIR à ~/.zshrc..."
    echo "" >> ~/.zshrc
    echo "# ps_tool configuration" >> ~/.zshrc
    echo "export PS_TOOL_INSTALL_DIR=\"$INSTALL_DIR\"" >> ~/.zshrc
fi

# Exporter pour la session actuelle
export PS_TOOL_INSTALL_DIR="$INSTALL_DIR"

success "ps_tool installé avec succès !"
echo ""
info "Vous pouvez maintenant utiliser: ps_tool <command>"
info "Essayez: ps_tool help"
echo ""
info "Pour voir les outils disponibles: ps_tool list"

