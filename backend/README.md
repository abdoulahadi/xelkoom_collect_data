# Xelkoom Backend - Plateforme de collecte audio pour Wolof TTS

Ce backend FastAPI fournit une API REST complète pour la gestion des utilisateurs, des phrases et des enregistrements audio pour la plateforme de collecte audio Xelkoom, destinée à l'entraînement de modèles Text-to-Speech (TTS) en Wolof.

## Configuration requise

- Python 3.9+
- PostgreSQL 13+
- FFmpeg
- Docker (optionnel pour déploiement conteneurisé)

## Installation

### Installation locale

1. Clonez le dépôt:
```bash
git clone <repository-url>
cd xelkoom-data-collect
```

2. Créez un environnement virtuel et installez les dépendances:
```bash
cd backend
python -m venv venv
# Sur Linux/MacOS
source venv/bin/activate
# Sur Windows
venv\Scripts\activate
pip install -r requirements.txt
```

3. Copiez le fichier d'environnement d'exemple:
```bash
copy .env.example .env
```

4. Modifiez les variables d'environnement dans `.env` selon votre configuration locale.

### Installation avec Docker

```bash
cd backend
docker-compose build
docker-compose up -d
```

## Structure du projet

```
backend/
├── app/                  # Application principale
│   ├── api/              # API routes et endpoints
│   ├── core/             # Configurations et utilitaires centraux
│   ├── db/               # Connexion et gestion de la base de données
│   ├── models/           # Modèles SQLAlchemy
│   ├── schemas/          # Schémas Pydantic
│   └── services/         # Services business logic
├── scripts/              # Scripts utilitaires
├── migrations/           # Migrations Alembic
├── tests/                # Tests unitaires et d'intégration
├── uploads/              # Répertoire pour les fichiers uploadés
└── audio/                # Répertoire pour les fichiers audio validés
```

## Utilisation

### Démarrage du serveur

Pour démarrer le serveur avec l'auto-reload activé:

```bash
python scripts/manage.py start --reload
```

Ou utilisez le script start_server.py:

```bash
python start_server.py
```

### Initialisation de la base de données

Pour initialiser la base de données et exécuter les migrations:

```bash
python scripts/manage.py init-db
python scripts/manage.py migrate
```

### Création d'un utilisateur administrateur

