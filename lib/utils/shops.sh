#!/bin/bash

# Fonctions de gestion des shops PrestaShop

# Fonction pour valider un shop (vérifie existence, répertoire, ddev)
# Usage: validate_shop <nom_shop>
# Retourne 0 si valide, 1 sinon
# Définit la variable _SHOP_PATH avec le chemin du shop
validate_shop() {
    local shop_name="$1"
    
    # Vérifier que ddev est installé
    if ! command_exists ddev; then
        error "ddev n'est pas installé"
        info "Installez ddev manuellement avec Homebrew: brew install ddev/ddev/ddev"
        return 1
    fi
    
    # Trouver le chemin du shop dans le registre
    local shop_path=$(get_shop_path "$shop_name")
    
    if [ -z "$shop_path" ]; then
        error "Shop non trouvé: $shop_name"
        info "Listez les shops disponibles avec: ps_tool shop list"
        return 1
    fi
    
    # Vérifier que le répertoire existe
    if [ ! -d "$shop_path" ]; then
        error "Le répertoire du shop n'existe plus: $shop_path"
        warning "Le shop a peut-être été supprimé"
        return 1
    fi
    
    # Vérifier que ddev est configuré dans ce répertoire
    if [ ! -f "$shop_path/.ddev/config.yaml" ]; then
        error "ddev n'est pas configuré dans ce répertoire: $shop_path"
        return 1
    fi
    
    # Exporter le chemin du shop
    _SHOP_PATH="$shop_path"
    return 0
}

# Fonction pour obtenir le chemin d'un shop depuis le registre
# Usage: get_shop_path <nom_shop>
# Retourne le chemin du shop ou une chaîne vide si non trouvé
get_shop_path() {
    local shop_name="$1"
    
    # Charger la configuration si nécessaire
    if [ -z "$PS_TOOL_SHOPS_REGISTRY" ]; then
        if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
            source "${SCRIPT_DIR}/lib/config.sh"
        else
            PS_TOOL_SHOPS_REGISTRY="${HOME}/.ps_tool/shops.txt"
        fi
    fi
    
    # Vérifier si le fichier existe
    if [ ! -f "$PS_TOOL_SHOPS_REGISTRY" ]; then
        return 1
    fi
    
    # Chercher le shop dans le registre
    # Format: shop_name|shop_path|prestashop_version|http_port|https_port
    while IFS='|' read -r name path version http_port https_port; do
        if [ "$name" = "$shop_name" ]; then
            echo "$path"
            return 0
        fi
    done < "$PS_TOOL_SHOPS_REGISTRY"
    
    return 1
}

# Fonction pour obtenir les ports d'un shop depuis le registre
# Usage: get_shop_ports_from_registry <nom_shop>
# Retourne "http_port|https_port" ou vide si non trouvé
get_shop_ports_from_registry() {
    local shop_name="$1"
    
    # Charger la configuration si nécessaire
    if [ -z "$PS_TOOL_SHOPS_REGISTRY" ]; then
        if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
            source "${SCRIPT_DIR}/lib/config.sh"
        else
            PS_TOOL_SHOPS_REGISTRY="${HOME}/.ps_tool/shops.txt"
        fi
    fi
    
    # Vérifier si le fichier existe
    if [ ! -f "$PS_TOOL_SHOPS_REGISTRY" ]; then
        return 1
    fi
    
    # Chercher le shop dans le registre
    # Format: shop_name|shop_path|prestashop_version|http_port|https_port
    while IFS='|' read -r name path version http_port https_port; do
        if [ "$name" = "$shop_name" ]; then
            echo "${http_port}|${https_port}"
            return 0
        fi
    done < "$PS_TOOL_SHOPS_REGISTRY"
    
    return 1
}

# Fonction pour obtenir la version PrestaShop d'un shop depuis le registre
# Usage: get_shop_prestashop_version <nom_shop>
# Retourne la version PrestaShop ou une chaîne vide si non trouvé
get_shop_prestashop_version() {
    local shop_name="$1"
    
    # Charger la configuration si nécessaire
    if [ -z "$PS_TOOL_SHOPS_REGISTRY" ]; then
        if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
            source "${SCRIPT_DIR}/lib/config.sh"
        else
            PS_TOOL_SHOPS_REGISTRY="${HOME}/.ps_tool/shops.txt"
        fi
    fi
    
    # Vérifier si le fichier existe
    if [ ! -f "$PS_TOOL_SHOPS_REGISTRY" ]; then
        return 1
    fi
    
    # Chercher le shop dans le registre
    # Format: shop_name|shop_path|prestashop_version|http_port|https_port
    while IFS='|' read -r name path version http_port https_port; do
        if [ "$name" = "$shop_name" ]; then
            echo "$version"
            return 0
        fi
    done < "$PS_TOOL_SHOPS_REGISTRY"
    
    return 1
}

