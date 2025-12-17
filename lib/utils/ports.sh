#!/bin/bash

# Fonctions de gestion des ports (ddev et Docker)

# Fonction pour obtenir tous les ports utilisés par ddev
# Usage: get_ddev_used_ports
# Retourne une liste des ports HTTP et HTTPS utilisés par les projets ddev
get_ddev_used_ports() {
    local http_ports=()
    local https_ports=()
    
    if ! command_exists ddev; then
        return 1
    fi
    
    # Obtenir la liste des projets ddev
    local ddev_list_output
    ddev_list_output=$(ddev list 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$ddev_list_output" ]; then
        # Parser la sortie de ddev list pour extraire les ports
        # Format: https://shop18.ddev.site:33001 ou http://shop18.ddev.site:33000
        while IFS= read -r line; do
            # Extraire les ports HTTP et HTTPS depuis les URLs
            local https_port=$(echo "$line" | grep -oE "https://[^[:space:]]+:([0-9]+)" | sed 's/.*://' || echo "")
            local http_port=$(echo "$line" | grep -oE "http://[^[:space:]]+:([0-9]+)" | sed 's/.*://' || echo "")
            
            if [ -n "$https_port" ]; then
                https_ports+=("$https_port")
            fi
            if [ -n "$http_port" ]; then
                http_ports+=("$http_port")
            fi
        done <<< "$ddev_list_output"
    fi
    
    # Afficher les résultats
    if [ ${#http_ports[@]} -gt 0 ] || [ ${#https_ports[@]} -gt 0 ]; then
        echo "Ports utilisés par ddev:"
        if [ ${#http_ports[@]} -gt 0 ]; then
            echo "  HTTP: ${http_ports[*]}"
        fi
        if [ ${#https_ports[@]} -gt 0 ]; then
            echo "  HTTPS: ${https_ports[*]}"
        fi
    else
        echo "Aucun port ddev trouvé"
    fi
}

# Fonction pour obtenir tous les ports utilisés par Docker
# Usage: get_docker_used_ports
# Retourne une liste des ports utilisés par les conteneurs Docker
get_docker_used_ports() {
    local all_ports=()
    
    if ! command_exists docker; then
        return 1
    fi
    
    # Obtenir tous les ports mappés depuis les conteneurs Docker
    local docker_ps_output
    docker_ps_output=$(docker ps --format "{{.Ports}}" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$docker_ps_output" ]; then
        # Parser la sortie pour extraire les ports
        # Format: 0.0.0.0:8080->80/tcp ou [::]:8080->80/tcp
        while IFS= read -r line; do
            if [ -n "$line" ] && [ "$line" != "<no value>" ]; then
                # Extraire les ports depuis le format Docker
                local ports=$(echo "$line" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:([0-9]+)->" | sed 's/.*://' | sed 's/->//' || echo "")
                if [ -z "$ports" ]; then
                    # Essayer avec le format IPv6
                    ports=$(echo "$line" | grep -oE "\[::\]:([0-9]+)->" | sed 's/\[::\]://' | sed 's/->//' || echo "")
                fi
                if [ -n "$ports" ]; then
                    all_ports+=("$ports")
                fi
            fi
        done <<< "$docker_ps_output"
    fi
    
    # Afficher les résultats
    if [ ${#all_ports[@]} -gt 0 ]; then
        echo "Ports utilisés par Docker:"
        # Trier et dédupliquer les ports
        local unique_ports=($(printf '%s\n' "${all_ports[@]}" | sort -u))
        echo "  ${unique_ports[*]}"
    else
        echo "Aucun port Docker trouvé"
    fi
}

# Fonction pour vérifier si un port est disponible
# Usage: is_port_available <port>
# Retourne 0 si le port est disponible, 1 sinon
is_port_available() {
    local port="$1"
    
    if [ -z "$port" ] || ! [[ "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Obtenir tous les ports utilisés
    get_all_used_ports
    
    # Vérifier dans les ports HTTP
    for p in "${_USED_HTTP_PORTS[@]}"; do
        if [ "$p" = "$port" ]; then
            return 1
        fi
    done
    
    # Vérifier dans les ports HTTPS
    for p in "${_USED_HTTPS_PORTS[@]}"; do
        if [ "$p" = "$port" ]; then
            return 1
        fi
    done
    
    return 0
}

# Fonction pour obtenir tous les ports utilisés (ddev registre + Docker)
# Usage: get_all_used_ports
# Retourne deux tableaux globaux: _USED_HTTP_PORTS et _USED_HTTPS_PORTS
get_all_used_ports() {
    _USED_HTTP_PORTS=()
    _USED_HTTPS_PORTS=()
    
    # Charger la configuration si nécessaire
    if [ -z "$PS_TOOL_SHOPS_REGISTRY" ]; then
        if [ -f "${SCRIPT_DIR}/lib/config.sh" ]; then
            source "${SCRIPT_DIR}/lib/config.sh"
        else
            PS_TOOL_SHOPS_REGISTRY="${HOME}/.ps_tool/shops.txt"
        fi
    fi
    
    # 1. Lire les ports depuis le registre des shops
    if [ -f "$PS_TOOL_SHOPS_REGISTRY" ]; then
        while IFS='|' read -r name path version http_port https_port; do
            # Ignorer les lignes vides ou mal formées
            if [ -z "$name" ]; then
                continue
            fi
            
            if [ -n "$http_port" ] && [[ "$http_port" =~ ^[0-9]+$ ]]; then
                _USED_HTTP_PORTS+=("$http_port")
            fi
            if [ -n "$https_port" ] && [[ "$https_port" =~ ^[0-9]+$ ]]; then
                _USED_HTTPS_PORTS+=("$https_port")
            fi
        done < "$PS_TOOL_SHOPS_REGISTRY"
    fi
    
    # 2. Lire les ports depuis ddev list (pour les projets non enregistrés)
    if command_exists ddev; then
        local ddev_list_output
        ddev_list_output=$(ddev list 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$ddev_list_output" ]; then
            while IFS= read -r line; do
                local https_port=$(echo "$line" | grep -oE "https://[^[:space:]]+:([0-9]+)" | sed 's/.*://' || echo "")
                local http_port=$(echo "$line" | grep -oE "http://[^[:space:]]+:([0-9]+)" | sed 's/.*://' || echo "")
                
                if [ -n "$https_port" ] && [[ "$https_port" =~ ^[0-9]+$ ]]; then
                    # Vérifier si le port n'est pas déjà dans la liste
                    local found=false
                    for p in "${_USED_HTTPS_PORTS[@]}"; do
                        if [ "$p" = "$https_port" ]; then
                            found=true
                            break
                        fi
                    done
                    if [ "$found" = false ]; then
                        _USED_HTTPS_PORTS+=("$https_port")
                    fi
                fi
                
                if [ -n "$http_port" ] && [[ "$http_port" =~ ^[0-9]+$ ]]; then
                    local found=false
                    for p in "${_USED_HTTP_PORTS[@]}"; do
                        if [ "$p" = "$http_port" ]; then
                            found=true
                            break
                        fi
                    done
                    if [ "$found" = false ]; then
                        _USED_HTTP_PORTS+=("$http_port")
                    fi
                fi
            done <<< "$ddev_list_output"
        fi
    fi
    
    # 3. Lire les ports depuis Docker
    if command_exists docker; then
        local docker_ps_output
        docker_ps_output=$(docker ps --format "{{.Ports}}" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$docker_ps_output" ]; then
            while IFS= read -r line; do
                if [ -n "$line" ] && [ "$line" != "<no value>" ]; then
                    # Extraire les ports depuis le format Docker (0.0.0.0:8080->80/tcp ou [::]:8080->80/tcp)
                    local ports=$(echo "$line" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:([0-9]+)->" | sed 's/.*://' | sed 's/->//' || echo "")
                    if [ -z "$ports" ]; then
                        ports=$(echo "$line" | grep -oE "\[::\]:([0-9]+)->" | sed 's/\[::\]://' | sed 's/->//' || echo "")
                    fi
                    
                    if [ -n "$ports" ] && [[ "$ports" =~ ^[0-9]+$ ]]; then
                        # Ajouter aux deux listes (HTTP et HTTPS) car on ne peut pas distinguer
                        local found=false
                        for p in "${_USED_HTTP_PORTS[@]}"; do
                            if [ "$p" = "$ports" ]; then
                                found=true
                                break
                            fi
                        done
                        if [ "$found" = false ]; then
                            _USED_HTTP_PORTS+=("$ports")
                            _USED_HTTPS_PORTS+=("$ports")
                        fi
                    fi
                fi
            done <<< "$docker_ps_output"
        fi
    fi
}

# Fonction pour générer des ports libres
# Usage: generate_free_ports [http_start] [https_start]
# Retourne "http_port|https_port" via echo
# Par défaut commence à 33000 pour HTTP et 33001 pour HTTPS
generate_free_ports() {
    local http_start="${1:-33000}"
    local https_start="${2:-33001}"
    
    # Obtenir tous les ports utilisés
    get_all_used_ports
    
    # Trouver un port HTTP libre
    local http_port=$http_start
    while true; do
        local found=false
        for p in "${_USED_HTTP_PORTS[@]}"; do
            if [ "$p" = "$http_port" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            break
        fi
        http_port=$((http_port + 1))
        # Limite de sécurité
        if [ $http_port -gt 65535 ]; then
            error "Impossible de trouver un port HTTP libre"
            return 1
        fi
    done
    
    # Trouver un port HTTPS libre
    local https_port=$https_start
    while true; do
        # Vérifier qu'il n'est pas égal au port HTTP
        if [ "$https_port" = "$http_port" ]; then
            https_port=$((https_port + 1))
            continue
        fi
        
        local found=false
        for p in "${_USED_HTTPS_PORTS[@]}"; do
            if [ "$p" = "$https_port" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            break
        fi
        https_port=$((https_port + 1))
        # Limite de sécurité
        if [ $https_port -gt 65535 ]; then
            error "Impossible de trouver un port HTTPS libre"
            return 1
        fi
    done
    
    echo "${http_port}|${https_port}"
    return 0
}

