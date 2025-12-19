# ps_tool

CLI bash pour exécuter des ensembles de commandes et installer des outils de développement.

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

#### Gestion des shops PrestaShop
- `ps_tool shop install <nom_shop> [version]` : Installer une shop PrestaShop
- `ps_tool shop list` : Lister tous les shops créés
- `ps_tool shop start <nom_shop>` : Démarrer un shop PrestaShop
- `ps_tool shop stop <nom_shop>` : Arrêter un shop PrestaShop
- `ps_tool shop remove <nom_shop> [--files]` : Supprimer un shop PrestaShop
- `ps_tool shop clean <nom_shop> [options]` : Nettoyer le cache et fichiers temporaires
- `ps_tool shop version` : Afficher les versions PrestaShop disponibles

#### Gestion du module ps_mbo
- `ps_tool mbo install <nom_shop> [version]` : Installer le module ps_mbo dans un shop
- `ps_tool mbo uninstall <nom_shop> [--files]` : Désinstaller le module ps_mbo d'un shop
- `ps_tool mbo use <environment> <nom_shop>` : Configurer l'environnement du module ps_mbo
- `ps_tool mbo status <nom_shop>` : Afficher la configuration actuelle de ps_mbo
- `ps_tool mbo version` : Afficher les versions ps_mbo disponibles

#### Gestion du module ps_accounts
- `ps_tool account install <nom_shop> [version] [--env PROD|PREPROD]` : Installer le module ps_accounts dans un shop
- `ps_tool account uninstall <nom_shop> [--files]` : Désinstaller le module ps_accounts d'un shop
- `ps_tool account version` : Afficher les versions ps_accounts disponibles

#### Autres commandes
- `ps_tool version` : Affiche la version actuelle du CLI
- `ps_tool list` : Liste les shops créés (alias de `ps_tool shop list`)
- `ps_tool help` : Affiche l'aide

### Exemples

```bash
# Installer un shop PrestaShop
ps_tool shop install shop18
ps_tool shop install shop18 9.0.2

# Installer avec Apache et options personnalisées
ps_tool shop install shop18 --webserver-type apache-fpm --router-http-port 8080

# Installation manuelle (sans CLI)
ps_tool shop install shop18 -m

# Lister les shops créés
ps_tool shop list

# Gérer un shop
ps_tool shop start shop18
ps_tool shop stop shop18
ps_tool shop remove shop18
ps_tool shop clean shop18

# Installer le module ps_mbo
ps_tool mbo install shop18
ps_tool mbo install shop18 5.2.1

# Désinstaller le module ps_mbo
ps_tool mbo uninstall shop18
ps_tool mbo uninstall shop18 --files

# Configurer l'environnement du module ps_mbo
ps_tool mbo use PROD shop18
ps_tool mbo use PREPROD shop18
ps_tool mbo use LOCAL shop18

# Installer le module ps_accounts
ps_tool account install shop18
ps_tool account install shop18 8.0.8
ps_tool account install shop18 --env PREPROD
ps_tool account install shop18 8.0.8 --env PREPROD

# Désinstaller le module ps_accounts
ps_tool account uninstall shop18
ps_tool account uninstall shop18 --files

# Voir le statut et les versions
ps_tool mbo status shop18
ps_tool mbo version
ps_tool account version
ps_tool shop version
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
├── ps_tool                 # Script principal (point d'entrée)
├── lib/
│   ├── commands/           # Routers des commandes principales
│   │   ├── shop.sh         # Router pour les commandes shop
│   │   ├── mbo.sh          # Router pour les commandes mbo
│   │   ├── account.sh      # Router pour les commandes account
│   │   └── version.sh      # Commande version
│   ├── utils/              # Modules utilitaires
│   │   ├── logging.sh      # Fonctions de logging
│   │   ├── commands.sh     # Fonctions d'exécution de commandes
│   │   ├── system.sh       # Fonctions système
│   │   ├── shops.sh        # Fonctions de gestion des shops
│   │   └── ports.sh        # Fonctions de gestion des ports
│   ├── utils.sh            # Chargeur des modules utilitaires
│   └── config.sh           # Configuration globale
├── commands/
│   ├── shop/               # Commandes shop
│   │   ├── install.sh      # Installation d'une shop
│   │   ├── list.sh         # Liste des shops
│   │   ├── start.sh        # Démarrer un shop
│   │   ├── stop.sh         # Arrêter un shop
│   │   ├── remove.sh       # Supprimer un shop
│   │   ├── clean.sh        # Nettoyer le cache et fichiers temporaires
│   │   └── version.sh      # Versions PrestaShop disponibles
│   ├── mbo/                 # Commandes mbo
│   │   ├── install.sh      # Installation du module ps_mbo
│   │   ├── uninstall.sh    # Désinstallation du module ps_mbo
│   │   ├── use.sh          # Configuration de l'environnement mbo
│   │   ├── status.sh       # Statut de la configuration mbo
│   │   └── version.sh      # Versions ps_mbo disponibles
│   ├── account/             # Commandes account
│   │   ├── install.sh      # Installation du module ps_accounts
│   │   └── version.sh      # Versions ps_accounts disponibles
│   ├── ddev.sh             # Installation de ddev
│   └── tools.sh            # Définitions des outils
├── config/
│   ├── prestashop.sh       # Configuration des versions PrestaShop
│   ├── ps_mbo.sh           # Configuration des versions ps_mbo
│   └── ps_accounts.sh      # Configuration des versions ps_accounts
├── install.sh              # Script d'installation
├── uninstall.sh            # Script de désinstallation
└── README.md               # Documentation
```

## Configuration

Le CLI stocke sa configuration dans `~/.ps_tool/` :
- `~/.ps_tool/config/` : Fichiers de configuration (versions PrestaShop, ps_mbo, etc.)
- `~/.ps_tool/shops.txt` : Registre des shops créés (nom, chemin, version PrestaShop, ports HTTP/HTTPS)

Le répertoire d'installation par défaut est `~/.ps_tool`, mais peut être modifié via la variable d'environnement `PS_TOOL_INSTALL_DIR`.

### Environnements disponibles pour ps_mbo

La commande `ps_tool mbo use` supporte les environnements suivants :
- `PROD` : Production (MBO: prod, Addons: prod)
- `PREPROD` : Préproduction (MBO: preprod, Addons: preprod)
- `LOCAL` : Local (MBO: local, Addons: local)
- `PRESTABULLE1-9` : Prestabulle 1 à 9 (MBO: prestabulleN, Addons: podN)
- `POD1-9` : Pod 1 à 9 (MBO: prod, Addons: podN)

## Prérequis

- macOS (le CLI est conçu pour macOS)
- Bash 4.0 ou supérieur
- ddev (sera installé automatiquement si nécessaire lors de l'installation d'une shop)
- curl ou wget (pour télécharger PrestaShop et les modules)
- unzip (pour extraire les archives)

### Installation manuelle des prérequis

Si vous préférez installer manuellement :

```bash
# Installer ddev avec Homebrew
brew install ddev/ddev/ddev

# Installer Git (si nécessaire)
brew install git

# Installer Node.js (si nécessaire)
brew install node

# Installer Python (si nécessaire)
brew install python
```

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## Licence

[Spécifiez votre licence ici]

