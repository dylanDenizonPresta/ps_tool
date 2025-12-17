#!/bin/bash

# Fichier de référence pour les outils installables
# Ce fichier peut être utilisé pour ajouter des outils simples
# Pour des outils plus complexes, créez un fichier séparé dans commands/

# Charger les utilitaires (init_script_dir sera appelé automatiquement)
# On doit d'abord trouver le répertoire pour charger utils.sh
SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR_TMP}/lib/utils.sh"

# Utiliser la fonction init_script_dir pour normaliser SCRIPT_DIR
init_script_dir 1

# Ajoutez ici d'autres fonctions install_<nom_outil>() pour de nouveaux outils simples
# Pour des outils plus complexes, créez un fichier séparé (ex: commands/shop.sh, commands/ddev.sh)