En production (sur Render), un utilisateur administrateur est créé automatiquement au démarrage avec les informations d'identification suivantes:
- **Nom d'utilisateur**: `xelkoom_admin` (configurable via la variable d'environnement `ADMIN_USERNAME`)
- **Mot de passe**: `X3lk00m@dmin2025!SecureP@ss` (configurable via la variable d'environnement `ADMIN_PASSWORD`)

Pour créer un utilisateur administrateur manuellement:

```bash
python scripts/manage.py admin
# ou
python scripts/update_admin_password.py [username] [password]
```

### Ajouter des données d'exemple

Pour ajouter des phrases d'exemple à la base de données:

```bash
python scripts/manage.py sample-data
```

### Exécution des tests

Pour exécuter tous les tests:

```bash
python scripts/manage.py test
```

Pour exécuter un fichier de test spécifique:

```bash
python scripts/manage.py test --test test_api.py
```

## API Documentation

Une fois le serveur démarré, la documentation de l'API est disponible à:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Architecture

Le backend suit une architecture en couches:

1. **API Layer** (app/api): Routes FastAPI et endpoints
2. **Service Layer** (app/services): Logique métier
3. **Model Layer** (app/models): Modèles SQLAlchemy
4. **Data Access Layer** (app/db): Accès à la base de données

## Déploiement sur Google Cloud

### Prérequis pour Google Cloud

1. Compte Google Cloud avec un projet créé
2. Google Cloud SDK installé et configuré
3. API Cloud Run, Cloud SQL et Cloud Storage activées

### Fichiers de configuration pour Google Cloud

Le projet inclut plusieurs fichiers spécifiques pour le déploiement sur Google Cloud :

- `Dockerfile.cloud` : Dockerfile optimisé pour Google Cloud Run
- `docker-compose.cloud.yml` : Configuration pour tester l'environnement Cloud localement
- `.env.cloud.example` : Exemple de variables d'environnement pour l'émulation Cloud
- `scripts/deploy_to_cloud_run.sh` : Script de déploiement pour Linux/macOS
- `scripts/deploy_to_cloud_run.bat` : Script de déploiement pour Windows
- `.gcloudignore` : Fichiers à ignorer lors du déploiement

### Test local de l'environnement Cloud

Pour tester localement l'environnement Cloud avant le déploiement :

```bash
# Créer le fichier de configuration
copy .env.cloud.example .env.cloud

# Lancer l'environnement d'émulation Cloud
docker-compose -f docker-compose.cloud.yml up -d
```

### Déploiement du backend sur Google Cloud Run

1. Créez une instance Cloud SQL (PostgreSQL):
```bash
gcloud sql instances create xelkoom-db --database-version=POSTGRES_13 --cpu=1 --memory=3840MiB --region=europe-west1
```

2. Créez une base de données et un utilisateur:
```bash
gcloud sql databases create xelkoom --instance=xelkoom-db
gcloud sql users create xelkoom-user --instance=xelkoom-db --password=<mot-de-passe-sécurisé>
```

3. Créez un bucket Cloud Storage pour les fichiers audio:
```bash
gsutil mb -l europe-west1 gs://xelkoom-audio-files
```

4. Configurez les variables d'environnement pour Cloud Run dans un fichier `.env.prod`:
```
DATABASE_URL=postgresql+asyncpg://xelkoom-user:<mot-de-passe>@/xelkoom?host=/cloudsql/<projet-id>:europe-west1:xelkoom-db
SECRET_KEY=<votre-clé-secrète>
AUDIO_STORAGE_TYPE=cloud
AUDIO_BUCKET_NAME=xelkoom-audio-files
CLOUD_STORAGE_LOCATION=europe-west1
```

5. Exécutez le script de déploiement:

Sur Linux/macOS:
```bash
chmod +x scripts/deploy_to_cloud_run.sh
scripts/deploy_to_cloud_run.sh
```

Sur Windows:
```bash
scripts\deploy_to_cloud_run.bat
```

Le script effectuera automatiquement:
- La création d'un fichier .dockerignore
- La construction de l'image Docker
- La configuration du bucket Cloud Storage
- Le déploiement sur Cloud Run avec les configurations appropriées

6. Exécutez les migrations de base de données:
```bash
gcloud run jobs create init-db \
  --image gcr.io/<projet-id>/xelkoom-backend \
  --command "python" \
  --args "scripts/manage.py,init-db,--migrate" \
  --set-env-vars="$(cat .env.prod | tr '\n' ',')" \
  --add-cloudsql-instances <projet-id>:europe-west1:xelkoom-db
```

7. Créez un administrateur:
```bash
gcloud run jobs create create-admin \
  --image gcr.io/<projet-id>/xelkoom-backend \
  --command "python" \
  --args "scripts/manage.py,admin" \
  --set-env-vars="$(cat .env.prod | tr '\n' ',')" \
  --add-cloudsql-instances <projet-id>:europe-west1:xelkoom-db
```

### Configuration d'un domaine personnalisé

Pour configurer un nom de domaine personnalisé avec HTTPS:

1. Mappez votre domaine à Cloud Run:
```bash
gcloud beta run domain-mappings create --service xelkoom-backend --domain api.xelkoom.com --region europe-west1
```

2. Suivez les instructions pour configurer vos enregistrements DNS.

### Surveillance et journalisation

Accédez à la surveillance et aux journaux via la console Google Cloud:

- Journaux: Cloud Logging > Logs Explorer
- Métriques: Cloud Monitoring > Dashboards
- Alertes: Cloud Monitoring > Alerting

## Sécurité

Le backend implémente:

- Authentification JWT avec rôles (admin, modérateur, utilisateur)
- Validation des entrées avec Pydantic
- Protection contre les injections SQL avec SQLAlchemy
- Limitation de débit (rate limiting)
- Journalisation des événements de sécurité
- CORS configuré pour les domaines autorisés
- Intégration avec Identity-Aware Proxy (IAP) possible pour Google Cloud

## Traitement audio

Le backend utilise FFmpeg pour:

- Normaliser les niveaux audio (16kHz, mono)
- Supprimer les silences des enregistrements
- Valider la qualité audio
- Stocker les métadonnées avec les enregistrements
- Analyser les caractéristiques audio (SNR, clarté)
