# Analytics - Guide d'utilisation

## Vue d'ensemble

La page Analytics de Xelkoom Admin Dashboard fournit une vue complète des métriques et des performances de la plateforme de collecte audio. Elle présente des données en temps réel sur les utilisateurs, les phrases, les enregistrements et l'activité générale.

## Fonctionnalités principales

### 1. Cartes de métriques principales (AnalyticsCards)
- **Utilisateurs** : Total des utilisateurs et nombre d'utilisateurs actifs
- **Phrases** : Total des phrases et phrases disponibles
- **Enregistrements** : Total des enregistrements et nombre validé
- **Durée audio totale** : Temps total de contenu audio validé

### 2. Statut des enregistrements (RecordingStatusCards)
- **En attente** : Enregistrements en attente de modération
- **Validés** : Enregistrements approuvés
- **Rejetés** : Enregistrements refusés
- **Total** : Nombre total d'enregistrements

### 3. Graphique d'activité quotidienne (DailyRecordingsChart)
- Visualisation de l'activité des 30 derniers jours
- Graphique en aires avec statistiques moyennes
- Tooltip détaillé pour chaque jour

### 4. Métriques d'engagement (EngagementMetrics)
- **Taux d'engagement** : Nombre moyen d'enregistrements par utilisateur
- **Taux de validation** : Pourcentage d'enregistrements approuvés
- **Utilisation des phrases** : Taux d'utilisation des phrases disponibles
- **Moyenne par utilisateur** : Enregistrements moyens par utilisateur actif

### 5. Filtre de période (PeriodFilter)
- Options : 7 jours, 30 jours, 90 jours, toutes les données
- Note : Actuellement utilisé pour l'affichage, le backend fournit les 30 derniers jours

## Actions disponibles

### Actualiser les données
- Bouton "Actualiser" pour recharger les métriques en temps réel
- Affichage de la dernière mise à jour
- Notifications toast pour les succès/erreurs

### Exporter les données
- Bouton "Exporter" pour télécharger les métriques au format JSON
- Inclut timestamp, période sélectionnée et toutes les métriques
- Nom de fichier automatique avec la date

## API Backend

### Endpoint utilisé
```
GET /admin/stats
```

### Données retournées (AdminStats)
```typescript
{
  total_users: number,
  active_users: number,
  total_sentences: number,
  available_sentences: number,
  total_recordings: number,
  pending_recordings: number,
  validated_recordings: number,
  rejected_recordings: number,
  total_audio_duration: number,
  daily_recordings: Array<{
    date: string,
    count: number
  }>
}
```

## Composants créés

1. **AnalyticsCards.tsx** - Cartes de métriques principales avec progression
2. **RecordingStatusCards.tsx** - Cartes de statut des enregistrements
3. **DailyRecordingsChart.tsx** - Graphique d'activité quotidienne (Recharts)
4. **EngagementMetrics.tsx** - Métriques d'engagement et KPIs
5. **PeriodFilter.tsx** - Sélecteur de période d'analyse

## Gestion d'état

- **Loading** : Indicateur de chargement pendant la récupération des données
- **Error** : Gestion des erreurs avec possibilité de réessayer
- **Refresh** : Actualisation manuelle avec feedback utilisateur
- **Export** : Export des données avec notifications de succès/erreur

## Indicateurs de performance (KPIs)

### Couleurs des tendances
- **Vert (success)** : Taux ≥ 70% (Excellent)
- **Orange (warning)** : Taux entre 40-69% (Moyen)
- **Rouge (error)** : Taux < 40% (Faible)

### Métriques calculées
- Taux d'engagement = (total_recordings / total_users) * 100
- Taux de validation = (validated_recordings / total_recordings) * 100
- Taux de rejet = (rejected_recordings / total_recordings) * 100
- Utilisation des phrases = (total_recordings / total_sentences) * 100

## Responsive Design

- Grille adaptative pour tous les écrans
- Cartes empilables sur mobile
- Graphiques responsifs avec Recharts
- Interface optimisée pour tablettes et desktop

## Améliorations futures possibles

1. **Filtres temporels backend** : Implémenter les filtres de période côté serveur
2. **Graphiques additionnels** : Graphiques de répartition par genre, âge, etc.
3. **Export Excel/CSV** : Formats d'export supplémentaires
4. **Comparaisons temporelles** : Métriques de progression vs période précédente
5. **Alertes automatiques** : Notifications pour seuils critiques
6. **Analytics en temps réel** : WebSocket pour mises à jour automatiques
