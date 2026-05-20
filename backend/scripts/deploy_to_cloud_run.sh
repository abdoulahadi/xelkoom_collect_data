#!/bin/bash

# Script de déploiement pour Google Cloud Run

set -e

# Variables à configurer
PROJECT_ID="votre-projet-id"
REGION="europe-west1"
SERVICE_NAME="xelkoom-backend"
DB_INSTANCE="xelkoom-db"
DB_NAME="xelkoom"
DB_USER="xelkoom-user"
STORAGE_BUCKET="xelkoom-audio-files"

# Vérifier si .env.prod existe
if [ ! -f .env.prod ]; then
    echo "Fichier .env.prod non trouvé. Veuillez créer ce fichier avec les variables d'environnement de production."
    exit 1
fi

# Confirmation avant de continuer
echo "Ce script va déployer l'application sur Google Cloud Run avec les paramètres suivants :"
echo "- Projet: $PROJECT_ID"
echo "- Région: $REGION"
echo "- Service: $SERVICE_NAME"
echo "- Base de données: $DB_INSTANCE"
echo "- Bucket Storage: $STORAGE_BUCKET"
echo ""
echo "Assurez-vous d'avoir configuré correctement le fichier .env.prod"
echo ""
read -p "Continuer ? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Vérifier si gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo "La commande gcloud n'est pas installée. Veuillez installer le Google Cloud SDK."
    exit 1
fi

# Vérifier si l'utilisateur est connecté à gcloud
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "Vous n'êtes pas connecté à Google Cloud. Connectez-vous avec 'gcloud auth login'."
    exit 1
fi

# S'assurer que le projet est configuré
gcloud config set project $PROJECT_ID

echo "=== Création d'un fichier .dockerignore ==="
cat << EOF > .dockerignore
venv/
__pycache__/
*.pyc
.env
.env.*
.git/
.github/
.gitignore
*.md
tests/
EOF

echo "=== Construction de l'image Docker ==="
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME .

echo "=== Création du bucket Cloud Storage pour les fichiers audio ==="
gsutil mb -l $REGION gs://$STORAGE_BUCKET || true
gsutil iam ch allUsers:objectViewer gs://$STORAGE_BUCKET || true

echo "=== Déploiement sur Cloud Run ==="
CONNECTION_NAME="$PROJECT_ID:$REGION:$DB_INSTANCE"

# Créer un fichier temporaire avec les variables d'environnement formatées pour gcloud
ENV_VARS=$(cat .env.prod | tr '\n' ',' | sed 's/,$//')

gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
    --region $REGION \
    --platform managed \
    --allow-unauthenticated \
    --set-env-vars="$ENV_VARS,CLOUD_SQL_CONNECTION_NAME=$CONNECTION_NAME,GOOGLE_CLOUD_PROJECT=$PROJECT_ID" \
    --add-cloudsql-instances $CONNECTION_NAME \
    --memory 1Gi \
    --cpu 1 \
    --concurrency 80 \
    --max-instances 10 \
    --min-instances 1 \
    --timeout 300s

echo "=== Application déployée avec succès ! ==="
URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')
echo "Vous pouvez accéder à votre application à l'adresse: $URL"
echo "Documentation API: $URL/docs"
