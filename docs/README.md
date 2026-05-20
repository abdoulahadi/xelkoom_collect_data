# 🎯 **Xelkoom - Plateforme de collecte de données audio pour TTS en Wolof**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.11+-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-3.0+-blue.svg)
![FastAPI](https://img.shields.io/badge/fastapi-0.104+-green.svg)

## 📋 **Description**

**Xelkoom** est une plateforme complète et scalable conçue pour collecter des données vocales en langue Wolof afin d'entraîner des modèles Text-to-Speech (TTS). Le projet comprend une API backend robuste, une application mobile intuitive et un dashboard d'administration pour la modération des données.

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Mobile App     │    │   Backend API   │    │ Admin Dashboard │
│   (Flutter)     │◄──►│   (FastAPI)     │◄──►│     (Web)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │   + Audio       │
                    │   Storage       │
                    └─────────────────┘
```

## 🚀 **Fonctionnalités principales**

### 📱 **Application Mobile (Flutter)**
- ✅ Interface intuitive en français/wolof
- ✅ Enregistrement audio haute qualité (16kHz, mono)
- ✅ Visualisation des phrases à lire
- ✅ Suivi des statistiques personnelles
- ✅ Mode hors-ligne pour enregistrements
- ✅ Consentement RGPD intégré

### 🔧 **Backend API (FastAPI)**
- ✅ Authentification JWT sécurisée
- ✅ Gestion des utilisateurs et phrases
- ✅ Traitement audio automatique (FFmpeg + librosa)
- ✅ Validation et normalisation audio
- ✅ API RESTful complète avec documentation
- ✅ Base de données PostgreSQL
- ✅ Stockage local/S3 des fichiers audio

### 🧑‍💼 **Dashboard Admin (Web)**
- ✅ Modération des enregistrements
- ✅ Statistiques en temps réel
- ✅ Gestion des utilisateurs et phrases
- ✅ Export des données (CSV/ZIP)
- ✅ Interface responsive et moderne

## 📦 **Structure du projet**

```
xelkoom-data-collect/
├── backend/                 # API FastAPI
│   ├── app/
│   │   ├── api/routes/     # Routes de l'API
│   │   ├── core/           # Configuration et auth
│   │   ├── models/         # Modèles SQLAlchemy
│   │   ├── schemas/        # Schémas Pydantic
│   │   └── services/       # Services (audio, etc.)
│   ├── migrations/         # Migrations Alembic
│   ├── scripts/           # Scripts d'initialisation
│   └── requirements.txt   # Dépendances Python
├── mobile_app/            # Application Flutter
│   ├── lib/
│   │   ├── models/        # Modèles de données
│   │   ├── providers/     # État Riverpod
│   │   ├── screens/       # Écrans de l'app
│   │   └── services/      # Services API/Audio
│   └── pubspec.yaml      # Dépendances Flutter
├── admin_dashboard/       # Dashboard web
│   ├── index.html        # Interface principale
│   ├── styles.css        # Styles CSS
│   └── script.js         # JavaScript
└── README.md             # Documentation
```

## ⚡ **Installation et lancement**

### 🔧 **Prérequis**

- **Python 3.11+**
- **PostgreSQL 12+**
- **Flutter 3.0+**
- **FFmpeg** (pour le traitement audio)
- **Node.js 16+** (optionnel, pour le dashboard)

### 🐍 **Backend (FastAPI)**

1. **Installation des dépendances**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Configuration de la base de données**
   ```bash
   # Créer la base de données PostgreSQL
   createdb xelkoom_db
   
   # Copier et configurer l'environnement
   cp .env.example .env
   # Éditer .env avec vos paramètres
   ```

3. **Migrations et données initiales**
   ```bash
   # Exécuter les migrations
   alembic upgrade head
   
   # Initialiser avec des données d'exemple
   python scripts/init_db.py
   ```

4. **Lancement du serveur**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

   ➡️ **API disponible sur:** http://localhost:8000
   
   ➡️ **Documentation:** http://localhost:8000/docs

### 📱 **Application Mobile (Flutter)**

1. **Installation des dépendances**
   ```bash
   cd mobile_app
   flutter pub get
   ```

2. **Configuration de l'API**
   ```dart
   // lib/services/api_service.dart
   static const String baseUrl = 'http://YOUR_API_URL:8000';
   ```

3. **Lancement de l'application**
   ```bash
   # Android
   flutter run
   
   # iOS (nécessite Xcode)
   flutter run -d ios
   
   # Build pour production
   flutter build apk --release
   flutter build ios --release
   ```

### 🌐 **Dashboard Admin (Web)**

1. **Servir les fichiers statiques**
   ```bash
   cd admin_dashboard
   
   # Avec Python
   python -m http.server 3000
   
   # Avec Node.js
   npx serve . -p 3000
   ```

2. **Configuration de l'API**
   ```javascript
   // script.js
   const API_BASE_URL = 'http://localhost:8000';
   ```

   ➡️ **Dashboard disponible sur:** http://localhost:3000

## 🔐 **Authentification**

### **Comptes par défaut (après init_db.py)**
- **Admin:** `username: admin`
- **Utilisateurs test:** `fatou_diop`, `moussa_fall`, `awa_ndiaye`

### **Workflow d'authentification**
1. **Inscription** → Consentement RGPD requis
2. **Connexion** → Token JWT généré
3. **Accès API** → Token dans header `Authorization: Bearer <token>`

## 📡 **API Endpoints**

### **Authentification**
```
POST /auth/register    # Inscription utilisateur
POST /auth/login       # Connexion
GET  /auth/me          # Profil utilisateur
POST /auth/refresh     # Renouvellement token
```

### **Phrases**
```
GET  /sentences/next       # Prochaine phrase à enregistrer
GET  /sentences/          # Liste des phrases
GET  /sentences/{id}      # Phrase spécifique
```

### **Enregistrements**
```
POST /recordings/         # Upload enregistrement
GET  /recordings/         # Mes enregistrements
GET  /recordings/{id}     # Enregistrement spécifique
DELETE /recordings/{id}   # Supprimer enregistrement
```

### **Utilisateurs**
```
GET  /users/me           # Mon profil
PUT  /users/me           # Modifier profil
GET  /users/me/stats     # Mes statistiques
DELETE /users/me         # Supprimer compte (RGPD)
```

### **Admin**
```
GET  /admin/stats                    # Statistiques globales
GET  /admin/recordings              # Enregistrements à modérer
PUT  /admin/recordings/{id}         # Modérer enregistrement
POST /admin/sentences               # Ajouter phrase
GET  /admin/export/metadata         # Export métadonnées
```

## 🎙️ **Traitement Audio**

### **Spécifications**
- **Format:** WAV, mono, 16kHz
- **Durée:** 1-30 secondes
- **Taille max:** 10MB

### **Pipeline de traitement**
1. **Validation** → Format et taille
2. **Normalisation** → -20dB RMS
3. **Nettoyage** → Suppression silences
4. **Qualité** → Score automatique
5. **Stockage** → Système local/S3

## 📊 **Base de données**

### **Modèle conceptuel**
```sql
Users (id, username, gender, age_range, consent_given, is_admin)
  ↓
Recordings (id, user_id, sentence_id, filepath, duration, status, quality_score)
  ↓
Sentences (id, text, language, difficulty_level, status)
```

### **Statuts des enregistrements**
- **`pending`** → En attente de modération
- **`validated`** → Approuvé pour l'entraînement
- **`rejected`** → Rejeté (qualité insuffisante)

## 🚀 **Déploiement Production**

### **Backend (Docker)**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### **Variables d'environnement**
```bash
DATABASE_URL=postgresql://user:pass@db:5432/xelkoom_prod
SECRET_KEY=your-production-secret-key
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AWS_BUCKET_NAME=xelkoom-audio-prod
REDIS_URL=redis://redis:6379/0
```

### **Mobile App (Build)**
```bash
# Android
flutter build apk --release --target-platform android-arm64

# iOS
flutter build ios --release
```

## 📈 **Monitoring et Analytics**

### **Métriques clés**
- Nombre total d'utilisateurs actifs
- Enregistrements par jour/semaine
- Taux de validation/rejet
- Durée totale d'audio collecté
- Qualité moyenne des enregistrements

### **Logs et erreurs**
- Authentification et accès
- Uploads et traitements audio
- Erreurs API et performances
- Actions de modération admin

## 🧪 **Tests**

### **Backend**
```bash
cd backend
pytest tests/ -v --cov=app
```

### **Mobile**
```bash
cd mobile_app
flutter test
flutter integration_test
```

## 🤝 **Contribution**

1. **Fork** le projet
2. **Créer** une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. **Commiter** les changements (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. **Push** vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. **Ouvrir** une Pull Request

## 📝 **Export TTS (Format LJSpeech)**

```
audio_001.wav|Jàngalekat dafay wax ci wolof.
audio_002.wav|Dafa wër ci boppam.
audio_003.wav|Nit ku baax la.
```

### **Métadonnées exportées**
- Nom du fichier audio
- Texte transcrit
- Durée d'enregistrement
- Score de qualité
- Informations du locuteur (anonymisées)

## 🛡️ **Sécurité et RGPD**

- ✅ **Consentement explicite** requis à l'inscription
- ✅ **Droit à l'oubli** → Suppression compte et données
- ✅ **Chiffrement** des tokens JWT
- ✅ **Validation** stricte des entrées utilisateur
- ✅ **Anonymisation** des exports
- ✅ **Logs d'audit** des actions admin

## 📞 **Support et Contact**

- **Issues GitHub:** [Ouvrir un ticket](https://github.com/votre-repo/xelkoom/issues)
- **Documentation API:** http://localhost:8000/docs
- **Email:** support@xelkoom.com

## 📄 **Licence**

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

**🎉 Merci de contribuer au développement de la technologie vocale en Wolof !**

*Fait avec ❤️ pour la communauté wolof et l'avancement de la technologie en Afrique de l'Ouest*