# Fonction pour enregistrer un shop dans le registre
# Usage: register_shop <nom_shop> <chemin> [version_prestashop] [http_port] [https_port]
# Format du registre: shop_name|shop_path|prestashop_version|http_port|https_port
register_shop() {
    local shop_name="$1"
    local shop_path="$2"
    local prestashop_version="${3:-}"
    local http_port="${4:-}"
    local https_port="${5:-}"
    
    # Charger la configuration si nécessaire
    if [ -z "$PS_TOOL_SHOPS_REGISTRY" ]; then
        if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
            source "${SCRIPT_DIR}/lib/config.sh"
        else
            PS_TOOL_SHOPS_REGISTRY="${HOME}/.ps_tool/shops.txt"
        fi
    fi
    
    # Créer le répertoire de configuration s'il n'existe pas
    mkdir -p "$(dirname "$PS_TOOL_SHOPS_REGISTRY")"
    
    # Vérifier si le shop existe déjà
    if grep -q "^${shop_name}|" "$PS_TOOL_SHOPS_REGISTRY" 2>/dev/null; then
        # Mettre à jour l'entrée existante
        local temp_file=$(mktemp)
        grep -v "^${shop_name}|" "$PS_TOOL_SHOPS_REGISTRY" > "$temp_file" 2>/dev/null || true
        echo "${shop_name}|${shop_path}|${prestashop_version}|${http_port}|${https_port}" >> "$temp_file"
        mv "$temp_file" "$PS_TOOL_SHOPS_REGISTRY"
    else
        # Ajouter une nouvelle entrée
        echo "${shop_name}|${shop_path}|${prestashop_version}|${http_port}|${https_port}" >> "$PS_TOOL_SHOPS_REGISTRY"
    fi
}

