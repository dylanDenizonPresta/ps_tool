#!/bin/bash

# Réinstallation d'une shop PrestaShop existante

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
# On doit d'abord trouver le répertoire pour charger utils.sh
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 2

# Charger la configuration PrestaShop
if [ -f "${SCRIPT_DIR}/config/prestashop.sh" ]; then
    source "${SCRIPT_DIR}/config/prestashop.sh"
fi

# Commande pour réinstaller un shop PrestaShop
cmd_shop_reinstall() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Réinstaller un shop PrestaShop existant

Usage:
    ps_tool shop reinstall <nom_shop> [nouvelle_version] [options]

Arguments:
    nom_shop            Nom du shop à réinstaller
    nouvelle_version    Nouvelle version de PrestaShop (optionnel)
                        Par défaut: conserve la version actuelle du shop

Options:
    --admin-email <email>        Email de l'administrateur (défaut: admin@prestashop.com)
    --admin-password <password>  Mot de passe admin (défaut: presta123)
    --shop-name <name>           Nom de la boutique (défaut: nom du shop)
    --country <code>             Code pays ISO (défaut: FR)
    --language <code>            Code langue (défaut: fr)
    --timezone <timezone>        Fuseau horaire (défaut: Europe/Paris)
    --currency <code>            Code devise (défaut: EUR)
    --ssl                        Activer SSL/HTTPS (défaut: activé)
    --no-fixtures                Ne pas installer les produits/données de démonstration
    --from-zip <chemin>          Réinstaller depuis un fichier zip local
    -m, --manual                 Installation manuelle via l'interface web
    --force, -f                  Ne pas demander de confirmation
    --help, -h                   Afficher cette aide

Exemples:
    ps_tool shop reinstall shop18
    ps_tool shop reinstall shop18 9.0.2
    ps_tool shop reinstall shop18 --admin-email admin@example.com
    ps_tool shop reinstall shop18 --from-zip /path/to/prestashop.zip
    ps_tool shop reinstall shop18 --force

La commande va:
    1. Récupérer les informations du shop (chemin, ports, version)
    2. Arrêter et supprimer les conteneurs ddev (base de données incluse)
    3. Supprimer les fichiers PrestaShop (la configuration ddev est conservée)
    4. Mettre à jour la version PHP si la version PrestaShop change
    5. Réinstaller PrestaShop avec une base de données vide
    6. Relancer l'installation CLI automatiquement

