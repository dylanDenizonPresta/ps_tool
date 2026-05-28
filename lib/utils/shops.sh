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
    
    # Lire le nom du projet depuis la config ddev
    local project_name
    project_name=$(grep -E "^name:" "$shop_path/.ddev/config.yaml" 2>/dev/null | sed 's/^name:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"' | tr -d "'" || echo "")

    if [ -z "$project_name" ]; then
        echo "Arrêté"
        return 0
    fi

    # Vérifier l'état via ddev list (fonctionne même si timeout n'est pas dispo sur macOS)
    # Le format de sortie est : │ shop9  │ running │ ...
    local list_output
    list_output=$(ddev list 2>/dev/null | grep -E "[[:space:]|]${project_name}[[:space:]|]" || echo "")

    if echo "$list_output" | grep -qiE "(running|ok)"; then
        echo "Démarré"
    else
        echo "Arrêté"
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

    # Un seul appel ddev list pour tous les shops
    local ddev_list_output=""
    if command_exists ddev; then
        ddev_list_output=$(ddev list 2>/dev/null)
    fi

    # Collecter les données dans des tableaux
    local shop_names=()
    local shop_paths=()
    local shop_versions=()
    local shop_statuses=()
    local shop_urls=()

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

        # Déterminer le nom ddev depuis config.yaml
        local project_name
        project_name=$(grep -E "^name:" "$shop_path/.ddev/config.yaml" 2>/dev/null \
            | sed 's/^name:[[:space:]]*//' | sed 's/[\"'\'']//g' | tr -d '[:space:]')

        # Déduire l'état depuis le résultat ddev list déjà chargé
        local status="Arrêté"
        if [ -n "$project_name" ] && [ -n "$ddev_list_output" ]; then
            local line
            # ddev list utilise │ (Unicode) comme séparateur, on cherche le nom entouré d'espaces
            line=$(echo "$ddev_list_output" | grep " ${project_name} ")
            if echo "$line" | grep -qiE "(running|ok)"; then
                status="Démarré"
            fi
        fi

        # Construire l'URL depuis les ports du registre
        local url="N/A"
        if [ -n "$https_port" ] && [[ "$https_port" =~ ^[0-9]+$ ]]; then
            if [ "$https_port" = "443" ]; then
                url="https://${shop_name}.ddev.site"
            else
                url="https://${shop_name}.ddev.site:${https_port}"
            fi
        elif [ -n "$http_port" ] && [[ "$http_port" =~ ^[0-9]+$ ]]; then
            if [ "$http_port" = "80" ]; then
                url="http://${shop_name}.ddev.site"
            else
                url="http://${shop_name}.ddev.site:${http_port}"
            fi
        fi

        shop_names+=("$shop_name")
        shop_paths+=("$shop_path")
        shop_versions+=("${prestashop_version:-N/A}")
        shop_statuses+=("$status")
        shop_urls+=("$url")
        _SHOP_COUNT=$((_SHOP_COUNT + 1))
    done < "$PS_TOOL_SHOPS_REGISTRY"

    # Si aucun shop, ne rien afficher
    if [ "$_SHOP_COUNT" -eq 0 ]; then
        return 0
    fi

    # ─── Calcul des largeurs de colonnes (sur les valeurs visuelles) ──────────

    local name_width=12    # "Nom du shop"
    local version_width=11 # "Version PS"
    local status_width=9   # "● Démarré" = 9 visual chars + 2 padding
    local url_width=5      # "URL"
    local path_width=7     # "Chemin"

    for i in "${!shop_names[@]}"; do
        local nw=${#shop_names[$i]}
        local vw=${#shop_versions[$i]}
        local uw=${#shop_urls[$i]}
        local pw=${#shop_paths[$i]}

        [ $nw -gt $name_width ]    && name_width=$nw
        [ $vw -gt $version_width ] && version_width=$vw
        [ $uw -gt $url_width ]     && url_width=$uw
        [ $pw -gt $path_width ]    && path_width=$pw
    done

    # Marges internes (1 espace de chaque côté)
    name_width=$((name_width + 2))
    version_width=$((version_width + 2))
    status_width=$((status_width + 2))
    url_width=$((url_width + 2))
    path_width=$((path_width + 2))

    # Limiter le chemin
    [ $path_width -gt 55 ] && path_width=55

    # ─── Helper : ligne horizontale de n caractères ─ ─────────────────────────
    _hline() {
        local n="$1"
        local i
        for ((i = 0; i < n; i++)); do printf '─'; done
    }

    # ─── Helper : cellule statut colorée avec padding correct ─────────────────
    # "● Démarré" = 10 bytes (● 3 + espace 1 + Démarré 9 bytes), 9 visual chars
    # "● Arrêté"  = 9 bytes  (● 3 + espace 1 + Arrêté  8 bytes), 8 visual chars
    _status_cell() {
        local text="$1"
        local cell_w="$2"
        local dot="●"
        local label visual_w color
        if [ "$text" = "Démarré" ]; then
            color="$GREEN"
            label="$dot Démarré"
            visual_w=9  # ● + espace + 7 chars visuels
        else
            color="$RED"
            label="$dot Arrêté"
            visual_w=8  # ● + espace + 6 chars visuels
        fi
        local pad=$((cell_w - visual_w - 1))  # -1 pour l'espace initial
        printf " %b%s%b%*s" "$color" "$label" "$NC" "$pad" ""
    }

    # ─── Affichage du tableau ─────────────────────────────────────────────────

    # Ligne du haut
    printf '┌'; _hline $name_width
    printf '┬'; _hline $version_width
    printf '┬'; _hline $status_width
    printf '┬'; _hline $url_width
    printf '┬'; _hline $path_width
    printf '┐\n'

    # En-tête
    # Note: "État" contient É (2 bytes UTF-8 / 1 char visuel) → +1 pour compenser le padding printf
    printf "│ %-*s│ %-*s│ %-*s│ %-*s│ %-*s│\n" \
        $((name_width - 1))    "Nom du shop" \
        $((version_width - 1)) "Version PS" \
        $((status_width))      "État" \
        $((url_width - 1))     "URL" \
        $((path_width - 1))    "Chemin"

    # Séparateur
    printf '├'; _hline $name_width
    printf '┼'; _hline $version_width
    printf '┼'; _hline $status_width
    printf '┼'; _hline $url_width
    printf '┼'; _hline $path_width
    printf '┤\n'

    # Lignes de données
    for i in "${!shop_names[@]}"; do
        local name="${shop_names[$i]}"
        local version="${shop_versions[$i]}"
        local status="${shop_statuses[$i]}"
        local url="${shop_urls[$i]}"
        local path="${shop_paths[$i]}"

        # Tronquer le chemin si trop long
        local max_path=$((path_width - 2))
        if [ ${#path} -gt $max_path ]; then
            path="...${path: -$((max_path - 3))}"
        fi

        printf "│ %-*s│ %-*s│" \
            $((name_width - 1))    "$name" \
            $((version_width - 1)) "$version"
        _status_cell "$status" "$status_width"
        printf "│ %-*s│ %-*s│\n" \
            $((url_width - 1))  "$url" \
            $((path_width - 1)) "$path"
    done

    # Ligne du bas
    printf '└'; _hline $name_width
    printf '┴'; _hline $version_width
    printf '┴'; _hline $status_width
    printf '┴'; _hline $url_width
    printf '┴'; _hline $path_width
    printf '┘\n'
}

