@echo off
REM Script de déploiement pour Google Cloud Run sous Windows

REM Variables à configurer
set PROJECT_ID=votre-projet-id
set REGION=europe-west1
set SERVICE_NAME=xelkoom-backend
set DB_INSTANCE=xelkoom-db
set DB_NAME=xelkoom
set DB_USER=xelkoom-user
set STORAGE_BUCKET=xelkoom-audio-files

REM Vérifier si .env.prod existe
if not exist .env.prod (
    echo Fichier .env.prod non trouvé. Veuillez créer ce fichier avec les variables d'environnement de production.
    exit /b 1
)

REM Confirmation avant de continuer
echo Ce script va déployer l'application sur Google Cloud Run avec les paramètres suivants :
echo - Projet: %PROJECT_ID%
echo - Région: %REGION%
echo - Service: %SERVICE_NAME%
echo - Base de données: %DB_INSTANCE%
echo - Bucket Storage: %STORAGE_BUCKET%
echo.
echo Assurez-vous d'avoir configuré correctement le fichier .env.prod
echo.
set /p CONTINUE=Continuer ? (y/n): 
if /i "%CONTINUE%" neq "y" exit /b 1

REM Vérifier si gcloud est installé
where gcloud >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo La commande gcloud n'est pas installée. Veuillez installer le Google Cloud SDK.
    exit /b 1
)

REM Vérifier si l'utilisateur est connecté à gcloud
gcloud auth list --filter=status:ACTIVE --format="value(account)" >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Vous n'êtes pas connecté à Google Cloud. Connectez-vous avec 'gcloud auth login'.
    exit /b 1
)

REM S'assurer que le projet est configuré
gcloud config set project %PROJECT_ID%

echo === Création d'un fichier .dockerignore ===
(
echo venv/
echo __pycache__/
echo *.pyc
echo .env
echo .env.*
echo .git/
echo .github/
echo .gitignore
echo *.md
echo tests/
) > .dockerignore

echo === Construction de l'image Docker ===
gcloud builds submit --tag gcr.io/%PROJECT_ID%/%SERVICE_NAME% .

echo === Création du bucket Cloud Storage pour les fichiers audio ===
gsutil mb -l %REGION% gs://%STORAGE_BUCKET% 2>nul
gsutil iam ch allUsers:objectViewer gs://%STORAGE_BUCKET% 2>nul

echo === Déploiement sur Cloud Run ===
set CONNECTION_NAME=%PROJECT_ID%:%REGION%:%DB_INSTANCE%

REM Extraire les variables d'environnement du fichier .env.prod
powershell -Command "$envVars = (Get-Content .env.prod) -join ','; Write-Output $envVars" > env_vars_temp.txt
set /p ENV_VARS=<env_vars_temp.txt
del env_vars_temp.txt

gcloud run deploy %SERVICE_NAME% ^
    --image gcr.io/%PROJECT_ID%/%SERVICE_NAME% ^
    --region %REGION% ^
    --platform managed ^
    --allow-unauthenticated ^
    --set-env-vars="%ENV_VARS%,CLOUD_SQL_CONNECTION_NAME=%CONNECTION_NAME%,GOOGLE_CLOUD_PROJECT=%PROJECT_ID%" ^
    --add-cloudsql-instances %CONNECTION_NAME% ^
    --memory 1Gi ^
    --cpu 1 ^
    --concurrency 80 ^
    --max-instances 10 ^
    --min-instances 1 ^
    --timeout 300s

echo === Application déployée avec succès ! ===
for /f "tokens=*" %%a in ('gcloud run services describe %SERVICE_NAME% --region %REGION% --format "value(status.url)"') do set URL=%%a
echo Vous pouvez accéder à votre application à l'adresse: %URL%
echo Documentation API: %URL%/docs
