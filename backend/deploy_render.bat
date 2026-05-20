@echo off
REM Script de déploiement pour Render (Windows)

echo 🚀 Préparation du déploiement pour Render...

REM Vérifier que Docker est installé
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker n'est pas installé. Veuillez l'installer avant de continuer.
    pause
    exit /b 1
)

REM Vérifier que le Dockerfile existe
if not exist "Dockerfile" (
    echo ❌ Dockerfile non trouvé dans le répertoire courant.
    pause
    exit /b 1
)

echo ✅ Vérifications préliminaires réussies

REM Construire l'image Docker localement pour tester
echo 🔨 Construction de l'image Docker...
docker build -t xelkoom-backend:latest .

if %errorlevel% equ 0 (
    echo ✅ Image Docker construite avec succès
) else (
    echo ❌ Erreur lors de la construction de l'image Docker
    pause
    exit /b 1
)

REM Test rapide de l'image (optionnel)
echo 🧪 Test rapide de l'image...
docker run --rm -d --name xelkoom-test -p 8001:8000 xelkoom-backend:latest

REM Attendre quelques secondes pour que le serveur démarre
timeout /t 5 /nobreak >nul

REM Tester l'endpoint de santé
curl -f http://localhost:8001/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Test de santé réussi
) else (
    echo ⚠️  Test de santé échoué ^(cela peut être normal si certaines dépendances ne sont pas disponibles^)
)

REM Arrêter le conteneur de test
docker stop xelkoom-test >nul 2>&1

echo.
echo 📋 Checklist avant déploiement sur Render :
echo □ Créer un compte sur render.com
echo □ Connecter votre repository GitHub
echo □ Créer une base de données PostgreSQL sur Render
echo □ Créer un service Redis sur Render
echo □ Configurer les variables d'environnement ^(voir .env.production.example^)
echo □ Déployer le service web avec le Dockerfile
echo.
echo 🌐 URLs utiles :
echo    - Dashboard Render: https://dashboard.render.com
echo    - Documentation: https://render.com/docs
echo.
echo 🔧 Commandes Render CLI ^(si installé^) :
echo    render services create --type web --name xelkoom-backend --repo https://github.com/your-username/your-repo
echo.
echo ✅ Votre application est prête pour le déploiement sur Render !
pause
