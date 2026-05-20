# Settings System - Guide d'utilisation

## Vue d'ensemble

La page **Paramètres système** de Xelkoom Admin Dashboard fournit une vue complète de l'état de santé, de la configuration et des logs de la plateforme. Elle permet aux administrateurs de surveiller et diagnostiquer le système en temps réel.

## Fonctionnalités principales

### 1. État du système (SystemHealthCard)

#### Statut global
- **Sain** (Healthy) : Tous les services fonctionnent normalement
- **Dégradé** (Degraded) : Certains services rencontrent des problèmes mineurs
- **Erreur** (Error) : Problèmes critiques détectés

#### Métriques surveillées

**Base de données**
- Status de connexion
- Taille de la base de données SQLite
- Pool de connexions (N/A pour SQLite)

**Stockage**
- Nombre de fichiers audio
- Taille totale du stockage audio
- Utilisation du disque (pourcentage, espace libre/utilisé)
- Alerte automatique si utilisation > 90%

**Ressources système**
- Nombre de cœurs CPU
- Utilisation mémoire RAM (pourcentage et valeurs absolues)
- Alerte automatique si utilisation mémoire > 85%

### 2. Configuration système (SystemConfigCard)

Interface en lecture seule des paramètres de configuration actuels :

#### Audio
- Chemin de stockage des fichiers
- Taille maximale des fichiers (MB)

#### Sécurité
- Durée d'expiration des tokens JWT
- Algorithme de chiffrement utilisé

#### Limitation de débit
- État d'activation
- Limite par défaut (ex: "100/minute")

#### Fonctionnalités
- **Validation Whisper** : État et modèle utilisé
- **Métriques** : Collecte des statistiques activée/désactivée

#### Environnement
- Type d'environnement (development/production)
- Mode debug (activé/désactivé avec alerte si activé)
- Niveau de logging (INFO, DEBUG, WARNING, ERROR)

### 3. Logs système (SystemLogsCard)

#### Affichage des logs
- Table paginée avec 25/50/100 entrées par page
- Colonnes : Timestamp, Niveau, Module, Message
- Tri chronologique (plus récents en premier)

#### Filtrage par niveau
- **Tous** : Affiche tous les logs
- **ERROR** : Erreurs critiques uniquement
- **WARNING** : Avertissements et erreurs
- **INFO** : Informations générales
- **DEBUG** : Logs de débogage détaillés

#### Icônes et couleurs
- 🛈 **INFO** (Bleu) : Informations normales
- ⚠️ **WARNING** (Orange) : Avertissements
- ❌ **ERROR** (Rouge) : Erreurs
- 🐛 **DEBUG** (Gris) : Débogage

## Actions disponibles

### Actualiser
- Bouton "Actualiser" pour recharger toutes les données système
- Notifications toast pour succès/erreurs
- Désactivation pendant l'actualisation

### Exporter
- Bouton "Exporter" pour télécharger un rapport système complet
- Format JSON incluant :
  - Timestamp de l'export
  - État de santé système
  - Configuration complète
  - Résumé des logs actuels
- Nom de fichier automatique : `xelkoom-system-report-YYYY-MM-DD.json`

## API Backend

### Endpoints utilisés

#### GET /admin/system/health
```json
{
  "status": "healthy|degraded|error",
  "timestamp": "ISO_DATE",
  "database": {
    "status": "healthy",
    "size_bytes": 1048576,
    "connection_pool": "N/A (SQLite)"
  },
  "storage": {
    "audio_files_count": 150,
    "audio_storage_size_bytes": 52428800,
    "disk_total_bytes": 1000000000,
    "disk_used_bytes": 500000000,
    "disk_free_bytes": 500000000,
    "disk_usage_percent": 50.0
  },
  "system": {
    "memory_total_bytes": 8589934592,
    "memory_used_bytes": 4294967296,
    "memory_available_bytes": 4294967296,
    "memory_usage_percent": 50.0,
    "cpu_count": 8
  }
}
```

#### GET /admin/system/config
```json
{
  "audio": {
    "storage_path": "./audio/",
    "max_size_mb": 10
  },
  "rate_limiting": {
    "enabled": true,
    "default_limit": "100/minute"
  },
  "features": {
    "whisper_validation": false,
    "whisper_model": "base",
    "metrics_enabled": true
  },
  "environment": {
    "debug": true,
    "environment": "development",
    "log_level": "INFO"
  },
  "security": {
    "token_expire_minutes": 30,
    "algorithm": "HS256"
  }
}
```

#### GET /admin/system/logs
```json
{
  "items": [
    {
      "timestamp": "ISO_DATE",
      "level": "INFO|WARNING|ERROR|DEBUG",
      "message": "Log message",
      "module": "xelkoom.api"
    }
  ],
  "total": 1000,
  "page": 1,
  "size": 50,
  "pages": 20
}
```

## Composants créés

1. **SystemHealthCard.tsx** - Affichage de l'état de santé
2. **SystemConfigCard.tsx** - Configuration système
3. **SystemLogsCard.tsx** - Logs avec filtrage et pagination
4. **useSystem.ts** - Hook pour gestion des données système

## Dépendances backend ajoutées

- **psutil==5.9.6** - Monitoring des ressources système (CPU, mémoire, disque)

## Sécurité et limitations

### Données sensibles
- Les mots de passe et clés secrètes ne sont PAS exposés
- Seules les configurations "safe" sont affichées
- Interface en lecture seule (pas de modification)

### Limitations actuelles
- Logs simplifiés (mock data pour démonstration)
- Pas de modification de configuration en temps réel
- Monitoring basique (pas d'historique de tendances)

## Améliorations futures possibles

1. **Logs réels** : Intégration avec un système de logging avancé
2. **Configuration éditable** : Interface pour modifier certains paramètres
3. **Alertes automatiques** : Notifications par email/SMS sur seuils critiques
4. **Historiques** : Graphiques de tendances des ressources
5. **Backup système** : Fonctionnalités de sauvegarde
6. **Maintenance** : Actions de maintenance (nettoyage cache, logs, etc.)
7. **Monitoring avancé** : Intégration Prometheus/Grafana
