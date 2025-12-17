#!/bin/bash

# Script de désinstallation de ps_tool

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

# Répertoires et fichiers à supprimer
INSTALL_DIR="${PS_TOOL_INSTALL_DIR:-${HOME}/.ps_tool}"
BIN_DIR="/usr/local/bin"
BIN_LINK="$BIN_DIR/ps_tool"

info "Désinstallation de ps_tool..."

# Demander confirmation
warning "Cette action va supprimer:"
echo "  - Le lien symbolique: $BIN_LINK"
echo "  - Le répertoire d'installation: $INSTALL_DIR"
echo "  - La configuration dans ~/.zshrc (ligne PS_TOOL_INSTALL_DIR)"
echo ""
read -p "Êtes-vous sûr de vouloir continuer ? [y/N]: " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Désinstallation annulée"
    exit 0
fi

# Supprimer le lien symbolique
if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
    info "Suppression du lien symbolique: $BIN_LINK"
    if sudo rm -f "$BIN_LINK" 2>/dev/null; then
        success "Lien symbolique supprimé"
    else
        error "Impossible de supprimer le lien symbolique (peut nécessiter sudo)"
        warning "Essayez manuellement: sudo rm -f $BIN_LINK"
    fi
else
    info "Aucun lien symbolique trouvé dans $BIN_LINK"
fi

# Supprimer le répertoire d'installation
if [ -d "$INSTALL_DIR" ]; then
    info "Suppression du répertoire d'installation: $INSTALL_DIR"
    warning "Ceci supprimera également tous les shops enregistrés dans le registre"
    
    read -p "Voulez-vous supprimer le répertoire d'installation ? [y/N]: " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if rm -rf "$INSTALL_DIR" 2>/dev/null; then
            success "Répertoire d'installation supprimé"
        else
            error "Impossible de supprimer le répertoire d'installation: $INSTALL_DIR"
            warning "Essayez manuellement: rm -rf $INSTALL_DIR"
        fi
    else
        info "Conservation du répertoire d'installation: $INSTALL_DIR"
    fi
else
    info "Aucun répertoire d'installation trouvé dans: $INSTALL_DIR"
fi

# Retirer la configuration de ~/.zshrc
if [ -f ~/.zshrc ]; then
    if grep -q "PS_TOOL_INSTALL_DIR" ~/.zshrc 2>/dev/null; then
        info "Suppression de la configuration dans ~/.zshrc..."
        
        # Créer une sauvegarde
        cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        
        # Supprimer les lignes liées à ps_tool
        if sed -i.bak '/# ps_tool configuration/,+1d' ~/.zshrc 2>/dev/null || \
           sed -i '' '/# ps_tool configuration/,+1d' ~/.zshrc 2>/dev/null || \
           grep -v "PS_TOOL_INSTALL_DIR" ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc; then
            success "Configuration retirée de ~/.zshrc"
            rm -f ~/.zshrc.bak 2>/dev/null || true
        else
            warning "Impossible de modifier ~/.zshrc automatiquement"
            info "Veuillez retirer manuellement les lignes contenant 'PS_TOOL_INSTALL_DIR' de ~/.zshrc"
        fi
    else
        info "Aucune configuration ps_tool trouvée dans ~/.zshrc"
    fi
fi

# Retirer la configuration de ~/.bashrc si elle existe
if [ -f ~/.bashrc ]; then
    if grep -q "PS_TOOL_INSTALL_DIR" ~/.bashrc 2>/dev/null; then
        info "Suppression de la configuration dans ~/.bashrc..."
        
        # Créer une sauvegarde
        cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        
        # Supprimer les lignes liées à ps_tool
        if sed -i.bak '/# ps_tool configuration/,+1d' ~/.bashrc 2>/dev/null || \
           sed -i '' '/# ps_tool configuration/,+1d' ~/.bashrc 2>/dev/null || \
           grep -v "PS_TOOL_INSTALL_DIR" ~/.bashrc > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc; then
            success "Configuration retirée de ~/.bashrc"
            rm -f ~/.bashrc.bak 2>/dev/null || true
        else
            warning "Impossible de modifier ~/.bashrc automatiquement"
            info "Veuillez retirer manuellement les lignes contenant 'PS_TOOL_INSTALL_DIR' de ~/.bashrc"
        fi
    fi
fi

# Retirer la configuration de ~/.bash_profile si elle existe
if [ -f ~/.bash_profile ]; then
    if grep -q "PS_TOOL_INSTALL_DIR" ~/.bash_profile 2>/dev/null; then
        info "Suppression de la configuration dans ~/.bash_profile..."
        
        # Créer une sauvegarde
        cp ~/.bash_profile ~/.bash_profile.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        
        # Supprimer les lignes liées à ps_tool
        if sed -i.bak '/# ps_tool configuration/,+1d' ~/.bash_profile 2>/dev/null || \
           sed -i '' '/# ps_tool configuration/,+1d' ~/.bash_profile 2>/dev/null || \
           grep -v "PS_TOOL_INSTALL_DIR" ~/.bash_profile > ~/.bash_profile.tmp && mv ~/.bash_profile.tmp ~/.bash_profile; then
            success "Configuration retirée de ~/.bash_profile"
            rm -f ~/.bash_profile.bak 2>/dev/null || true
        else
            warning "Impossible de modifier ~/.bash_profile automatiquement"
            info "Veuillez retirer manuellement les lignes contenant 'PS_TOOL_INSTALL_DIR' de ~/.bash_profile"
        fi
    fi
fi

success "Désinstallation terminée !"
echo ""
info "Pour réinstaller ps_tool, exécutez: ./install.sh"
info "Note: Vous devrez peut-être redémarrer votre terminal pour que les changements prennent effet"