# Fonction pour vérifier l'état d'un shop (démarré ou arrêté)
# Usage: get_shop_status <chemin_shop>
# Retourne "Démarré" ou "Arrêté"
get_shop_status() {
    local shop_path="$1"
    
    # Vérifier que ddev est installé
    if ! command_exists ddev; then
        echo "N/A"
        return 0
    fi
    
    # Vérifier que le répertoire existe et contient une config ddev
    if [ ! -d "$shop_path" ] || [ ! -f "$shop_path/.ddev/config.yaml" ]; then
        echo "N/A"
        return 0
    fi
    
    # Vérifier l'état via ddev describe
    # Si ddev describe retourne des informations avec "OK" ou "running", le projet est démarré
    local status_output
    status_output=$(cd "$shop_path" && timeout 3 ddev describe 2>/dev/null)
    local describe_exit_code=$?
    
    if [ $describe_exit_code -eq 0 ] && [ -n "$status_output" ]; then
        # Vérifier si la sortie contient des indicateurs que le projet est démarré
        # "OK" dans la colonne STAT indique que le service est démarré
        # "running (ok)" ou "running" dans ddev list indique aussi un projet démarré
        if echo "$status_output" | grep -qiE "(OK|running|started|active)" && \
           ! echo "$status_output" | grep -qiE "(stopped|not found|unhealthy.*stopped)"; then
            echo "Démarré"
        else
            echo "Arrêté"
        fi
    else
        # Si ddev describe échoue ou ne retourne rien, vérifier avec ddev list
        local project_name=$(grep -E "^name:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/^name:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"' | tr -d "'" || echo "")
        if [ -n "$project_name" ] && command_exists ddev; then
            local list_output
            list_output=$(ddev list 2>/dev/null | grep -E "^[[:space:]]*${project_name}[[:space:]]" || echo "")
            if echo "$list_output" | grep -qiE "(running|ok)"; then
                echo "Démarré"
            else
                echo "Arrêté"
            fi
        else
            echo "Arrêté"
        fi
    fi
}

# Fonction pour obtenir les ports utilisés par un shop
# Usage: get_shop_ports <chemin_shop>
# Retourne les ports au format "HTTP:80, HTTPS:443" ou "N/A"
get_shop_ports() {
    local shop_path="$1"
    
    # Vérifier que ddev est installé
    if ! command_exists ddev; then
        echo "N/A"
        return 0
    fi
    
    # Vérifier que le répertoire existe et contient une config ddev
    if [ ! -d "$shop_path" ] || [ ! -f "$shop_path/.ddev/config.yaml" ]; then
        echo "N/A"
        return 0
    fi
    
    # Essayer d'abord avec ddev describe --json (plus fiable)
    local json_output
    json_output=$(cd "$shop_path" && timeout 3 ddev describe --json 2>/dev/null)
    local json_exit_code=$?
    
    local http_port=""
    local https_port=""
    
    if [ $json_exit_code -eq 0 ] && [ -n "$json_output" ]; then
        # Extraire les ports depuis le JSON
        http_port=$(echo "$json_output" | grep -oE '"http_port":\s*([0-9]+)' | head -1 | grep -oE '[0-9]+' || echo "")
        https_port=$(echo "$json_output" | grep -oE '"https_port":\s*([0-9]+)' | head -1 | grep -oE '[0-9]+' || echo "")
    fi
    
    # Si pas trouvé dans le JSON, essayer ddev describe en texte
    if [ -z "$http_port" ] && [ -z "$https_port" ]; then
        local describe_output
        describe_output=$(cd "$shop_path" && timeout 3 ddev describe 2>/dev/null)
        local describe_exit_code=$?
        
        if [ $describe_exit_code -eq 0 ] && [ -n "$describe_output" ]; then
            # Chercher les URLs avec ports dans la section "Project URLs" ou dans les URLs du service web
            # Format: https://shop18.ddev.site:33001 ou http://shop18.ddev.site:33000
            https_port=$(echo "$describe_output" | grep -oE "https://[^[:space:],]+:([0-9]+)" | head -1 | sed 's/.*://' || echo "")
            http_port=$(echo "$describe_output" | grep -oE "http://[^[:space:],]+:([0-9]+)" | head -1 | sed 's/.*://' || echo "")
            
            # Si toujours pas trouvé, chercher dans la ligne du projet (format: https://shop18.ddev.site:33001)
            if [ -z "$https_port" ] && [ -z "$http_port" ]; then
                https_port=$(echo "$describe_output" | grep -oE "https://[^[:space:]]+:([0-9]+)" | head -1 | sed 's/.*://' || echo "")
                http_port=$(echo "$describe_output" | grep -oE "http://[^[:space:]]+:([0-9]+)" | head -1 | sed 's/.*://' || echo "")
            fi
        fi
    fi
    
    # Si toujours pas trouvé, essayer avec ddev list (fonctionne même si projet arrêté)
    if [ -z "$http_port" ] && [ -z "$https_port" ]; then
        local project_name=$(grep -E "^name:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/^name:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"' | tr -d "'" || echo "")
        if [ -n "$project_name" ] && command_exists ddev; then
            # Lire ddev list et chercher le projet
            local ddev_list_output
            ddev_list_output=$(ddev list 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$ddev_list_output" ]; then
                # Chercher la ligne du projet dans ddev list
                local list_line=$(echo "$ddev_list_output" | grep -E "^[│ ]*${project_name}[│ ]" || echo "")
                if [ -n "$list_line" ]; then
                    # Extraire les ports depuis la ligne (format: https://shop18.ddev.site:33001)
                    https_port=$(echo "$list_line" | grep -oE "https://[^[:space:]]+:([0-9]+)" | head -1 | sed 's/.*://' || echo "")
                    http_port=$(echo "$list_line" | grep -oE "http://[^[:space:]]+:([0-9]+)" | head -1 | sed 's/.*://' || echo "")
                fi
            fi
        fi
    fi
    
    # Si toujours pas trouvé, lire depuis config.yaml (peut être commenté ou utiliser les valeurs par défaut)
    if [ -z "$http_port" ] && [ -z "$https_port" ]; then
        if [ -f "$shop_path/.ddev/config.yaml" ]; then
            # Chercher les ports non commentés
            http_port=$(grep -E "^router_http_port:" "$shop_path/.ddev/config.yaml" 2>/dev/null | grep -v "^#" | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")
            https_port=$(grep -E "^router_https_port:" "$shop_path/.ddev/config.yaml" 2>/dev/null | grep -v "^#" | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")
        fi
    fi
    
    # Formater la sortie
    if [ -n "$http_port" ] && [ -n "$https_port" ]; then
        echo "HTTP:$http_port, HTTPS:$https_port"
    elif [ -n "$http_port" ]; then
        echo "HTTP:$http_port"
    elif [ -n "$https_port" ]; then
        echo "HTTPS:$https_port"
    else
        echo "N/A"
    fi
}

# Fonction pour lire le registre des shops
# Usage: read_shops_registry
# Affiche la liste des shops dans un tableau avec le chemin et l'état, et retourne le nombre via la variable globale _SHOP_COUNT
read_shops_registry() {
    # Charger la configuration si nécessaire
    if [ -z "$PS_TOOL_SHOPS_REGISTRY" ]; then
        if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
            source "${SCRIPT_DIR}/lib/config.sh"
        else
            PS_TOOL_SHOPS_REGISTRY="${HOME}/.ps_tool/shops.txt"
        fi
    fi
    
    # Réinitialiser le compteur
    _SHOP_COUNT=0
    
    # Vérifier si le fichier existe
    if [ ! -f "$PS_TOOL_SHOPS_REGISTRY" ]; then
        return 1
    fi
    
    # Collecter les données dans des tableaux
    local shop_names=()
    local shop_paths=()
    local shop_versions=()
    local shop_statuses=()
    local shop_ports=()
    
    # Lire le registre et collecter les données
    # Format: shop_name|shop_path|prestashop_version|http_port|https_port
    while IFS='|' read -r shop_name shop_path prestashop_version http_port https_port; do
        # Ignorer les lignes vides ou mal formées
        if [ -z "$shop_name" ]; then
            continue
        fi
        
        # Vérifier que le répertoire existe toujours
        if [ ! -d "$shop_path" ]; then
            continue
        fi
        
        # Obtenir l'état du shop
        local status=$(get_shop_status "$shop_path")
        
        # Utiliser les ports du registre si disponibles, sinon essayer de les obtenir depuis ddev
        local ports="N/A"
        if [ -n "$http_port" ] && [ -n "$https_port" ] && [[ "$http_port" =~ ^[0-9]+$ ]] && [[ "$https_port" =~ ^[0-9]+$ ]]; then
            ports="HTTP:$http_port, HTTPS:$https_port"
        else
            # Fallback: obtenir depuis ddev describe
            ports=$(get_shop_ports "$shop_path")
        fi
        
        shop_names+=("$shop_name")
        shop_paths+=("$shop_path")
        shop_versions+=("${prestashop_version:-N/A}")
        shop_statuses+=("$status")
        shop_ports+=("$ports")
        _SHOP_COUNT=$((_SHOP_COUNT + 1))
    done < "$PS_TOOL_SHOPS_REGISTRY"
    
    # Si aucun shop, ne rien afficher
    if [ $_SHOP_COUNT -eq 0 ]; then
        return 0
    fi
    
    # Déterminer les largeurs de colonnes
    local name_width=20
    local version_width=15
    local status_width=10
    local ports_width=20
    local path_width=50
    
    # Calculer les largeurs nécessaires
    for i in "${!shop_names[@]}"; do
        local name_len=${#shop_names[$i]}
        local version_len=${#shop_versions[$i]}
        local status_len=${#shop_statuses[$i]}
        local ports_len=${#shop_ports[$i]}
        local path_len=${#shop_paths[$i]}
        
        if [ $name_len -gt $name_width ]; then
            name_width=$name_len
        fi
        if [ $version_len -gt $version_width ]; then
            version_width=$version_len
        fi
        if [ $status_len -gt $status_width ]; then
            status_width=$status_len
        fi
        if [ $ports_len -gt $ports_width ]; then
            ports_width=$ports_len
        fi
        if [ $path_len -gt $path_width ]; then
            path_width=$path_len
        fi
    done
    
    # Ajouter un peu de marge
    name_width=$((name_width + 2))
    version_width=$((version_width + 2))
    status_width=$((status_width + 2))
    ports_width=$((ports_width + 2))
    path_width=$((path_width + 2))
    
    # Limiter la largeur du chemin si trop long
    if [ $path_width -gt 60 ]; then
        path_width=60
    fi
    
    # Afficher l'en-tête du tableau (avec état et ports)
    printf "┌%-*s┬%-*s┬%-*s┬%-*s┬%-*s┐\n" $name_width "" $version_width "" $status_width "" $ports_width "" $path_width ""
    printf "│%-*s│%-*s│%-*s│%-*s│%-*s│\n" $name_width " Nom du shop" $version_width " Version PS" $status_width " État" $ports_width " Ports" $path_width " Chemin"
    printf "├%-*s┼%-*s┼%-*s┼%-*s┼%-*s┤\n" $name_width "" $version_width "" $status_width "" $ports_width "" $path_width ""
    
    # Afficher les lignes de données
    for i in "${!shop_names[@]}"; do
        local name="${shop_names[$i]}"
        local version="${shop_versions[$i]}"
        local status="${shop_statuses[$i]}"
        local ports="${shop_ports[$i]}"
        local path="${shop_paths[$i]}"
        
        # Tronquer le chemin si trop long
        if [ ${#path} -gt $((path_width - 2)) ]; then
            path="...${path: -$((path_width - 5))}"
        fi
        
        printf "│%-*s│%-*s│%-*s│%-*s│%-*s│\n" $name_width " $name" $version_width " $version" $status_width " $status" $ports_width " $ports" $path_width " $path"
    done
    
    # Afficher le pied du tableau
    printf "└%-*s┴%-*s┴%-*s┴%-*s┴%-*s┘\n" $name_width "" $version_width "" $status_width "" $ports_width "" $path_width ""
}

