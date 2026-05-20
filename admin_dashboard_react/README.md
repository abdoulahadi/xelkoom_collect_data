# Xelkoom Admin Dashboard

Dashboard d'administration moderne pour la plateforme de collecte de données audio Xelkoom.

## 🚀 Fonctionnalités

- **Tableau de bord interactif** avec métriques en temps réel
- **Gestion des utilisateurs** avec filtres et actions en masse
- **Modération des enregistrements** avec interface audio
- **Analytics avancées** avec graphiques et exportations
- **Interface responsive** optimisée pour desktop et mobile
- **Authentification sécurisée** avec JWT
- **Notifications temps réel** via WebSocket
- **Thème moderne** avec Material-UI

## 🛠️ Technologies

- **Frontend**: React 18 + TypeScript
- **UI**: Material-UI (MUI) v5
- **State**: React Query + Context API

## 🌐 Déploiement sur Netlify

### Prérequis
- Compte GitHub
- Compte Netlify
- Repository GitHub configuré

### Configuration automatique
1. **Push du code sur GitHub** :
```bash
git add .
git commit -m "Prepare for Netlify deployment"
git push origin main
```

2. **Connexion Netlify-GitHub** :
   - Connectez-vous à [Netlify](https://netlify.com)
   - Cliquez sur "New site from Git"
   - Sélectionnez GitHub et autorisez l'accès
   - Choisissez votre repository

3. **Configuration du build** :
   - Build command: `npm run build`
   - Publish directory: `dist`
   - Node version: `18`

### Variables d'environnement Netlify
Configurez ces variables dans Netlify Dashboard > Site Settings > Environment Variables :

```
VITE_API_URL=https://votre-backend-api.com
VITE_WS_URL=https://votre-backend-api.com
VITE_DEV_MODE=false
VITE_LOG_LEVEL=error
VITE_APP_NAME=Xelkoom Admin
VITE_APP_VERSION=1.0.0
```

### Déploiement des previews
- **Pull Requests** : Déploiement automatique des previews
- **Branches** : Déploiement automatique pour test

### Configuration DNS (Optionnel)
Pour utiliser un domaine personnalisé :
1. Netlify Dashboard > Domain Settings
2. Ajoutez votre domaine
3. Configurez les DNS selon les instructions
- **Routing**: React Router v6
- **Build**: Vite
- **HTTP Client**: Axios
- **WebSocket**: Socket.IO Client
- **Notifications**: React Hot Toast

## 📦 Installation

1. **Cloner le projet**
```bash
git clone <repository-url>
cd admin_dashboard_react
```

2. **Installer les dépendances**
```bash
npm install
```

3. **Configuration**
```bash
# Copier le fichier d'environnement
cp .env.example .env

# Modifier les variables d'environnement
VITE_API_URL=http://localhost:8000
VITE_WS_URL=http://localhost:8000
```

## 🚀 Utilisation

### Développement
```bash
# Démarrer le serveur de développement
npm run dev

# L'application sera disponible sur http://localhost:3000
```

### Production
```bash
# Construire l'application
npm run build

# Prévisualiser le build
npm run preview
```

### Linting
```bash
# Vérifier le code
npm run lint
```

## 📁 Structure du projet

```
src/
├── components/           # Composants réutilisables
│   ├── Common/          # Composants communs
│   └── Layout/          # Composants de mise en page
├── contexts/            # Contextes React
├── pages/               # Pages de l'application
├── services/            # Services API
├── types/               # Types TypeScript
├── utils/               # Utilitaires
├── App.tsx             # Composant principal
├── main.tsx            # Point d'entrée
├── index.css           # Styles globaux
└── vite-env.d.ts       # Types Vite
```

## 🔐 Authentification

Le dashboard utilise l'authentification JWT. Les credentials par défaut sont configurés dans le backend.

### Rôles d'utilisateur
- **Admin**: Accès complet à toutes les fonctionnalités
- **Moderator**: Accès limité à la modération et aux statistiques

## 🎨 Personnalisation

### Thème
Le thème peut être personnalisé dans `src/main.tsx`:

```typescript
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2', // Couleur primaire
    },
    // ... autres couleurs
  },
});
```

### Styles
Les styles globaux sont dans `src/index.css` et peuvent être modifiés selon vos besoins.

## 📊 Fonctionnalités disponibles

### ✅ Implémentées
- [x] Authentification JWT
- [x] Tableau de bord avec métriques
- [x] Interface utilisateur moderne
- [x] Notifications temps réel
- [x] Responsive design
- [x] Gestion d'état avec React Query

### 🚧 En développement
- [ ] Modération des enregistrements
- [ ] Gestion des utilisateurs
- [ ] Analytics détaillées
- [ ] Paramètres système
- [ ] Export de données
- [ ] Tests unitaires

## 🔒 Sécurité

- Authentification JWT avec refresh tokens
- Validation des données côté client
- Protection contre les attaques XSS
- Gestion sécurisée des tokens
- Variables d'environnement pour la configuration

## 🐛 Dépannage

### Problèmes courants

1. **Erreur de connexion API**
   - Vérifier que le backend est démarré
   - Vérifier l'URL de l'API dans `.env`

2. **Erreurs de build**
   - Nettoyer les modules: `rm -rf node_modules && npm install`
   - Vérifier la version de Node.js (>= 16)

3. **WebSocket non connecté**
   - Vérifier que le serveur WebSocket est actif
   - Vérifier l'URL WebSocket dans `.env`

## 📝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push sur la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🤝 Support

Pour toute question ou problème:
- Ouvrir une issue sur GitHub
- Contacter l'équipe de développement

## 🔄 Versions

- **v1.0.0** - Version initiale avec tableau de bord et authentification
- **v1.1.0** - Ajout de la modération (prévu)
- **v1.2.0** - Gestion des utilisateurs (prévu)
- **v2.0.0** - Analytics avancées (prévu)
