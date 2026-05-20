# Audit de Compatibilité UUID/Int

## Problème
L'application utilise des UUID comme identifiants primaires dans la base de données PostgreSQL, mais certaines parties du code étaient configurées pour utiliser des entiers. Lors de la migration vers SQLite, il est nécessaire de s'assurer que tous les endpoints et schémas acceptent les deux types d'identifiants.

## Modifications Effectuées

### 1. Schémas Pydantic (app/schemas/__init__.py)
- Changement de tous les champs ID de type `int` vers `Any` ou `Union[int, str]`
- Ajout de `arbitrary_types_allowed=True` dans la configuration des modèles
- Classes modifiées :
  - `UserResponse.id`
  - `SentenceResponse.id`
  - `RecordingResponse.id` et `RecordingResponse.user_id`
  - `RecordingBase.sentence_id`
  - `UserWithStats.id`
  - `LeaderboardEntry.user_id`
  - `BulkModerationRequest.recording_ids`

### 2. Routes API - Types de Paramètres
Changement de `int` vers `str` pour tous les paramètres de chemin représentant des ID :

#### app/api/routes/admin.py
- `get_user_by_id(user_id: str)`
- `update_user(user_id: str)`
- `activate_user(user_id: str)`
- `deactivate_user(user_id: str)`
- `delete_user(user_id: str)`
- `get_recording_audio(recording_id: str)`

#### app/api/routes/recordings.py
- `create_recording(sentence_id: str)`
- `get_recording(recording_id: str)`
- `delete_recording(recording_id: str)`

#### app/api/routes/sentences.py
- `get_sentence(sentence_id: str)`

### 3. Utilitaires de Conversion (app/core/pydantic_utils.py)
Création d'un nouveau fichier contenant :
- `convert_uuid_values()` : Convertit récursivement les UUID en chaînes
- `model_to_dict()` : Convertit les objets SQLAlchemy en dictionnaires compatibles Pydantic

### 4. Routes d'Authentification (app/api/routes/auth.py)
- Remplacement de l'ancienne fonction `prepare_model_for_validation`
- Utilisation de `model_to_dict` pour toutes les conversions
- Modification des routes : `register`, `login`, `get_current_user_info`, `refresh_token`

### 5. Configuration de Base de Données (app/models/__init__.py)
- Système déjà en place pour détecter automatiquement le type de base de données
- Utilisation conditionnelle d'UUID pour PostgreSQL et d'int pour SQLite

## Tests Nécessaires

1. **Tests de Régression :**
   - Inscription de nouveaux utilisateurs
   - Connexion avec utilisateurs existants (UUID)
   - Accès aux routes admin avec des UUID
   - Création et récupération d'enregistrements

2. **Tests de Compatibilité :**
   - Vérifier que les anciens ID UUID fonctionnent toujours
   - Vérifier que les nouveaux ID int fonctionnent avec SQLite
   - Tester la pagination avec différents types d'ID

3. **Tests d'API :**
   - Toutes les routes CRUD pour users, sentences, recordings
   - Routes d'administration
   - Téléchargement de fichiers audio

## Endpoints Potentiellement Affectés

- `DELETE /admin/users/{user_id}` ✅ Corrigé
- `GET /admin/users/{user_id}` ✅ Corrigé
- `PATCH /admin/users/{user_id}` ✅ Corrigé
- `POST /admin/users/{user_id}/activate` ✅ Corrigé
- `POST /admin/users/{user_id}/deactivate` ✅ Corrigé
- `GET /recordings/{recording_id}` ✅ Corrigé
- `DELETE /recordings/{recording_id}` ✅ Corrigé
- `POST /recordings/?sentence_id={sentence_id}` ✅ Corrigé
- `GET /sentences/{sentence_id}` ✅ Corrigé
- `GET /admin/recordings/{recording_id}/audio` ✅ Corrigé

## Actions de Suivi

1. **Déploiement :**
   - Pousser toutes les modifications vers le dépôt
   - Redéployer sur Render
   - Vérifier les logs pour d'éventuelles erreurs

2. **Monitoring :**
   - Surveiller les erreurs 422 dans les logs
   - Vérifier que les opérations CRUD fonctionnent correctement
   - Tester l'interface d'administration

3. **Documentation :**
   - Mettre à jour la documentation API si nécessaire
   - Informer l'équipe frontend des changements potentiels
