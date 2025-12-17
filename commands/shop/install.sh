#!/bin/bash

# Installation d'une shop PrestaShop

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

# Fonction interne pour l'installation (retourne un code de sortie)
_install_shop_internal() {
    # Afficher l'aide si demandé
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << EOF
Installation d'une shop PrestaShop avec ddev

Usage:
    ps_tool shop install <nom_shop> [version] [options]

Arguments:
    nom_shop          Nom de la shop (utilisé pour le projet ddev)
    version           Version de PrestaShop à installer (optionnel)
                      Par défaut: $PRESTASHOP_DEFAULT_VERSION

Options:
    --router-http-port <port>    Port HTTP du routeur ddev (défaut: auto)
    --router-https-port <port>   Port HTTPS du routeur ddev (défaut: auto)
    --admin-email <email>        Email de l'administrateur (défaut: admin@prestashop.com)
    --admin-password <password>  Mot de passe admin (défaut: presta123)
    --shop-name <name>           Nom de la boutique (défaut: nom du shop)
    --country <code>             Code pays ISO (défaut: FR)
    --language <code>            Code langue (défaut: fr)
    --timezone <timezone>        Fuseau horaire (défaut: Europe/Paris)
    --currency <code>            Code devise (défaut: EUR)
    --help, -h                    Afficher cette aide

Exemples:
    ps_tool shop install shop18
    ps_tool shop install shop18 9.0.2
    ps_tool shop install shop18 8.2.3
    ps_tool shop install shop18 9.0.2 --router-http-port 8080 --router-https-port 8443
    ps_tool shop install shop18 --admin-email admin@example.com --admin-password MyPass123

La commande va:
    1. Télécharger PrestaShop depuis GitHub
    2. Extraire les fichiers à la racine du répertoire courant
    3. Configurer ddev avec la version PHP appropriée et les ports spécifiés
    4. Installer PrestaShop automatiquement via CLI (sans interface web)

Pour lister les versions disponibles, consultez le fichier de configuration.
EOF
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            return 0
        else
            return 1
        fi
    fi

    local shop_name="$1"
    shift
    
    # Parser les arguments et options
    local prestashop_version="$PRESTASHOP_DEFAULT_VERSION"
    local router_http_port=""
    local router_https_port=""
    
    # Options d'installation CLI avec valeurs par défaut
    local admin_email="admin@prestashop.com"
    local admin_password="presta123"
    local shop_name_option=""
    local country="FR"
    local language="fr"
    local timezone="Europe/Paris"
    local currency="EUR"
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --router-http-port)
                if [ $# -lt 2 ]; then
                    error "Option --router-http-port nécessite un port"
                    return 1
                fi
                router_http_port="$2"
                shift 2
                ;;
            --router-https-port)
                if [ $# -lt 2 ]; then
                    error "Option --router-https-port nécessite un port"
                    return 1
                fi
                router_https_port="$2"
                shift 2
                ;;
            --admin-email)
                if [ $# -lt 2 ]; then
                    error "Option --admin-email nécessite un email"
                    return 1
                fi
                admin_email="$2"
                shift 2
                ;;
            --admin-password)
                if [ $# -lt 2 ]; then
                    error "Option --admin-password nécessite un mot de passe"
                    return 1
                fi
                admin_password="$2"
                shift 2
                ;;
            --shop-name)
                if [ $# -lt 2 ]; then
                    error "Option --shop-name nécessite un nom"
                    return 1
                fi
                shop_name_option="$2"
                shift 2
                ;;
            --country)
                if [ $# -lt 2 ]; then
                    error "Option --country nécessite un code pays"
                    return 1
                fi
                country="$2"
                shift 2
                ;;
            --language)
                if [ $# -lt 2 ]; then
                    error "Option --language nécessite un code langue"
                    return 1
                fi
                language="$2"
                shift 2
                ;;
            --timezone)
                if [ $# -lt 2 ]; then
                    error "Option --timezone nécessite un fuseau horaire"
                    return 1
                fi
                timezone="$2"
                shift 2
                ;;
            --currency)
                if [ $# -lt 2 ]; then
                    error "Option --currency nécessite un code devise"
                    return 1
                fi
                currency="$2"
                shift 2
                ;;
            --help|-h)
                # Aide déjà affichée au début
                return 0
                ;;
            -*)
                warning "Option inconnue: $1"
                shift
                ;;
            *)
                # Si ce n'est pas une option, c'est probablement la version PrestaShop
                if [ "$prestashop_version" = "$PRESTASHOP_DEFAULT_VERSION" ] && [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    prestashop_version="$1"
                else
                    warning "Argument ignoré: $1"
                fi
                shift
                ;;
        esac
    done
    
    # Utiliser le nom du shop comme nom de boutique par défaut si non spécifié
    if [ -z "$shop_name_option" ]; then
        shop_name_option="$shop_name"
    fi
    
    info "Installation de la shop: $shop_name"
    info "Version PrestaShop: $prestashop_version"
    
    # Vérifier que ddev est installé
    if ! command_exists ddev; then
        error "ddev n'est pas installé"
        if confirm "Voulez-vous installer ddev maintenant ?"; then
            # Charger la fonction install_ddev depuis ddev.sh
            if [ -f "${SCRIPT_DIR}/commands/ddev.sh" ]; then
                source "${SCRIPT_DIR}/commands/ddev.sh"
            fi
            install_ddev || return 1
        else
            return 1
        fi
    fi
    
    # Vérifier qu'on est dans un répertoire valide
    local current_dir=$(pwd)
    if [ ! -w "$current_dir" ]; then
        error "Le répertoire courant n'est pas accessible en écriture: $current_dir"
        return 1
    fi
    
    # Vérifier si ddev est déjà configuré AVANT l'extraction
    local need_ddev_config=true
    if [ -f "$current_dir/.ddev/config.yaml" ]; then
        # Vérifier le nom du projet dans la config
        local existing_project_name=$(grep -E "^name:" "$current_dir/.ddev/config.yaml" 2>/dev/null | sed 's/^name:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"' | tr -d "'" || echo "")
        
        if [ -n "$existing_project_name" ] && [ "$existing_project_name" = "$shop_name" ]; then
            # Le projet est déjà configuré avec le même nom
            info "ddev est déjà configuré pour ce shop: $shop_name"
            need_ddev_config=false
        else
            # Le projet existe mais avec un nom différent, ou ddev détecte un conflit
            if [ -n "$existing_project_name" ]; then
                warning "ddev est déjà configuré avec un autre nom de projet: $existing_project_name"
            else
                warning "ddev est déjà configuré dans ce répertoire"
            fi
            
            # Vérifier si un projet avec ce nom existe déjà ailleurs
            if command_exists ddev; then
                local existing_project=$(ddev list --json 2>/dev/null | grep -o "\"name\":\"${shop_name}\"" || echo "")
                if [ -n "$existing_project" ]; then
                    warning "Un projet ddev nommé '$shop_name' existe déjà ailleurs"
                    if confirm "Voulez-vous arrêter et retirer l'ancien projet ddev ?"; then
                        info "Arrêt et retrait de l'ancien projet ddev..."
                        # Trouver le chemin de l'ancien projet
                        local old_project_path=$(ddev list --json 2>/dev/null | grep -A 5 "\"name\":\"${shop_name}\"" | grep -o "\"approot\":\"[^\"]*\"" | cut -d'"' -f4 | head -1)
                        if [ -n "$old_project_path" ] && [ -d "$old_project_path" ]; then
                            (cd "$old_project_path" && ddev stop --unlist 2>/dev/null) || true
                            info "Ancien projet ddev arrêté et retiré"
                        else
                            # Essayer avec le nom directement
                            ddev stop --unlist "$shop_name" 2>/dev/null || true
                        fi
                    fi
                fi
            fi
            
            if ! confirm "Voulez-vous reconfigurer ddev pour $shop_name ?"; then
                info "Configuration ddev annulée"
                need_ddev_config=false
            fi
        fi
    else
        # Vérifier si un projet avec ce nom existe déjà ailleurs (même sans config.yaml local)
        if command_exists ddev; then
            local existing_project=$(ddev list --json 2>/dev/null | grep -o "\"name\":\"${shop_name}\"" || echo "")
            if [ -n "$existing_project" ]; then
                warning "Un projet ddev nommé '$shop_name' existe déjà ailleurs"
                if confirm "Voulez-vous arrêter et retirer l'ancien projet ddev ?"; then
                    info "Arrêt et retrait de l'ancien projet ddev..."
                    # Trouver le chemin de l'ancien projet
                    local old_project_path=$(ddev list --json 2>/dev/null | grep -A 5 "\"name\":\"${shop_name}\"" | grep -o "\"approot\":\"[^\"]*\"" | cut -d'"' -f4 | head -1)
                    if [ -n "$old_project_path" ] && [ -d "$old_project_path" ]; then
                        (cd "$old_project_path" && ddev stop --unlist 2>/dev/null) || true
                        info "Ancien projet ddev arrêté et retiré"
                    else
                        # Essayer avec le nom directement
                        ddev stop --unlist "$shop_name" 2>/dev/null || true
                    fi
                fi
            fi
        fi
    fi
    
    # Vérifier si le répertoire n'est pas vide (sauf fichiers cachés et .ddev)
    local visible_files=$(ls -A "$current_dir" 2>/dev/null | grep -v '^\.' | grep -v '^\.ddev$' || true)
    if [ -n "$visible_files" ]; then
        warning "Le répertoire n'est pas vide"
        if ! confirm "Voulez-vous continuer l'installation dans ce répertoire ?"; then
            info "Installation annulée"
            return 0
        fi
    fi
    
    # Obtenir l'URL de téléchargement de PrestaShop
    local download_url=$(get_prestashop_url "$prestashop_version")
    if [ -z "$download_url" ]; then
        error "Version PrestaShop non trouvée: $prestashop_version"
        return 1
    fi
    
    # Télécharger PrestaShop
    info "Téléchargement de PrestaShop $prestashop_version..."
    local zip_file="/tmp/prestashop_${prestashop_version}.zip"
    
    if command_exists curl; then
        if ! curl -fsSL -o "$zip_file" "$download_url"; then
            error "Échec du téléchargement de PrestaShop"
            return 1
        fi
    elif command_exists wget; then
        if ! wget -q -O "$zip_file" "$download_url"; then
            error "Échec du téléchargement de PrestaShop"
            return 1
        fi
    else
        error "curl ou wget est requis pour télécharger PrestaShop"
        return 1
    fi
    
    success "PrestaShop téléchargé avec succès"
    
    # Extraire PrestaShop à la racine du répertoire courant
    info "Extraction de PrestaShop..."
    if command_exists unzip; then
        # Créer un dossier temporaire pour l'extraction
        local temp_dir=$(mktemp -d)
        
        if ! unzip -q "$zip_file" -d "$temp_dir"; then
            error "Échec de l'extraction de PrestaShop"
            rm -rf "$temp_dir"
            rm -f "$zip_file"
            return 1
        fi
        
        # Vérifier si le ZIP contient un fichier prestashop.zip (cas PrestaShop 8.2.x)
        local inner_zip="$temp_dir/prestashop.zip"
        if [ -f "$inner_zip" ]; then
            info "Extraction du fichier prestashop.zip interne..."
            # Créer un sous-dossier pour extraire le prestashop.zip interne
            local inner_temp_dir=$(mktemp -d)
            if ! unzip -q "$inner_zip" -d "$inner_temp_dir"; then
                error "Échec de l'extraction du fichier prestashop.zip interne"
                rm -rf "$temp_dir" "$inner_temp_dir"
                rm -f "$zip_file"
                return 1
            fi
            # Supprimer les fichiers du premier niveau (Install_PrestaShop.html, index.php, prestashop.zip)
            # Utiliser find pour être plus fiable avec les fichiers cachés
            find "$temp_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null || rm -rf "$temp_dir"/* 2>/dev/null || true
            # Déplacer le contenu du inner_temp_dir vers temp_dir
            if [ -n "$(ls -A "$inner_temp_dir" 2>/dev/null)" ]; then
                # Utiliser find pour éviter les problèmes avec les fichiers cachés
                find "$inner_temp_dir" -mindepth 1 -maxdepth 1 -exec mv {} "$temp_dir/" \; 2>/dev/null || \
                find "$inner_temp_dir" -mindepth 1 -maxdepth 1 -exec cp -R {} "$temp_dir/" \; 2>/dev/null || true
            fi
            rm -rf "$inner_temp_dir"
            success "Fichier prestashop.zip interne extrait avec succès"
            # Après extraction du prestashop.zip interne, les fichiers sont directement dans temp_dir
            local extracted_dir="$temp_dir"
        else
            # Trouver le dossier extrait (généralement PrestaShop-version ou prestashop-version)
            # Ou utiliser directement le répertoire temporaire si les fichiers sont à la racine
            extracted_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)
            
            # Si aucun dossier n'est trouvé, les fichiers sont peut-être directement dans temp_dir
            if [ -z "$extracted_dir" ]; then
                # Vérifier s'il y a des fichiers dans temp_dir
                local file_count=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
                if [ "$file_count" -gt 0 ]; then
                    # Les fichiers sont directement dans temp_dir
                    extracted_dir="$temp_dir"
                else
                    error "Impossible de trouver le dossier extrait"
                    info "Contenu du répertoire temporaire:"
                    ls -la "$temp_dir" >&2 || true
                    rm -rf "$temp_dir"
                    rm -f "$zip_file"
                    return 1
                fi
            fi
        fi
        
        # Déplacer le contenu du dossier extrait vers la racine du répertoire courant
        info "Copie des fichiers vers le répertoire d'installation..."
        
        # Utiliser find avec -exec pour copier tous les fichiers et dossiers de manière fiable
        # Cela fonctionne même si extracted_dir = temp_dir et gère les fichiers cachés
        local copy_error=0
        find "$extracted_dir" -mindepth 1 -maxdepth 1 -exec cp -R {} "$current_dir/" \; 2>/dev/null || copy_error=$?
        
        # Si find échoue, essayer avec cp -R classique
        if [ $copy_error -ne 0 ]; then
            if ! cp -R "$extracted_dir"/* "$current_dir/" 2>/dev/null; then
                error "Échec de la copie des fichiers"
                info "Répertoire source: $extracted_dir"
                info "Répertoire destination: $current_dir"
                info "Contenu du répertoire source:"
                ls -la "$extracted_dir" | head -10 >&2 || true
                rm -rf "$temp_dir"
                rm -f "$zip_file"
                return 1
            fi
        fi
        
        # Vérifier que des fichiers ont bien été copiés dans le répertoire de destination
        local copied_files=$(find "$current_dir" -mindepth 1 -maxdepth 1 ! -name '.ddev' 2>/dev/null | wc -l | tr -d ' ')
        if [ "$copied_files" -lt 5 ]; then
            warning "Seulement $copied_files fichier(s)/dossier(s) copié(s), cela semble insuffisant"
            info "Vérifiez le contenu du répertoire d'installation"
            info "Contenu actuel:"
            ls -la "$current_dir" | head -10 >&2 || true
        fi
        
        # Nettoyer le dossier temporaire
        rm -rf "$temp_dir"
    else
        error "unzip est requis pour extraire PrestaShop"
        rm -f "$zip_file"
        return 1
    fi
    
    # Nettoyer le fichier ZIP
    rm -f "$zip_file"
    success "PrestaShop extrait avec succès à la racine du répertoire"
    
    # Déterminer le docroot (PrestaShop 8+ utilise 'public', versions antérieures utilisent la racine)
    local docroot="."
    if [ -d "public" ]; then
        docroot="public"
    fi
    
    # Configurer ddev seulement si nécessaire
    if [ "$need_ddev_config" = true ]; then
        # Configurer ddev dans le dossier courant
        info "Configuration de ddev dans: $current_dir"
        
        # Générer automatiquement les ports si non spécifiés
        if [ -z "$router_http_port" ] || [ -z "$router_https_port" ]; then
            info "Génération automatique des ports libres..."
            local free_ports
            free_ports=$(generate_free_ports)
            if [ $? -ne 0 ] || [ -z "$free_ports" ]; then
                error "Impossible de générer des ports libres"
                return 1
            fi
            
            # Extraire les ports générés
            router_http_port=$(echo "$free_ports" | cut -d'|' -f1)
            router_https_port=$(echo "$free_ports" | cut -d'|' -f2)
            
            info "Ports générés: HTTP:$router_http_port, HTTPS:$router_https_port"
        else
            # Vérifier que les ports spécifiés sont disponibles
            if ! is_port_available "$router_http_port"; then
                error "Le port HTTP $router_http_port est déjà utilisé"
                return 1
            fi
            if ! is_port_available "$router_https_port"; then
                error "Le port HTTPS $router_https_port est déjà utilisé"
                return 1
            fi
            if [ "$router_http_port" = "$router_https_port" ]; then
                error "Les ports HTTP et HTTPS ne peuvent pas être identiques"
                return 1
            fi
        fi
        
        # Afficher les ports qui seront utilisés
        info "Ports du routeur: HTTP:$router_http_port, HTTPS:$router_https_port"
        
        # Obtenir la version PHP requise depuis la configuration
        local php_version=$(get_prestashop_php_version "$prestashop_version")
        
        # Construire la commande ddev config avec les ports
        local ddev_config_cmd="ddev config --project-type=php --project-name=$shop_name --docroot=$docroot --php-version=$php_version --router-http-port=$router_http_port --router-https-port=$router_https_port"
        
        # Essayer de configurer ddev et capturer la sortie
        local config_output
        config_output=$(eval "$ddev_config_cmd" 2>&1)
        local config_exit_code=$?
        
        if [ $config_exit_code -eq 0 ]; then
            success "ddev configuré avec succès pour la shop: $shop_name"
        else
            # Vérifier si l'erreur est due à un projet existant avec le même nom
            if echo "$config_output" | grep -qi "already contains a project named"; then
                warning "Un projet ddev avec le nom '$shop_name' existe déjà"
                if confirm "Voulez-vous arrêter et retirer l'ancien projet ddev puis reconfigurer ?"; then
                    # Trouver et arrêter l'ancien projet
                    local old_project_path=$(ddev list --json 2>/dev/null | grep -A 5 "\"name\":\"${shop_name}\"" | grep -o "\"approot\":\"[^\"]*\"" | cut -d'"' -f4 | head -1)
                    if [ -n "$old_project_path" ] && [ -d "$old_project_path" ]; then
                        info "Arrêt de l'ancien projet ddev..."
                        (cd "$old_project_path" && ddev stop --unlist 2>/dev/null) || true
                        info "Ancien projet ddev arrêté et retiré"
                    else
                        # Essayer avec le nom directement
                        ddev stop --unlist "$shop_name" 2>/dev/null || true
                    fi
                    
                    # Réessayer la configuration avec les mêmes options (les ports sont déjà définis)
                    if run_command "$ddev_config_cmd"; then
                        success "ddev configuré avec succès pour la shop: $shop_name"
                    else
                        error "Échec de la configuration de ddev après retrait de l'ancien projet"
                        warning "PrestaShop a été installé mais ddev n'a pas pu être configuré"
                        return 1
                    fi
                else
                    error "Configuration ddev annulée"
                    warning "PrestaShop a été installé mais ddev n'a pas pu être configuré"
                    return 1
                fi
            else
                error "Échec de la configuration de ddev"
                echo "$config_output" >&2
                warning "PrestaShop a été installé mais ddev n'a pas pu être configuré"
                return 1
            fi
        fi
    fi
    
    # Enregistrer le shop dans le registre avec les ports (même si ddev était déjà configuré)
    # Si les ports n'ont pas été générés, essayer de les obtenir depuis la config ddev
    if [ -z "$router_http_port" ] || [ -z "$router_https_port" ]; then
        if [ -f "$current_dir/.ddev/config.yaml" ]; then
            router_http_port=$(grep -E "^router_http_port:" "$current_dir/.ddev/config.yaml" 2>/dev/null | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")
            router_https_port=$(grep -E "^router_https_port:" "$current_dir/.ddev/config.yaml" 2>/dev/null | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")
        fi
    fi
    
    if function_exists "register_shop"; then
        register_shop "$shop_name" "$current_dir" "$prestashop_version" "$router_http_port" "$router_https_port"
    else
        # Charger la fonction depuis utils.sh si elle n'est pas encore chargée
        source "${SCRIPT_DIR}/lib/utils.sh"
        register_shop "$shop_name" "$current_dir" "$prestashop_version" "$router_http_port" "$router_https_port"
    fi
    
    # Démarrer automatiquement ddev
    info "Démarrage de l'environnement ddev..."
    local ddev_started=false
    if run_command "ddev start"; then
        success "Environnement ddev démarré avec succès"
        ddev_started=true
    else
        warning "L'installation est terminée mais ddev n'a pas pu démarrer automatiquement"
        info "Vous pouvez démarrer manuellement avec: ddev start"
    fi
    
    # Installer PrestaShop via CLI si ddev est démarré
    if [ "$ddev_started" = true ]; then
        _install_prestashop_cli "$current_dir" "$shop_name" "$admin_email" "$admin_password" "$shop_name_option" "$country" "$language" "$timezone" "$currency" "$router_http_port" "$router_https_port"
    else
        warning "Installation CLI de PrestaShop ignorée (ddev non démarré)"
        info "Après avoir démarré ddev manuellement, vous pouvez installer PrestaShop via l'interface web avec: ddev launch"
    fi
    
    success "Installation terminée !"
    
    return 0
}

# Fonction pour installer PrestaShop via CLI
# Usage: _install_prestashop_cli <chemin> <shop_name> <admin_email> <admin_password> <shop_name_option> <country> <language> <timezone> <currency> <http_port> <https_port>
_install_prestashop_cli() {
    local shop_path="$1"
    local shop_name="$2"
    local admin_email="$3"
    local admin_password="$4"
    local shop_name_option="$5"
    local country="$6"
    local language="$7"
    local timezone="$8"
    local currency="$9"
    local http_port="${10}"
    local https_port="${11}"
    
    # Vérifier que ddev est démarré
    if ! command_exists ddev; then
        warning "ddev n'est pas disponible, installation CLI ignorée"
        return 1
    fi
    
    # Vérifier que le répertoire existe
    if [ ! -d "$shop_path" ]; then
        warning "Le répertoire du shop n'existe pas: $shop_path"
        return 1
    fi
    
    # Vérifier que le script d'installation CLI existe
    local install_script=""
    if [ -f "$shop_path/install/index_cli.php" ]; then
        install_script="install/index_cli.php"
    elif [ -f "$shop_path/install-dev/index_cli.php" ]; then
        install_script="install-dev/index_cli.php"
    else
        warning "Script d'installation CLI non trouvé dans $shop_path"
        info "PrestaShop sera installé via l'interface web avec: ddev launch"
        return 1
    fi
    
    info "Installation de PrestaShop via CLI..."
    
    # Construire le domaine avec le port si nécessaire
    # Avec ddev, si les ports sont personnalisés (différents de 80/443), il faut les inclure dans le domaine
    local domain="${shop_name}.ddev.site"
    
    # Récupérer les ports depuis la config ddev si non fournis
    if [ -z "$http_port" ] || [ -z "$https_port" ]; then
        if [ -f "$shop_path/.ddev/config.yaml" ]; then
            if [ -z "$http_port" ]; then
                http_port=$(grep -E "^router_http_port:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")
            fi
            if [ -z "$https_port" ]; then
                https_port=$(grep -E "^router_https_port:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")
            fi
        fi
    fi
    
    # Ajouter le port HTTPS au domaine s'il est personnalisé (différent de 443)
    if [ -n "$https_port" ] && [ "$https_port" != "443" ] && [ "$https_port" != "80" ]; then
        domain="${shop_name}.ddev.site:${https_port}"
    elif [ -n "$http_port" ] && [ "$http_port" != "80" ] && [ "$http_port" != "443" ]; then
        # Si pas de port HTTPS personnalisé mais un port HTTP personnalisé, utiliser celui-ci
        domain="${shop_name}.ddev.site:${http_port}"
    fi
    
    # Exécuter la commande dans le conteneur ddev
    info "Exécution de l'installation CLI de PrestaShop..."
    info "Email admin: $admin_email"
    info "Domaine: $domain"
    
    # Construire et exécuter la commande ddev exec
    # ddev exec exécute la commande dans le conteneur web
    local install_output
    if [ -n "$shop_name_option" ]; then
        install_output=$(cd "$shop_path" && ddev exec php "$install_script" \
            --domain="$domain" \
            --db_server=db \
            --db_name=db \
            --db_user=db \
            --db_password=db \
            --email="$admin_email" \
            --password="$admin_password" \
            --country="$country" \
            --language="$language" \
            --timezone="$timezone" \
            --currency="$currency" \
            --shop_name="$shop_name_option" \
            2>&1)
    else
        install_output=$(cd "$shop_path" && ddev exec php "$install_script" \
            --domain="$domain" \
            --db_server=db \
            --db_name=db \
            --db_user=db \
            --db_password=db \
            --email="$admin_email" \
            --password="$admin_password" \
            --country="$country" \
            --language="$language" \
            --timezone="$timezone" \
            --currency="$currency" \
            2>&1)
    fi
    local install_exit_code=$?
    
    if [ $install_exit_code -eq 0 ]; then
        success "PrestaShop installé avec succès via CLI"
        
        # Supprimer le dossier install après une installation réussie (sécurité)
        info "Suppression du dossier d'installation..."
        local install_dir=""
        if [ -d "$shop_path/install" ]; then
            install_dir="$shop_path/install"
        elif [ -d "$shop_path/install-dev" ]; then
            install_dir="$shop_path/install-dev"
        fi
        
        if [ -n "$install_dir" ] && [ -d "$install_dir" ]; then
            if rm -rf "$install_dir" 2>/dev/null; then
                success "Dossier d'installation supprimé avec succès"
            else
                warning "Impossible de supprimer le dossier d'installation: $install_dir"
                info "Veuillez le supprimer manuellement pour des raisons de sécurité"
            fi
        fi
        
        info "Vous pouvez accéder au shop avec: ddev launch"
        info "Back-office: https://${domain}/admin (email: $admin_email)"
    else
        warning "L'installation CLI de PrestaShop a échoué"
        echo "$install_output" >&2
        info "Vous pouvez installer PrestaShop manuellement via l'interface web"
        info "Accédez à: ddev launch"
        return 1
    fi
    
    return 0
}

# Commande pour ps_tool shop install (utilise exit)
cmd_shop_install() {
    _install_shop_internal "$@"
    local exit_code=$?
    exit $exit_code
}

