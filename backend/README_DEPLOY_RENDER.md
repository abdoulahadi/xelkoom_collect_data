# Déploiement sur Render

Ce guide vous explique comment déployer l'application Xelkoom backend sur Render.

## 📋 Prérequis

- Compte GitHub avec votre code source
- Compte Render (gratuit) : [render.com](https://render.com)
- Docker installé localement (pour les tests)

## 🚀 Étapes de déploiement

### 1. Préparation du repository

Assurez-vous que tous les fichiers nécessaires sont dans votre repository :
- `Dockerfile`
- `requirements.txt`
- `.dockerignore`
- `render.yaml` (optionnel, pour infrastructure as code)

### 2. Créer les services sur Render

#### a) Base de données PostgreSQL
1. Allez sur [dashboard.render.com](https://dashboard.render.com)
2. Cliquez sur "New +" → "PostgreSQL"
3. Configurez :
   - **Name** : `xelkoom-db`
   - **Database** : `xelkoom`
   - **User** : `xelkoom_user`
   - **Region** : Frankfurt (ou Oregon)
   - **Plan** : Starter (gratuit)

#### b) Redis (pour rate limiting)
1. Cliquez sur "New +" → "Redis"
2. Configurez :
   - **Name** : `xelkoom-redis`
   - **Region** : Frankfurt (même que la DB)
   - **Plan** : Starter (gratuit)

#### c) Service Web
1. Cliquez sur "New +" → "Web Service"
2. Connectez votre repository GitHub
3. Configurez :
   - **Name** : `xelkoom-backend`
   - **Runtime** : Docker
   - **Region** : Frankfurt
   - **Branch** : main
   - **Dockerfile Path** : `./Dockerfile`
   - **Plan** : Starter (gratuit, ou Standard si besoin de plus de ressources)

### 3. Configuration des variables d'environnement

Dans les paramètres du service web, ajoutez ces variables :

#### Variables obligatoires
```bash
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO
DATABASE_URL=[Auto-généré par Render depuis votre DB PostgreSQL]
SECRET_KEY=[Générer une clé de 32+ caractères]
REDIS_URL=[Auto-généré par Render depuis votre Redis]
```

#### Variables administrateur (recommandé)
```bash
# Configuration de l'administrateur
ADMIN_USERNAME=xelkoom_admin
ADMIN_PASSWORD=[Votre mot de passe fort personnalisé]
```

#### Variables CORS (adaptez à vos domaines)
```bash
ALLOW_ORIGINS=https://your-frontend-domain.com,https://your-app.onrender.com
```

#### Variables optionnelles
```bash
# Rate limiting
ENABLE_RATE_LIMITING=true
DEFAULT_RATE_LIMIT=100/minute

# AWS S3 (si utilisé)
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_BUCKET_NAME=your_bucket_name
AWS_REGION=us-east-1

# Monitoring
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id

# Audio processing (désactivé par défaut pour économiser les ressources)
ENABLE_WHISPER_VALIDATION=false
```

### 4. Déploiement

1. Commitez et poussez vos changements sur GitHub
2. Render détectera automatiquement les changements et démarrera le build
3. Le build prendra quelques minutes (compilation des dépendances audio)
4. Vérifiez les logs pour s'assurer que tout fonctionne

## 🔧 Test local avec Docker

Avant de déployer, testez localement :

### Windows
```bash
./deploy_render.bat
```

### Linux/Mac
```bash
chmod +x deploy_render.sh
./deploy_render.sh
```

## 📊 Monitoring et logs

### Accès aux logs
- Allez dans votre service sur le dashboard Render
- Onglet "Logs" pour voir les logs en temps réel
- Onglet "Metrics" pour voir l'utilisation des ressources

### Health checks
L'application expose plusieurs endpoints pour le monitoring :
- `GET /health` : Status de santé
- `GET /` : Information générale de l'API

## 🔒 Sécurité

### Utilisateur administrateur
Un compte administrateur est automatiquement créé au démarrage de l'application avec les informations suivantes :
- **Nom d'utilisateur**: `xelkoom_admin`
- **Mot de passe**: `X3lk00m@dmin2025!SecureP@ss`

⚠️ **IMPORTANT**: Pour des raisons de sécurité, il est recommandé de :
1. Changer ce mot de passe immédiatement après le premier déploiement
2. Utiliser la variable d'environnement `ADMIN_PASSWORD` sur Render pour définir votre propre mot de passe sécurisé
3. Ne jamais partager ces informations dans des fichiers publics

Pour changer le mot de passe après déploiement :
```bash
# Via le terminal interactif de Render
python scripts/set_password.py --username xelkoom_admin --password "VotreNouveauMotDePasseSecurisé"
```

### Variables secrètes
- Utilisez des clés secrètes fortes (32+ caractères)
- Ne commitez jamais les vraies valeurs dans git
- Utilisez les variables d'environnement de Render

### CORS
Configurez `ALLOW_ORIGINS` avec vos vrais domaines en production.

## 📈 Scaling

### Plans Render
- **Starter** (gratuit) : 512MB RAM, 0.1 CPU, endormissement après 15min d'inactivité
- **Standard** (7$/mois) : 512MB RAM, 0.5 CPU, pas d'endormissement
- **Pro** (25$/mois) : 2GB RAM, 1 CPU, auto-scaling

### Optimisations
- Utilisez Redis pour le cache
- Activez la compression gzip (déjà configurée)
- Optimisez les requêtes de base de données

## 🐛 Dépannage

### Erreurs courantes

#### Build qui échoue
- Vérifiez les logs de build
- Assurez-vous que `requirements.txt` est correct
- Vérifiez que Docker peut construire l'image localement

#### Service qui ne démarre pas
- Vérifiez les variables d'environnement
- Regardez les logs de démarrage
- Vérifiez que la base de données est accessible

#### Problèmes de connexion à la DB
- Vérifiez que `DATABASE_URL` est correctement configuré
- Assurez-vous que les services sont dans la même région

### Commandes utiles

#### Accès aux logs via CLI Render
```bash
# Installer Render CLI
npm install -g @render/cli

# Voir les logs
render logs --service-id your-service-id

# Redémarrer le service
render restart --service-id your-service-id
```

## 🔗 Liens utiles

- [Documentation Render](https://render.com/docs)
- [Dashboard Render](https://dashboard.render.com)
- [Status Render](https://status.render.com)
- [Support Render](https://render.com/support)

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs sur le dashboard Render
2. Consultez la documentation Render
3. Testez localement avec Docker
4. Contactez le support Render si nécessaire
