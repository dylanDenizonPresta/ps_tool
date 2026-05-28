#!/bin/bash

# Interface web PS Tool

SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"
init_script_dir 1

# Port par défaut
WEB_DEFAULT_PORT=7337
WEB_PID_FILE="${HOME}/.ps_tool/web.pid"

cmd_web() {
    local subcommand="${1:-start}"

    case "$subcommand" in
        start|"")
            shift 2>/dev/null || true
            _web_start "$@"
            ;;
        stop)
            _web_stop
            ;;
        status)
            _web_status
            ;;
        help|--help|-h)
            _web_help
            ;;
        *)
            # Si c'est une option (--port, --no-open...), traiter comme start
            _web_start "$@"
            ;;
    esac
}

_web_help() {
    cat << EOF
Interface web PS Tool

Usage:
    ps_tool web [start]    Démarrer l'interface web (défaut)
    ps_tool web stop       Arrêter l'interface web
    ps_tool web status     Afficher le statut du serveur

Options (start):
    --port <port>    Port d'écoute (défaut: $WEB_DEFAULT_PORT)
    --no-open        Ne pas ouvrir le navigateur automatiquement
    --help, -h       Afficher cette aide

Exemples:
    ps_tool web
    ps_tool web --port 8080
    ps_tool web --no-open
    ps_tool web stop
EOF
}

_web_start() {
    local port="$WEB_DEFAULT_PORT"
    local auto_open=true

    # Parser les options
    while [ $# -gt 0 ]; do
        case "$1" in
            --port)
                if [ $# -lt 2 ]; then
                    error "Option --port nécessite un numéro de port"
                    exit 1
                fi
                port="$2"
                shift 2
                ;;
            --no-open)
                auto_open=false
                shift
                ;;
            --help|-h)
                _web_help
                exit 0
                ;;
            *)
                warning "Option inconnue: $1"
                shift
                ;;
        esac
    done

    # Vérifier que Node.js est installé
    if ! command_exists node; then
        error "Node.js n'est pas installé"
        info "Installez Node.js via: brew install node"
        exit 1
    fi

    local web_dir="${SCRIPT_DIR}/web"

    # Vérifier que le dossier web existe
    if [ ! -f "${web_dir}/server.js" ]; then
        error "L'interface web n'est pas installée (${web_dir}/server.js introuvable)"
        exit 1
    fi

    # Vérifier que les dépendances sont installées
    if [ ! -d "${web_dir}/node_modules" ]; then
        info "Installation des dépendances Node.js..."
        if ! (cd "$web_dir" && npm install --silent 2>/dev/null); then
            error "Échec de l'installation des dépendances"
            exit 1
        fi
        success "Dépendances installées"
    fi

    # Vérifier si un serveur tourne déjà
    if [ -f "$WEB_PID_FILE" ]; then
        local existing_pid
        existing_pid=$(cat "$WEB_PID_FILE" 2>/dev/null)
        if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
            local existing_port
            existing_port=$(lsof -Pan -p "$existing_pid" -iTCP -sTCP:LISTEN 2>/dev/null | grep -o ':\([0-9]*\)' | head -1 | tr -d ':')
            warning "L'interface web tourne déjà (PID: $existing_pid, port: ${existing_port:-?})"
            if [ -n "$existing_port" ]; then
                info "→ http://localhost:${existing_port}"
            fi
            if confirm "Voulez-vous la redémarrer sur le port $port ?"; then
                _web_stop
            else
                exit 0
            fi
        else
            rm -f "$WEB_PID_FILE"
        fi
    fi

    # Vérifier que le port est disponible
    if ! is_port_available "$port"; then
        error "Le port $port est déjà utilisé"
        info "Essayez un autre port : ps_tool web --port <port>"
        exit 1
    fi

    # Démarrer le serveur en arrière-plan
    info "Démarrage de l'interface web sur le port $port..."
    mkdir -p "$(dirname "$WEB_PID_FILE")"

    PORT="$port" nohup node "${web_dir}/server.js" \
        > "${HOME}/.ps_tool/web.log" 2>&1 &
    local pid=$!

    echo "$pid" > "$WEB_PID_FILE"

    # Attendre que le serveur soit prêt (max 5s)
    local url="http://localhost:${port}"
    local attempts=0
    while [ $attempts -lt 10 ]; do
        sleep 0.5
        if curl -s -o /dev/null "$url" 2>/dev/null; then
            break
        fi
        attempts=$((attempts + 1))
    done

    if ! kill -0 "$pid" 2>/dev/null; then
        error "Le serveur a échoué au démarrage"
        info "Logs : ${HOME}/.ps_tool/web.log"
        rm -f "$WEB_PID_FILE"
        exit 1
    fi

    success "Interface web démarrée → $url  (PID: $pid)"
    info "Arrêter avec : ps_tool web stop"

    # Ouvrir le navigateur
    if [ "$auto_open" = true ]; then
        if command_exists open; then
            open "$url"
        elif command_exists xdg-open; then
            xdg-open "$url"
        fi
    fi
}

_web_stop() {
    if [ ! -f "$WEB_PID_FILE" ]; then
        warning "Aucun serveur web PS Tool en cours d'exécution"
        return 0
    fi

    local pid
    pid=$(cat "$WEB_PID_FILE" 2>/dev/null)

    if [ -z "$pid" ]; then
        rm -f "$WEB_PID_FILE"
        warning "Fichier PID vide, aucun processus à arrêter"
        return 0
    fi

    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        rm -f "$WEB_PID_FILE"
        success "Interface web arrêtée (PID: $pid)"
    else
        rm -f "$WEB_PID_FILE"
        warning "Le processus (PID: $pid) n'était plus actif"
    fi
}

_web_status() {
    if [ ! -f "$WEB_PID_FILE" ]; then
        info "Interface web : arrêtée"
        return 0
    fi

    local pid
    pid=$(cat "$WEB_PID_FILE" 2>/dev/null)

    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        local port
        port=$(lsof -Pan -p "$pid" -iTCP -sTCP:LISTEN 2>/dev/null | grep -o ':\([0-9]*\)' | head -1 | tr -d ':')
        success "Interface web : en cours d'exécution (PID: $pid)"
        info "→ http://localhost:${port:-$WEB_DEFAULT_PORT}"
    else
        warning "Interface web : arrêtée (PID obsolète)"
        rm -f "$WEB_PID_FILE"
    fi
}
