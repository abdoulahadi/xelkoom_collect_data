# Scripts utilitaires pour Xelkoom Backend

Ce dossier contient des scripts utilitaires pour faciliter la gestion du backend.

## Scripts disponibles

### manage.py

Un script utilitaire qui fournit des commandes communes pour gérer le backend.

Utilisation:

```bash
# Démarrer le serveur avec reload activé
python scripts/manage.py start --reload

# Créer un utilisateur administrateur
python scripts/manage.py admin

# Initialiser la base de données
python scripts/manage.py init-db

# Exécuter les migrations
python scripts/manage.py migrate

# Ajouter des données d'exemple
python scripts/manage.py sample-data

# Exécuter les tests
python scripts/manage.py test
```

### organize_files.py

Script pour organiser les fichiers du backend en déplaçant les scripts utilitaires vers le dossier scripts et les fichiers de test vers le dossier tests.

### Autres scripts

- `add_metadata_column.py` - Ajoute une colonne de métadonnées à la base de données
- `add_role_column.py` - Ajoute une colonne de rôle à la table utilisateurs
- `add_sample_sentences.py` - Ajoute des phrases d'exemple à la base de données
- `check_db.py` - Vérifie la connexion à la base de données
- `configure_balance.py` - Configure l'équilibrage des phrases
- `create_admin_user.py` - Crée un utilisateur administrateur
- `create_moderator.py` - Crée un utilisateur modérateur
- `update_user_roles.py` - Met à jour les rôles des utilisateurs
