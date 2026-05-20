# Guide de Gestion des Phrases - Xelkoom Admin Dashboard

## Vue d'ensemble

La page **Gestion des Phrases** permet aux administrateurs et modérateurs de gérer le corpus de phrases utilisées pour la collecte d'enregistrements audio en wolof. Cette interface offre des fonctionnalités complètes de création, modification, suppression et organisation des phrases.

## Fonctionnalités Principales

### 1. Tableau de Bord des Statistiques

#### Cartes de Métriques
- **Total des phrases** : Nombre total de phrases dans le système
- **Enregistrements** : Nombre total d'enregistrements associés aux phrases
- **Phrases actives** : Nombre et pourcentage de phrases activées
- **Phrases inactives** : Nombre et pourcentage de phrases désactivées

#### Statistiques Détaillées
- **Répartition par difficulté** : Distribution des phrases par niveau (facile, moyen, difficile)
- **Répartition par langue** : Distribution des phrases par langue (WO, FR, EN)

### 2. Gestion des Phrases

#### Création de Phrases

**Création Individuelle :**
1. Cliquez sur "Nouvelle phrase"
2. Remplissez le formulaire :
   - **Texte** : Le contenu de la phrase (max 1000 caractères)
   - **Langue** : Wolof, Français, ou Anglais
   - **Difficulté** : Facile, Moyen, ou Difficile
3. Cliquez sur "Créer"

**Création en Masse (Bulk) :**
1. Cliquez sur "Import Bulk"
2. Entrez les phrases (une par ligne) dans la zone de texte
3. Les phrases seront créées avec les paramètres par défaut :
   - Langue : Wolof
   - Difficulté : Facile
   - Statut : Actif
4. Cliquez sur "Créer X phrases"

#### Modification de Phrases
1. Localisez la phrase dans le tableau
2. Cliquez sur l'icône "Modifier" (crayon)
3. Modifiez les champs nécessaires
4. Cliquez sur "Modifier"

#### Suppression de Phrases
1. Localisez la phrase dans le tableau
2. Cliquez sur l'icône "Supprimer" (poubelle)
3. Confirmez la suppression dans le dialogue

⚠️ **Attention** : La suppression est irréversible

#### Activation/Désactivation
1. Localisez la phrase dans le tableau
2. Cliquez sur l'icône de basculement (toggle)
3. Le statut change immédiatement

### 3. Recherche et Filtres

#### Barre de Recherche
- Recherche dans le texte des phrases
- Recherche en temps réel pendant la saisie
- Appuyez sur Entrée ou cliquez sur l'icône de recherche

#### Filtres Disponibles
- **Statut** : Toutes, Actives, Inactives
- **Difficulté** : Toutes, Facile, Moyen, Difficile

#### Actions de Filtrage
- **Filtrer** : Applique les filtres sélectionnés
- **Effacer** : Remet à zéro tous les filtres

### 4. Navigation et Affichage

#### Tableau Principal
- **Colonnes** : ID, Texte, Langue, Difficulté, Statut, Enregistrements, Date de création
- **Sélection** : Cases à cocher pour sélection multiple
- **Pagination** : Navigation entre les pages (10, 25, 50, 100 lignes par page)
- **Tri** : Tri par colonnes (si activé)

#### Actions en Lot
- Sélectionnez plusieurs phrases avec les cases à cocher
- Utilisez la barre d'outils qui apparaît pour des actions groupées
- Actions disponibles : Suppression en lot (si autorisé)

### 5. Export de Données

#### Format d'Export
- **Format** : JSON
- **Nom du fichier** : `sentences_YYYY-MM-DD.json`
- **Contenu** : Toutes les données des phrases visibles

#### Données Exportées
```json
{
  "id": 123,
  "text": "Texte de la phrase",
  "language": "wo",
  "difficulty_level": "easy",
  "is_active": true,
  "recording_count": 5,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-02T00:00:00Z"
}
```

## Permissions et Rôles

### Administrateur
- ✅ Création de phrases
- ✅ Modification de phrases
- ✅ Suppression de phrases
- ✅ Activation/Désactivation
- ✅ Import en masse
- ✅ Export de données
- ✅ Accès à toutes les statistiques

### Modérateur
- ✅ Création de phrases
- ✅ Modification de phrases
- ❌ Suppression de phrases (selon configuration)
- ✅ Activation/Désactivation
- ✅ Import en masse
- ✅ Export de données
- ✅ Accès à toutes les statistiques

### Utilisateur
- ❌ Aucun accès à cette section

## Bonnes Pratiques

### Création de Phrases
1. **Qualité du Contenu**
   - Utilisez des phrases grammaticalement correctes
   - Vérifiez l'orthographe avant la création
   - Adaptez la difficulté au contenu

2. **Organisation**
   - Créez des phrases de différents niveaux de difficulté
   - Équilibrez les langues selon vos besoins
   - Activez seulement les phrases prêtes pour l'enregistrement

3. **Import en Masse**
   - Préparez vos phrases dans un fichier texte
   - Une phrase par ligne
   - Vérifiez le contenu avant l'import

### Gestion Quotidienne
1. **Surveillance**
   - Vérifiez régulièrement les statistiques
   - Surveillez le ratio phrases actives/inactives
   - Analysez les enregistrements par phrase

2. **Maintenance**
   - Désactivez les phrases problématiques
   - Mettez à jour le contenu si nécessaire
   - Supprimez les doublons

3. **Performance**
   - Maintenez un nombre approprié de phrases actives
   - Équilibrez les niveaux de difficulté
   - Surveillez la charge sur les enregistrements

## Résolution de Problèmes

### Problèmes Courants

**Erreur lors de la création :**
- Vérifiez la longueur du texte (max 1000 caractères)
- Assurez-vous que le texte n'est pas vide
- Vérifiez votre connexion réseau

**Filtres ne fonctionnent pas :**
- Cliquez sur "Filtrer" après avoir sélectionné les critères
- Utilisez "Effacer" pour remettre à zéro
- Actualisez la page si nécessaire

**Données non mises à jour :**
- Utilisez le bouton "Actualiser" (🔄)
- Vérifiez votre connexion
- Rechargez la page si nécessaire

### Messages d'Erreur

- **"Erreur lors du chargement"** : Problème de connexion au serveur
- **"Phrase trop longue"** : Réduisez le texte à moins de 1000 caractères
- **"Accès refusé"** : Vérifiez vos permissions
- **"Phrase introuvable"** : La phrase a peut-être été supprimée par un autre utilisateur

## Support Technique

En cas de problème persistant :
1. Notez le message d'erreur exact
2. Vérifiez votre rôle et vos permissions
3. Contactez l'équipe technique avec :
   - Description du problème
   - Actions effectuées
   - Captures d'écran si pertinentes