Note: Les ports ddev du shop sont conservés lors de la réinstallation.
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            exit 0
        else
            exit 1
        fi
    fi

    local shop_name="$1"
    shift

    # Récupérer les informations du shop depuis le registre
    local shop_path
    shop_path=$(get_shop_path "$shop_name")

    if [ -z "$shop_path" ]; then
        error "Shop non trouvé: $shop_name"
        info "Listez les shops disponibles avec: ps_tool shop list"
        exit 1
    fi

    if [ ! -d "$shop_path" ]; then
        error "Le répertoire du shop n'existe plus: $shop_path"
        info "Le shop a peut-être été supprimé manuellement"
        exit 1
    fi

    # Récupérer la version actuelle et les ports depuis le registre
    local current_version
    current_version=$(get_shop_prestashop_version "$shop_name")

    local registry_ports
    registry_ports=$(get_shop_ports_from_registry "$shop_name")
    local current_http_port
    current_http_port=$(echo "$registry_ports" | cut -d'|' -f1)
    local current_https_port
    current_https_port=$(echo "$registry_ports" | cut -d'|' -f2)

    # Fallback : lire les ports depuis .ddev/config.yaml si absents du registre
    if [ -z "$current_http_port" ] && [ -f "$shop_path/.ddev/config.yaml" ]; then
        current_http_port=$(grep -E "^router_http_port:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")
        current_https_port=$(grep -E "^router_https_port:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")
    fi

    # Parser les options
    local new_version="${current_version:-$PRESTASHOP_DEFAULT_VERSION}"
    local force=false
    local extra_args=()

    while [ $# -gt 0 ]; do
        case "$1" in
            --force|-f)
                force=true
                shift
                ;;
            --help|-h)
                exit 0
                ;;
            *)
                # Intercepter la version PS (X.Y.Z ou X.Y.Z.W)
                if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                    new_version="$1"
                else
                    # Transmettre les autres options à l'installeur
                    extra_args+=("$1")
                fi
                shift
                ;;
        esac
    done

    # Afficher les informations de la réinstallation
    info "Shop à réinstaller : $shop_name"
    info "Répertoire         : $shop_path"
    if [ -n "$current_version" ]; then
        if [ "$new_version" != "$current_version" ]; then
            info "Version actuelle   : $current_version  →  Nouvelle version : $new_version"
        else
            info "Version            : $new_version (inchangée)"
        fi
    else
        info "Version cible      : $new_version"
    fi
    if [ -n "$current_http_port" ]; then
        info "Ports conservés    : HTTP:$current_http_port, HTTPS:$current_https_port"
    fi
    echo ""
    warning "ATTENTION: Cette opération va :"
    warning "  • Supprimer tous les fichiers PrestaShop"
    warning "  • Détruire la base de données (toutes les données seront perdues)"
    warning "  • Conserver uniquement la configuration ddev (.ddev/)"
    echo ""

    # Demander confirmation
    if [ "$force" = false ]; then
        if ! confirm "Voulez-vous vraiment réinstaller ce shop ?"; then
            info "Réinstallation annulée"
            exit 0
        fi
    fi

    # ─── Étape 1 : Suppression des conteneurs et de la base de données ────────

    info "Suppression des conteneurs ddev et de la base de données..."
    if command_exists ddev; then
        # ddev delete supprime les conteneurs et volumes (DB incluse)
        # mais conserve le dossier .ddev et les fichiers du projet
        if (cd "$shop_path" && ddev delete --omit-snapshot --yes 2>/dev/null); then
            success "Conteneurs et base de données supprimés"
        else
            # Si ddev delete échoue (projet pas connu de ddev), juste arrêter proprement
            (cd "$shop_path" && ddev stop 2>/dev/null) || true
            warning "Impossible de supprimer complètement les conteneurs ddev"
            info "Tentative de nettoyage basique..."
        fi
    fi

    # ─── Étape 2 : Suppression des fichiers PrestaShop (conservation de .ddev) ─

    info "Suppression des fichiers PrestaShop..."
    local deleted_count=0
    while IFS= read -r -d '' item; do
        rm -rf "$item" 2>/dev/null && deleted_count=$((deleted_count + 1))
    done < <(find "$shop_path" -mindepth 1 -maxdepth 1 ! -name '.ddev' -print0 2>/dev/null)

    if [ "$deleted_count" -gt 0 ]; then
        success "Fichiers PrestaShop supprimés ($deleted_count élément(s))"
    else
        info "Aucun fichier PrestaShop à supprimer"
    fi

    # ─── Étape 3 : Mise à jour de la version PHP si nécessaire ───────────────

    if [ -f "$shop_path/.ddev/config.yaml" ]; then
        local required_php
        required_php=$(get_prestashop_php_version "$new_version" 2>/dev/null || echo "")
        local current_php
        current_php=$(grep -E "^php_version:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")

        if [ -n "$required_php" ] && [ "$current_php" != "$required_php" ]; then
            info "Mise à jour de la version PHP : ${current_php:-?} → $required_php"
            if (cd "$shop_path" && ddev config --php-version="$required_php" 2>/dev/null); then
                success "Version PHP mise à jour : $required_php"
            else
                warning "Impossible de mettre à jour la version PHP automatiquement"
                info "Vous pouvez le faire manuellement : cd $shop_path && ddev config --php-version=$required_php"
            fi
        fi
    fi

    # ─── Étape 4 : Réinstallation de PrestaShop ───────────────────────────────

    info "Lancement de la réinstallation de PrestaShop $new_version..."
    echo ""

    # Construire les arguments pour _install_shop_internal
    # On passe les ports existants pour éviter qu'ils soient réattribués
    local install_args=("$shop_name" "$new_version")

    if [ -n "$current_http_port" ]; then
        install_args+=("--router-http-port" "$current_http_port")
    fi
    if [ -n "$current_https_port" ]; then
        install_args+=("--router-https-port" "$current_https_port")
    fi

    # Ajouter les arguments supplémentaires passés par l'utilisateur
    if [ ${#extra_args[@]} -gt 0 ]; then
        install_args+=("${extra_args[@]}")
    fi

    # Exécuter l'installation depuis le répertoire du shop
    # _install_shop_internal est défini dans commands/shop/install.sh,
    # qui est chargé par lib/commands/shop.sh avant ce fichier
    if ! function_exists "_install_shop_internal"; then
        # Chargement de secours si appelé hors du routeur
        if [ -f "${SCRIPT_DIR}/commands/shop/install.sh" ]; then
            source "${SCRIPT_DIR}/commands/shop/install.sh"
        else
            error "Impossible de charger la fonction d'installation"
            exit 1
        fi
    fi

    (
        cd "$shop_path" || exit 1
        _install_shop_internal "${install_args[@]}"
    )
    local reinstall_exit_code=$?

    if [ $reinstall_exit_code -eq 0 ]; then
        echo ""
        success "Shop '$shop_name' réinstallé avec succès !"
    else
        echo ""
        error "La réinstallation du shop '$shop_name' a échoué (code: $reinstall_exit_code)"
        exit 1
    fi
}
