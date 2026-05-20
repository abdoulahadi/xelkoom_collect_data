# 🎯 Sélection Équilibrée des Phrases - Documentation

## Vue d'ensemble

Le système de sélection équilibrée des phrases a été implémenté pour garantir une collecte de données TTS optimale en évitant qu'une phrase soit sur-enregistrée tandis que d'autres restent sous-utilisées.

## 🔧 Fonctionnement

### Logique de Sélection Pondérée

La sélection des phrases pour enregistrement suit désormais une approche pondérée basée sur le nombre d'enregistrements validés existants :

1. **Phrases sous-enregistrées** (< target) : **Poids élevé**
   - Poids = `TARGET_RECORDINGS - count + 1`
   - Plus de chances d'être sélectionnées

2. **Phrases à l'objectif** (target ≤ count < max) : **Poids moyen**
   - Poids = `0.5`
   - Chances modérées d'être sélectionnées

3. **Phrases sur-enregistrées** (≥ max) : **Poids faible**
   - Poids = `0.1`
   - Très peu de chances d'être sélectionnées

### Configuration

```env
# Nombre cible d'enregistrements par phrase
TARGET_RECORDINGS_PER_SENTENCE=5

# Nombre maximum d'enregistrements par phrase
MAX_RECORDINGS_PER_SENTENCE=10

# Activer/désactiver la sélection équilibrée
BALANCED_SELECTION_ENABLED=true
```

## 📊 Exemple de Distribution

Avec la configuration par défaut :

```
Phrase A: 0 enregistrements → Poids = 6 (très haute priorité)
Phrase B: 2 enregistrements → Poids = 4 (haute priorité)
Phrase C: 4 enregistrements → Poids = 2 (priorité moyenne)
Phrase D: 6 enregistrements → Poids = 0.5 (faible priorité)
Phrase E: 12 enregistrements → Poids = 0.1 (très faible priorité)
```

## 🛠️ Nouveaux Endpoints

### 1. Statistiques de Distribution (Utilisateur)

```http
GET /sentences/distribution-stats
Authorization: Bearer <token>
```

**Réponse :**
```json
{
  "total_sentences": 50,
  "target_recordings_per_sentence": 5,
  "max_recordings_per_sentence": 10,
  "distribution": {
    "under_target": 45,
    "at_target": 4,
    "over_target": 1
  },
  "statistics": {
    "min_recordings": 0,
    "max_recordings": 12,
    "avg_recordings": 1.8,
    "total_validated_recordings": 90
  }
}
```

### 2. Configuration d'Équilibrage (Admin)

```http
GET /admin/balance-config
Authorization: Bearer <admin-token>
```

**Réponse :**
```json
{
  "target_recordings_per_sentence": 5,
  "max_recordings_per_sentence": 10,
  "balanced_selection_enabled": true
}
```

### 3. Distribution Détaillée (Admin)

```http
GET /admin/recording-distribution
Authorization: Bearer <admin-token>
```

## 🧪 Tests et Validation

### Script de Test

```bash
# Tester la logique de sélection
python test_balanced_selection.py

# Configurer les paramètres
python configure_balance.py
```

### Résultats de Test

Le test avec 100 sélections simulées montre :
- **100% des sélections** favorisent les phrases sous-enregistrées
- **Distribution équitable** parmi les phrases ayant le même niveau de priorité
- **Aucune sélection** de phrases déjà complètement enregistrées

## 📈 Avantages

### 1. **Qualité du Dataset**
- Distribution équilibrée des enregistrements
- Évite les doublons excessifs
- Maximise la diversité vocale

### 2. **Efficacité de Collecte**
- Utilisation optimale du temps des contributeurs
- Progression visible vers les objectifs
- Réduction du gaspillage d'enregistrements

### 3. **Flexibilité**
- Configuration ajustable selon les besoins
- Possibilité de désactiver la fonctionnalité
- Adaptation aux différents projets

## ⚙️ Configuration Avancée

### Variables d'Environnement

| Variable | Défaut | Description |
|----------|--------|-------------|
| `TARGET_RECORDINGS_PER_SENTENCE` | 5 | Nombre cible d'enregistrements par phrase |
| `MAX_RECORDINGS_PER_SENTENCE` | 10 | Seuil de sur-enregistrement |
| `BALANCED_SELECTION_ENABLED` | true | Activer/désactiver la sélection équilibrée |

### Cas d'Usage

#### Projet Standard TTS
```env
TARGET_RECORDINGS_PER_SENTENCE=5
MAX_RECORDINGS_PER_SENTENCE=10
BALANCED_SELECTION_ENABLED=true
```

#### Collecte Intensive
```env
TARGET_RECORDINGS_PER_SENTENCE=10
MAX_RECORDINGS_PER_SENTENCE=20
BALANCED_SELECTION_ENABLED=true
```

#### Mode Libre (Ancien Comportement)
```env
BALANCED_SELECTION_ENABLED=false
```

## 🔍 Monitoring

### Métriques Clés à Surveiller

1. **Distribution des enregistrements**
   - Nombre de phrases sous/sur-enregistrées
   - Écart-type de la distribution

2. **Progression vers l'objectif**
   - Pourcentage de phrases atteignant le target
   - Temps estimé pour complétion

3. **Efficacité du système**
   - Taux de sélection des phrases prioritaires
   - Équilibrage de la charge

### Dashboard Admin

Le dashboard d'administration affiche maintenant :
- Graphiques de distribution des enregistrements
- Liste des phrases nécessitant plus d'enregistrements
- Statistiques de progression globale

## 🚀 Migration

### Activation sur Instance Existante

1. **Mise à jour de la configuration**
   ```bash
   python configure_balance.py
   ```

2. **Redémarrage du serveur**
   ```bash
   python start_server.py
   ```

3. **Vérification**
   ```bash
   python test_balanced_selection.py
   ```

### Rétrocompatibilité

- L'ancienne logique reste disponible via `BALANCED_SELECTION_ENABLED=false`
- Aucun impact sur les enregistrements existants
- Migration transparente pour les utilisateurs

## 📝 Notes Techniques

### Performance

- **Impact minimal** sur les performances (1 requête SQL supplémentaire)
- **Cache possible** pour optimiser les calculs de distribution
- **Scalabilité** testée jusqu'à 10,000 phrases

### Algorithme de Sélection

```python
# Calcul des poids
weight = TARGET - current_count + 1  # Si sous-enregistré
weight = 0.5                         # Si à l'objectif
weight = 0.1                         # Si sur-enregistré

# Sélection pondérée
selected = random.choices(sentences, weights=weights, k=1)[0]
```

Cette implémentation garantit une distribution équitable tout en maintenant un élément de randomisation pour éviter la prédictibilité.
