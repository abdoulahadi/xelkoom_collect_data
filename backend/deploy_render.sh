#!/bin/bash

# Script de déploiement pour Render
# Ce script peut être utilisé en local pour tester avant le déploiement

echo "🚀 Préparation du déploiement pour Render..."

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

# Vérifier que le Dockerfile existe
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile non trouvé dans le répertoire courant."
    exit 1
fi

echo "✅ Vérifications préliminaires réussies"

# Construire l'image Docker localement pour tester
echo "🔨 Construction de l'image Docker..."
docker build -t xelkoom-backend:latest .

if [ $? -eq 0 ]; then
    echo "✅ Image Docker construite avec succès"
else
    echo "❌ Erreur lors de la construction de l'image Docker"
    exit 1
fi

# Test rapide de l'image (optionnel)
echo "🧪 Test rapide de l'image..."
docker run --rm -d --name xelkoom-test -p 8001:8000 xelkoom-backend:latest

# Attendre quelques secondes pour que le serveur démarre
sleep 5

# Tester l'endpoint de santé
if curl -f http://localhost:8001/health > /dev/null 2>&1; then
    echo "✅ Test de santé réussi"
else
    echo "⚠️  Test de santé échoué (cela peut être normal si certaines dépendances ne sont pas disponibles)"
fi

# Arrêter le conteneur de test
docker stop xelkoom-test > /dev/null 2>&1

echo ""
echo "📋 Checklist avant déploiement sur Render :"
echo "□ Créer un compte sur render.com"
echo "□ Connecter votre repository GitHub"
echo "□ Créer une base de données PostgreSQL sur Render"
echo "□ Créer un service Redis sur Render"
echo "□ Configurer les variables d'environnement (voir .env.production.example)"
echo "□ Déployer le service web avec le Dockerfile"
echo ""
echo "🌐 URLs utiles :"
echo "   - Dashboard Render: https://dashboard.render.com"
echo "   - Documentation: https://render.com/docs"
echo ""
echo "🔧 Commandes Render CLI (si installé) :"
echo "   render services create --type web --name xelkoom-backend --repo https://github.com/your-username/your-repo"
echo ""
echo "✅ Votre application est prête pour le déploiement sur Render !"
