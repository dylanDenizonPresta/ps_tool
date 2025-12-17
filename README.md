# ps_tool

CLI bash pour exécuter des ensembles de commandes macOS et installer des outils de développement.

## Installation

### Installation depuis le repository

1. Clonez le repository :
```bash
git clone https://github.com/USERNAME/ps_tool.git
cd ps_tool
```

2. Exécutez le script d'installation :
```bash
./install.sh
```

Le script va :
- Copier les fichiers dans `~/.ps_tool`
- Créer un lien symbolique dans `/usr/local/bin/ps_tool`
- Configurer les variables d'environnement nécessaires

### Vérification de l'installation

Après l'installation, vous devriez pouvoir utiliser `ps_tool` depuis n'importe quel terminal :

```bash
ps_tool version
```

### Désinstallation

Pour désinstaller ps_tool, exécutez le script de désinstallation :

```bash
./uninstall.sh
```

Le script va :
- Supprimer le lien symbolique dans `/usr/local/bin/ps_tool`
- Supprimer le répertoire d'installation `~/.ps_tool` (avec confirmation)
- Retirer la configuration de `~/.zshrc`, `~/.bashrc` et `~/.bash_profile`

**Note** : La désinstallation supprimera également le registre des shops créés. Assurez-vous d'avoir sauvegardé les informations importantes avant de désinstaller.

## Utilisation

### Commandes disponibles

- `ps_tool shop <command>` : Gérer les shops PrestaShop
- `ps_tool version` : Affiche la version actuelle
- `ps_tool list` : Liste les shops créés
- `ps_tool help` : Affiche l'aide

### Exemples

```bash
# Installer un shop PrestaShop
ps_tool shop install shop18

# Lister les shops créés
ps_tool list

# Voir la version
ps_tool version
```

## Mise à jour

Pour mettre à jour le CLI, réinstallez-le avec :

```bash
./install.sh
```

Cette commande va copier les nouveaux fichiers dans le répertoire d'installation.

## Ajouter de nouveaux outils

Pour ajouter un nouvel outil installable, éditez le fichier `commands/tools.sh` et ajoutez une nouvelle fonction `install_<nom_outil>()` :

```bash
install_mon_outil() {
    if command_exists mon_outil; then
        info "mon_outil est déjà installé"
        return 0
    fi

    info "Installation de mon_outil..."
    # Votre logique d'installation ici
    run_command "brew install mon-outil"
}
```

## Structure du projet

```
ps_tool/
├── ps_tool                 # Script principal
├── lib/
│   ├── commands/           # Implémentations des commandes
│   ├── utils.sh           # Fonctions utilitaires
│   └── config.sh           # Configuration
├── commands/
│   └── tools.sh           # Définitions des outils
├── install.sh             # Script d'installation
└── README.md              # Documentation
```

## Configuration

Le CLI stocke sa configuration dans `~/.ps_tool/config`.

Le répertoire d'installation par défaut est `~/.ps_tool`, mais peut être modifié via la variable d'environnement `PS_TOOL_INSTALL_DIR`.

## Prérequis

- macOS (testé sur les versions récentes)
- Bash 4.0 ou supérieur

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## Licence

[Spécifiez votre licence ici]

