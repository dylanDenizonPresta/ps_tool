#!/bin/bash

# Script de vérification des prérequis pour ps_tool

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs
PASSED=0
FAILED=0
WARNINGS=0

# Fonction pour afficher un message de succès
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED=$((PASSED + 1))
}

# Fonction pour afficher un message d'erreur
check_fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED=$((FAILED + 1))
}

# Fonction pour afficher un avertissement
check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# Fonction pour afficher une information
check_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Fonction pour vérifier si une commande existe
check_command() {
    local cmd="$1"
    local name="${2:-$cmd}"
    local required="${3:-true}"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        local version=""
        case "$cmd" in
            bash)
                version=" ($(bash --version | head -n1 | cut -d' ' -f4 | cut -d'(' -f1))"
                ;;
            ddev)
                version=" ($(ddev version --short 2>/dev/null || echo "version inconnue"))"
                ;;
            git)
                version=" ($(git --version | cut -d' ' -f3))"
                ;;
            curl)
                version=" ($(curl --version | head -n1 | cut -d' ' -f2))"
                ;;
            wget)
                version=" ($(wget --version | head -n1 | cut -d' ' -f3))"
                ;;
            unzip)
                version=" ($(unzip -v 2>/dev/null | head -n1 | cut -d' ' -f2 || echo ""))"
                ;;
        esac
        check_pass "$name est installé$version"
        return 0
    else
        if [ "$required" = "true" ]; then
            check_fail "$name n'est pas installé"
            return 1
        else
            check_warn "$name n'est pas installé (optionnel)"
            return 1
        fi
    fi
}




# Afficher l'en-tête
echo ""
echo "=========================================="
echo "  Vérification des prérequis pour ps_tool"
echo "=========================================="
echo ""

# Vérifier le système d'exploitation
check_info "Système d'exploitation: $(uname -s)"
check_info "Architecture: $(uname -m)"

# Vérifier les outils requis
echo ""
echo "--- Outils requis ---"
check_command "curl" "curl" true
check_command "wget" "wget" false  # Optionnel si curl est présent
check_command "unzip" "unzip" true

# Vérifier ddev
echo ""
echo "--- Outils de développement ---"
if check_command "ddev" "ddev" false; then
    # Vérifier si ddev est fonctionnel
    if ddev version >/dev/null 2>&1; then
        check_pass "ddev est fonctionnel"
    else
        check_warn "ddev est installé mais ne semble pas fonctionner correctement"
    fi
else
        check_info "Installez ddev manuellement avec Homebrew: brew install ddev/ddev/ddev"
fi

# Vérifier Git (optionnel mais recommandé)
check_command "git" "Git" false

# Vérifier les variables d'environnement
echo ""
echo "--- Variables d'environnement ---"
if [ -n "$PS_TOOL_INSTALL_DIR" ]; then
    check_info "PS_TOOL_INSTALL_DIR est défini: $PS_TOOL_INSTALL_DIR"
    if [ -d "$PS_TOOL_INSTALL_DIR" ]; then
        check_pass "PS_TOOL_INSTALL_DIR existe et est accessible"
    else
        check_fail "PS_TOOL_INSTALL_DIR pointe vers un répertoire inexistant"
    fi
else
    check_info "PS_TOOL_INSTALL_DIR n'est pas défini (utilisation du répertoire par défaut)"
fi

if [ -n "$PS_TOOL_WORK_DIR" ]; then
    check_info "PS_TOOL_WORK_DIR est défini: $PS_TOOL_WORK_DIR"
    if [ -d "$PS_TOOL_WORK_DIR" ]; then
        check_pass "PS_TOOL_WORK_DIR existe et est accessible"
    else
        check_warn "PS_TOOL_WORK_DIR pointe vers un répertoire inexistant"
    fi
fi

# Résumé
echo ""
echo "=========================================="
echo "  Résumé"
echo "=========================================="
echo -e "${GREEN}✓ Réussis:${NC} $PASSED"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ Avertissements:${NC} $WARNINGS"
fi
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}✗ Échecs:${NC} $FAILED"
fi
echo ""

# Code de sortie
if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        check_pass "Tous les prérequis sont satisfaits !"
        echo ""
        exit 0
    else
        check_warn "Les prérequis essentiels sont satisfaits, mais certains éléments optionnels manquent."
        echo ""
        exit 0
    fi
else
    check_fail "Certains prérequis essentiels manquent. Veuillez les installer avant d'utiliser ps_tool."
    echo ""
    exit 1
fi

