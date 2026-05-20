# PRD — Audit & Corrections Rigoureuses : Plateforme Xelkoom Data Collect

**Version :** 1.0
**Date :** 20 mars 2026
**Auteur :** Équipe Engineering — Audit Interne
**Statut :** En attente de validation

---

## 1. Contexte & Objectif

### 1.1 Contexte
Xelkoom Data Collect est une plateforme de collecte de données audio pour l'entraînement TTS (Text-to-Speech) en langue Wolof. Elle se compose de :
- **Backend** : API REST FastAPI + PostgreSQL
- **Dashboard Admin** : Application React (Vite + MUI)
- **Application Mobile** : Flutter (Riverpod) pour l'enregistrement audio

Le projet vise un **déploiement à l'échelle nationale** au Sénégal.

### 1.2 Objectif du PRD
Ce document recense de manière exhaustive les **anomalies, incohérences et vulnérabilités** détectées lors de l'audit complet du code source. Chaque problème est classifié, localisé avec précision (fichier + ligne), et accompagné d'une correction prescrite. L'objectif est de servir de **feuille de route technique** pour rendre le projet production-ready.

### 1.3 Méthodologie d'audit
- Lecture intégrale de chaque fichier source des 3 composants
- Vérification croisée des contrats API (backend ↔ frontend ↔ mobile)
- Analyse statique de sécurité (OWASP Top 10)
- Revue des schemas de base de données et migrations
- Évaluation de la conformité RGPD

---

## 2. Score de Maturité Actuel

| Domaine | Score | Cible prod |
|---------|-------|------------|
| Sécurité | 3/10 | 8/10 |
| Architecture Backend | 5/10 | 8/10 |
| Dashboard Admin | 5/10 | 8/10 |
| App Mobile | 4/10 | 8/10 |
| Cohérence inter-composants | 3/10 | 9/10 |
| Conformité RGPD | 3/10 | 8/10 |
| Scalabilité | 4/10 | 8/10 |
| Couverture de tests | 2/10 | 7/10 |
| **Score global** | **3.6/10** | **8/10** |

---

## 3. Classification des Priorités

| Priorité | Signification | SLA |
|----------|--------------|-----|
| **P0** | Critique — Bloquant pour tout déploiement. Faille de sécurité exploitable ou corruption de données. | Immédiat |
| **P1** | Haut — Impacte fortement la fiabilité, la sécurité ou l'expérience utilisateur. | Sprint 1 |
| **P2** | Moyen — Dégradation de qualité, dette technique, incohérence. | Sprint 2-3 |
| **P3** | Bas — Amélioration, nettoyage, bonnes pratiques. | Backlog |

---

## 4. Inventaire des Corrections

### 4.1 SÉCURITÉ

---

#### SEC-001 · P0 · Bypass d'authentification sans mot de passe

**Fichier :** `backend/app/core/auth.py` — Lignes 64-77
**Code actuel :**
```python
def authenticate_user(db: Session, username: str, password: str = None) -> Optional[User]:
    user = get_user_by_username(db, username)
    if not user or not user.is_active:
        return None
    if password and user.hashed_password:
        if not verify_password(password, user.hashed_password):
            return None
    return user
```
**Problème :** Si `password` est `None` ou si l'utilisateur n'a pas de `hashed_password`, la fonction retourne l'utilisateur sans aucune vérification. Tout compte sans mot de passe est accessible par simple connaissance du username.

**Correction prescrite :**
```python
def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
    user = get_user_by_username(db, username)
    if not user or not user.is_active:
        return None
    if not user.hashed_password:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user
```

**Impact :** Les comptes existants sans mot de passe seront inaccessibles → prévoir une migration pour forcer un reset password.

---

#### SEC-002 · P0 · Inscription sans mot de passe autorisée

**Fichier :** `backend/app/schemas/__init__.py` — Ligne 15
**Code actuel :**
```python
class UserCreate(UserBase):
    password: Optional[str] = Field(None, min_length=6, description="User password, optional")
```
**Fichier :** `backend/app/api/routes/auth.py` — Ligne 42
```python
hashed_password=get_password_hash(user_data.password) if hasattr(user_data, 'password') and user_data.password else None,
```
**Problème :** Un utilisateur peut s'inscrire sans mot de passe, créant un compte vulnérable (voir SEC-001).

**Correction prescrite :**
```python
class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=128, description="User password, required")
```
Et dans `auth.py` registration :
```python
hashed_password=get_password_hash(user_data.password),
```

---

#### SEC-003 · P0 · SECRET_KEY par défaut prévisible

**Fichier :** `backend/app/core/config.py` — Ligne 9
**Code actuel :**
```python
SECRET_KEY: str = "your-secret-key-here-change-in-production"
```
**Problème :** Si `.env` est absent, les JWT sont signés avec une clé publiquement connue. N'importe qui peut forger des tokens admin.

**Correction prescrite :**
```python
SECRET_KEY: str  # Pas de valeur par défaut — DOIT être défini via variable d'environnement
```
Ajouter une validation au démarrage dans `main.py` :
```python
if settings.SECRET_KEY == "your-secret-key-here-change-in-production" or len(settings.SECRET_KEY) < 32:
    raise RuntimeError("FATAL: SECRET_KEY must be set to a secure random value of at least 32 characters")
```

---

#### SEC-004 · P0 · Credentials admin en clair dans le Dockerfile

**Fichier :** `backend/Dockerfile` — Lignes 67-69
**Code actuel :**
```dockerfile
ENV ADMIN_USERNAME=xelkoom_admin
ENV ADMIN_PASSWORD=X3lk00m@dmin2025!SecureP@ss
ENV SETUP_ADMIN=true
```
**Problème :** Les credentials sont stockées dans les couches de l'image Docker. Toute personne avec `docker inspect` ou `docker history` peut les extraire.

**Correction prescrite :** Supprimer ces 3 lignes `ENV` du Dockerfile. Passer les credentials au runtime :
```bash
docker run -e ADMIN_USERNAME=... -e ADMIN_PASSWORD=... image_name
```
Ou utiliser Docker Secrets / un gestionnaire de secrets (Vault, AWS Secrets Manager).

---

#### SEC-005 · P0 · Default admin credentials `admin/admin123`

**Fichier :** `backend/app/core/config.py` — Lignes 57-58
**Code actuel :**
```python
DEFAULT_ADMIN_USERNAME: str = "admin"
DEFAULT_ADMIN_PASSWORD: str = "admin123"
```
**Problème :** Credentials par défaut trivialement devinables. Si `.env` n'est pas configuré en production, le compte admin est compromis.

**Correction prescrite :** Supprimer les valeurs par défaut et exiger la configuration via env vars :
```python
DEFAULT_ADMIN_USERNAME: Optional[str] = None
DEFAULT_ADMIN_PASSWORD: Optional[str] = None
```
Ajouter validation dans le script de setup admin pour rejeter les mots de passe faibles.

---

#### SEC-006 · P0 · JWT stocké en SharedPreferences (mobile)

**Fichier :** `mobile_app/lib/services/auth_service.dart` — Lignes 11-15
**Code actuel :**
```dart
Future<void> saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
```
**Problème :** `SharedPreferences` stocke les données en clair dans un fichier XML. Sur un appareil rooté ou via backup, le token JWT est lisible.

**Correction prescrite :** Migrer vers `flutter_secure_storage` :
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveAuthData(String token, User user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}
```
Ajouter `flutter_secure_storage: ^9.0.0` dans `pubspec.yaml`.

---

#### SEC-007 · P1 · Login accepte credentials en query parameters

**Fichier :** `backend/app/api/routes/auth.py` — Lignes 69-82
**Code actuel :**
```python
async def login(
    login_data: LoginRequest = None,
    username: str = None,
    password: str = None,
    db: Session = Depends(get_db)
):
    user_username = login_data.username if login_data else username
    user_password = login_data.password if login_data else password
```
**Problème :** Les mots de passe passés en query string sont logués dans les logs serveur, l'historique du navigateur, les proxies, et les en-têtes `Referer`.

**Correction prescrite :**
```python
@router.post("/login", response_model=Token)
async def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, login_data.username, login_data.password)
```
Supprimer les paramètres `username` et `password` optionnels.

---

#### SEC-008 · P1 · Token JWT dans l'URL pour audio (frontend)

**Fichier :** `admin_dashboard_react/src/services/api.ts` — Ligne 196
**Code actuel :**
```typescript
async getRecordingAudioUrl(recordingId: string): Promise<string> {
    return `${API_BASE_URL}/admin/recordings/${recordingId}/audio?token=${this.token}`;
}
```
**Fichier :** `backend/app/api/routes/admin.py` — Ligne 748
```python
token: str = Query(...),  # Token passé en paramètre de requête
```
**Problème :** Le JWT fuite dans les logs serveur, l'historique du navigateur, le `Referer` header.

**Correction prescrite :**
- Backend : Accepter le token via le header `Authorization` standard uniquement
- Frontend : Utiliser `fetch()` avec header `Authorization: Bearer <token>` et gérer le blob audio via `URL.createObjectURL()`

---

#### SEC-009 · P1 · JWT dans localStorage (frontend)

**Fichier :** `admin_dashboard_react/src/services/api.ts` — Ligne 68
**Code actuel :**
```typescript
this.token = localStorage.getItem('admin_token');
```
**Problème :** `localStorage` est accessible par tout script JS de la page. Une faille XSS permet de voler le token.

**Correction prescrite :** Migrer vers un cookie `httpOnly` côté backend, ou au minimum utiliser `sessionStorage` avec un mécanisme de rafraîchissement.

---

#### SEC-010 · P1 · Build release signé avec clé debug (mobile)

**Fichier :** `mobile_app/android/app/build.gradle.kts`
**Problème :** Le build type `release` utilise `signingConfigs.getByName("debug")`. Le Play Store rejettera l'APK et il n'y a aucune protection anti-tampering.

**Correction prescrite :** Configurer un keystore de release :
```kotlin
signingConfigs {
    create("release") {
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
    }
}
buildTypes {
    release {
        isMinifyEnabled = true
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

#### SEC-011 · P1 · Pas de certificate pinning (mobile)

**Fichier :** `mobile_app/lib/services/api_service.dart`
**Problème :** Le client Dio n'implémente aucun certificate pinning. Un attaquant MITM peut intercepter les tokens et les données audio.

**Correction prescrite :** Implémenter le pinning via `dio_certificate_pinning` ou un `SecurityContext` personnalisé.

---

#### SEC-012 · P1 · Path traversal dans le serving de fichiers audio

**Fichier :** `backend/app/api/routes/admin.py` — Lignes 776-782
**Code actuel :**
```python
if os.path.isabs(recording.filepath):
    audio_path = Path(recording.filepath)
else:
    storage_base = Path(settings.AUDIO_STORAGE_PATH)
    audio_path = storage_base / recording.filepath
```
**Problème :** Si `recording.filepath` contient `../../../etc/passwd`, le serveur peut servir des fichiers arbitraires.

**Correction prescrite :**
```python
storage_base = Path(settings.AUDIO_STORAGE_PATH).resolve()
audio_path = (storage_base / recording.filepath).resolve()
if not str(audio_path).startswith(str(storage_base)):
    raise HTTPException(status_code=403, detail="Access denied")
```

---

#### SEC-013 · P2 · CORS trop permissif

**Fichier :** `backend/app/main.py` — Lignes 92-93
**Code actuel :**
```python
allow_methods=["*"],
allow_headers=["*"],
```
**Correction prescrite :**
```python
allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
allow_headers=["Authorization", "Content-Type", "Accept"],
```

---

#### SEC-014 · P2 · SecurityMiddleware casse les headers de réponse

**Fichier :** `backend/app/core/rate_limiting.py` — Lignes 58-75
**Code actuel :**
```python
headers = dict(message.get("headers", []))
headers.update(security_headers)
message["headers"] = list(headers.items())
```
**Problème :** Convertir les headers ASGI (liste de tuples `(bytes, bytes)`) en dict supprime les headers dupliqués (`Set-Cookie`).

**Correction prescrite :**
```python
existing_headers = list(message.get("headers", []))
for key, value in security_headers.items():
    existing_headers.append((key, value))
message["headers"] = existing_headers
```

---

#### SEC-015 · P1 · DEBUG=True par défaut

**Fichier :** `backend/app/core/config.py` — Ligne 43
**Code actuel :**
```python
DEBUG: bool = True
ENVIRONMENT: str = "development"
```
**Correction prescrite :**
```python
DEBUG: bool = False
ENVIRONMENT: str = "production"
```
Et ajouter validation au démarrage :
```python
if settings.ENVIRONMENT == "production" and settings.DEBUG:
    logger.warning("DEBUG mode is enabled in production — this is a security risk")
```

---

### 4.2 COHÉRENCE INTER-COMPOSANTS (CONTRATS API)

---

#### CTR-001 · P0 · Genre : mobile envoie `masculin/féminin`, backend attend `male/female`

**Fichier mobile :** `mobile_app/lib/screens/auth/registration_screen.dart` — Lignes 18, 25, 320
**Code actuel :**
```dart
final List<String> _genderOptions = ['Masculin', 'Féminin'];
// ...
gender: _selectedGender.toLowerCase(), // Envoie "masculin" ou "féminin"
```
**Fichier backend :** `backend/app/models/__init__.py` — Lignes 23-26
```python
class GenderEnum(enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"
```
**Problème :** Le backend définit des enums `male/female/other`, or la colonne est un `String(20)` sans contrainte. La valeur `"masculin"` est acceptée silencieusement, corrompant les données de statistiques par genre.

**Correction prescrite (mobile) :**
```dart
final Map<String, String> _genderOptions = {
  'Masculin': 'male',
  'Féminin': 'female',
};
// À l'envoi :
gender: _genderOptions[_selectedGender]!,
```
**Correction prescrite (backend) :** Ajouter une validation Pydantic dans `UserCreate` :
```python
from pydantic import field_validator

@field_validator('gender')
@classmethod
def validate_gender(cls, v):
    if v not in ('male', 'female', 'other'):
        raise ValueError('gender must be male, female, or other')
    return v
```

---

#### CTR-002 · P0 · Tranches d'âge : mobile ≠ backend

**Fichier mobile :** `mobile_app/lib/screens/auth/registration_screen.dart` — Ligne 26
```dart
final List<String> _ageRanges = ['18-25', '26-35', '36-45', '46-55', '56+'];
```
**Fichier backend :** `backend/app/models/__init__.py` — Lignes 28-33
```python
class AgeRangeEnum(enum.Enum):
    RANGE_18_24 = "18-24"
    RANGE_25_34 = "25-34"
    RANGE_35_44 = "35-44"
    RANGE_45_54 = "45-54"
    RANGE_55_PLUS = "55+"
```
**Problème :** Les valeurs ne correspondent pas (`18-25` vs `18-24`, `26-35` vs `25-34`, etc.). Les statistiques par tranche d'âge sont corrompues.

**Correction prescrite (mobile) :**
```dart
final List<String> _ageRanges = ['18-24', '25-34', '35-44', '45-54', '55+'];
```

---

#### CTR-003 · P0 · Endpoint `/auth/login-legacy` inexistant

**Fichier mobile :** `mobile_app/lib/services/api_service.dart` — Ligne 104
```dart
'/auth/login-legacy',
```
**Fichier backend :** `backend/app/api/routes/auth.py` — Aucune route `/login-legacy`
**Problème :** L'appel retournera toujours 404.

**Correction prescrite :** Soit créer l'endpoint côté backend, soit supprimer l'appel côté mobile et utiliser uniquement `/auth/login`.

---

#### CTR-004 · P0 · Type des IDs : frontend `number` vs backend UUID

**Fichier frontend :** `admin_dashboard_react/src/types/index.ts` — Lignes 2, 17, 40
```typescript
export interface User { id: number; ... }
export interface Sentence { id: number; ... }
export interface Recording { id: number; ... }
```
**Fichier backend :** `backend/app/schemas/__init__.py`
```python
id: Any  # UUID sur PostgreSQL, int sur SQLite
```
**Problème :** En production (PostgreSQL), le backend retourne des UUIDs (strings). Le frontend les traite comme `number`, ce qui casse les comparaisons et les navigations.

**Correction prescrite (frontend) :**
```typescript
export interface User { id: string; ... }
export interface Sentence { id: string; ... }
export interface Recording { id: string; ... }
```

---

#### CTR-005 · P1 · `AuthResponse.expires_in` attendu mais jamais renvoyé

**Fichier frontend :** `admin_dashboard_react/src/types/index.ts` — Ligne 189
```typescript
export interface AuthResponse {
    access_token: string;
    token_type: string;
    expires_in: number;  // <-- N'existe pas dans la réponse backend
    user: User;
}
```
**Fichier backend :** `backend/app/schemas/__init__.py` — Lignes 122-125
```python
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
    # Pas de expires_in
```
**Correction prescrite :** Ajouter `expires_in` au schema backend :
```python
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    user: UserResponse
```

---

#### CTR-006 · P1 · `UserWithStats` ne contient pas `role`

**Fichier backend :** `backend/app/schemas/__init__.py` — Lignes 172-183
```python
class UserWithStats(BaseModel):
    id: Any
    username: str
    gender: str
    age_range: str
    is_admin: bool
    is_active: bool
    consent_given: bool
    # Pas de champ 'role'
```
**Fichier frontend :** `admin_dashboard_react/src/types/index.ts`
```typescript
export interface User { role: 'admin' | 'moderator' | 'user'; ... }
```
**Correction prescrite :** Ajouter `role: str` dans `UserWithStats` :
```python
class UserWithStats(BaseModel):
    # ...
    role: str
    # ...
```

---

#### CTR-007 · P2 · Champs fantômes dans le type `Sentence` côté frontend

**Fichier :** `admin_dashboard_react/src/types/index.ts` — Lignes 20, 25, 30
```typescript
category?: string;         // N'existe pas dans le backend
is_active?: boolean;       // N'existe pas dans le backend
average_quality_score?: number;  // N'existe pas dans le backend
```
**Correction prescrite :** Supprimer ces 3 champs du type `Sentence`.

---

#### CTR-008 · P2 · Token refresh non implémenté côté mobile

**Fichier mobile :** `mobile_app/lib/services/api_service.dart` — Le token expire en 30 min mais le `/auth/refresh` n'est jamais appelé. L'utilisateur est déconnecté brutalement.

**Correction prescrite :** Implémenter un intercepteur Dio qui détecte les 401, appelle `/auth/refresh`, et rejoue la requête originale.

---

#### CTR-009 · P2 · `audio_metadata` non parsé par le modèle mobile `Recording`

**Problème :** Le backend renvoie `audio_metadata` dans `RecordingResponse`, mais le modèle Dart `Recording` ne le parse pas. Les métadonnées audio sont perdues côté mobile.

**Correction prescrite :** Ajouter `Map<String, dynamic>? audioMetadata` au modèle Dart `Recording`.

---

### 4.3 BASE DE DONNÉES

---

#### DB-001 · P1 · Aucune migration Alembic

**Fichier :** `backend/migrations/versions/` — Dossier vide
**Fichier :** `backend/app/main.py` — Ligne 72
```python
Base.metadata.create_all(bind=engine)
```
**Problème :** `create_all()` ne modifie jamais les colonnes existantes. Tout changement de schema en production nécessite une migration manuelle. Le schema n'est pas versionné.

**Correction prescrite :**
1. Supprimer `Base.metadata.create_all()` de `main.py`
2. Générer la migration initiale : `alembic revision --autogenerate -m "initial_schema"`
3. Intégrer `alembic upgrade head` dans le script de démarrage
4. Documenter le workflow de migration dans le README

---

#### DB-002 · P1 · Type d'ID conditonnel (SQLite vs PostgreSQL)

**Fichier :** `backend/app/models/__init__.py` — Lignes 10-17
```python
if "sqlite" in settings.DATABASE_URL:
    def get_id_column():
        return Column(Integer, primary_key=True, autoincrement=True)
else:
    from sqlalchemy.dialects.postgresql import UUID
    def get_id_column():
        return Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
```
**Problème :** Le schema change en fonction de l'environnement runtime. Les migrations générées sur SQLite ne fonctionnent pas sur PostgreSQL et vice versa. La parité dev/prod est violée.

**Correction prescrite :** Utiliser `sqlalchemy.Uuid` (SQLAlchemy 2.0+) qui fonctionne sur les deux moteurs :
```python
from sqlalchemy import Uuid
import uuid

class User(Base):
    __tablename__ = "users"
    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
```

---

#### DB-003 · P1 · Pas de contrainte UNIQUE sur `(user_id, sentence_id)` dans Recording

**Fichier :** `backend/app/models/__init__.py` — Lignes 80-83
**Problème :** La contrainte "un enregistrement par utilisateur par phrase" n'existe qu'au niveau applicatif. Sous requêtes concurrentes, des doublons peuvent être créés.

**Correction prescrite :**
```python
class Recording(Base):
    __tablename__ = "recordings"
    __table_args__ = (
        UniqueConstraint('user_id', 'sentence_id', name='uq_recording_user_sentence'),
    )
```

---

#### DB-004 · P1 · Index manquants sur colonnes fréquemment filtrées

**Fichier :** `backend/app/models/__init__.py`
**Colonnes sans index :**
- `Recording.user_id` (FK, ligne 82)
- `Recording.sentence_id` (FK, ligne 83)
- `Recording.status` (ligne 90)
- `Sentence.status` (ligne 76)

**Correction prescrite :**
```python
user_id = get_foreign_key_column("users")  # Ajouter index=True
sentence_id = get_foreign_key_column("sentences")  # Ajouter index=True
status = Column(String(20), default="pending", index=True)
```

---

#### DB-005 · P2 · Colonnes enum en String(20) sans CHECK constraint

**Fichier :** `backend/app/models/__init__.py` — Lignes 60-63
```python
gender = Column(String(20), nullable=False)
age_range = Column(String(20), nullable=False)
status = Column(String(20), default="available")
role = Column(String(20), default="user")
```
**Problème :** N'importe quelle valeur peut être insérée sans validation au niveau DB.

**Correction prescrite :** Ajouter des `CheckConstraint` ou utiliser des `Enum` PostgreSQL via SQLAlchemy.

---

#### DB-006 · P2 · N+1 queries dans la liste admin des utilisateurs

**Fichier :** `backend/app/api/routes/admin.py` — Lignes 519-527
```python
for user in users:
    recording_count = db.query(Recording).filter(Recording.user_id == user.id).count()
    validated_count = db.query(Recording).filter(
        Recording.user_id == user.id, Recording.status == "validated"
    ).count()
```
**Problème :** 2 requêtes par utilisateur × 50 utilisateurs = 100 requêtes supplémentaires par page.

**Correction prescrite :** Utiliser une sous-requête agrégée avec `outerjoin` + `group_by`.

---

#### DB-007 · P2 · Pool de connexions non configuré pour la production

**Fichier :** `backend/app/db/database.py` — Lignes 12-16
**Code actuel :**
```python
engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True, pool_recycle=300)
```
**Correction prescrite :**
```python
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=300,
    pool_size=10,
    max_overflow=20,
    pool_timeout=30,
)
```

---

### 4.4 DASHBOARD ADMIN (React)

---

#### ADM-001 · P1 · Double pagination (Sentences)

**Fichier :** `admin_dashboard_react/src/pages/Sentences.tsx` — Ligne ~444
**Problème :** `sentences.items.slice(page * rowsPerPage, ...)` applique une pagination client-side sur des données déjà paginées côté serveur. Le nombre d'items affichés est incohérent avec le total.

**Correction prescrite :** Supprimer le `slice()` client-side. La pagination doit être entièrement gérée côté serveur via les paramètres `skip` et `limit`.

---

#### ADM-002 · P1 · Division par zéro dans RecordingStatusCards

**Fichier :** `admin_dashboard_react/src/components/RecordingStatusCards.tsx` — Ligne ~105
```typescript
(card.value / metrics.total_recordings) * 100
```
**Problème :** Quand `total_recordings === 0`, le résultat est `NaN`.

**Correction prescrite :**
```typescript
metrics.total_recordings > 0 ? (card.value / metrics.total_recordings) * 100 : 0
```

---

#### ADM-003 · P1 · Stats utilisateurs calculées sur la page courante

**Fichier :** `admin_dashboard_react/src/pages/Users.tsx` — Ligne ~519
**Problème :** `UserStatsCards` reçoit `users.length` (page actuelle, ex: 25) au lieu de `total` (tous les utilisateurs, ex: 500). Les statistiques sont fausses.

**Correction prescrite :** Passer `total` (provenant de la réponse paginée du serveur) aux composants de stats.

---

#### ADM-004 · P1 · Route `/balance` manquante dans le router

**Fichier :** `admin_dashboard_react/src/App.tsx` — Le fichier `Balance.tsx` existe mais n'est pas déclaré dans les routes.
**Problème :** `BalanceSummaryCard` navigue vers `/balance` qui tombe sur le catch-all `*` → redirect vers `/dashboard`.

**Correction prescrite :** Ajouter la route dans `App.tsx` :
```tsx
<Route path="/balance" element={<Balance />} />
```

---

#### ADM-005 · P1 · Recherche client-side casse la pagination serveur

**Fichier :** `admin_dashboard_react/src/pages/Users.tsx` — Lignes 343-354
**Fichier :** `admin_dashboard_react/src/hooks/useSentences.ts` — Lignes 44-55
**Problème :** Le filtre de recherche s'applique côté client sur les items de la page courante, puis remplace `total` par le nombre filtré. La pagination est cassée.

**Correction prescrite :** Implémenter la recherche côté serveur via un paramètre `search` dans l'API backend.

---

#### ADM-006 · P2 · `PeriodFilter` dans Analytics ne fait rien

**Fichier :** `admin_dashboard_react/src/pages/Analytics.tsx`
**Problème :** Le composant `PeriodFilter` est affiché mais `selectedPeriod` n'est jamais transmis à aucun appel API. Le filtre est purement cosmétique.

**Correction prescrite :** Soit connecter le filtre aux appels API avec un paramètre `period`, soit le retirer de l'UI.

---

#### ADM-007 · P2 · `EngagementMetrics` calcul absurde

**Fichier :** `admin_dashboard_react/src/components/EngagementMetrics.tsx` — Ligne 28
```typescript
engagementRate = (total_recordings / total_users) * 100
```
**Problème :** 10 utilisateurs avec 100 enregistrements = "1000% d'engagement". Ce n'est pas un taux.

**Correction prescrite :** Utiliser une métrique pertinente, ex: % d'utilisateurs ayant au moins 1 enregistrement.

---

#### ADM-008 · P2 · 30+ instances de `any` en TypeScript

**Fichiers multiples :** `SocketContext.tsx`, `AuthContext.tsx`, `useAnalytics.ts`, `useSystem.ts`, `useSentences.ts`, `DailyRecordingsChart.tsx`, `CreateSentenceDialog.tsx`, etc.
**Problème :** Le mode `strict: true` est activé mais contourné partout via `any`, annulant les bénéfices de TypeScript.

**Correction prescrite :** Remplacer chaque `any` par le type approprié. Pour les erreurs dans les `catch` :
```typescript
catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error';
}
```

---

#### ADM-009 · P2 · `react-query` v3 (end-of-life)

**Fichier :** `admin_dashboard_react/package.json`
```json
"react-query": "^3.39.3"
```
**Correction prescrite :** Migrer vers `@tanstack/react-query` v5.

---

#### ADM-010 · P2 · Pas d'Error Boundary React

**Problème :** Une erreur non catchée dans un composant crash toute l'application.

**Correction prescrite :** Ajouter un `ErrorBoundary` à la racine de l'arbre de composants.

---

#### ADM-011 · P3 · Copyright hardcodé "© 2024"

**Fichier :** `admin_dashboard_react/src/components/Layout/Sidebar.tsx` — Ligne 125
**Correction prescrite :** `© ${new Date().getFullYear()}`

---

#### ADM-012 · P3 · `AnalyticsTest.tsx` shippé en production

**Fichier :** `admin_dashboard_react/src/components/AnalyticsTest.tsx`
**Correction prescrite :** Supprimer ce fichier de debug.

---

#### ADM-013 · P3 · Dépendances inutilisées

**Fichier :** `admin_dashboard_react/package.json`
- `socket.io-client` — WebSocket complètement désactivé (~40 KB)
- `@mui/x-charts` — Jamais utilisé (recharts est utilisé)
- `howler` — Jamais utilisé

**Correction prescrite :** Supprimer ces dépendances.

---

### 4.5 APP MOBILE (Flutter)

---

#### MOB-001 · P0 · Schema SQL offline cassé

**Fichier :** `mobile_app/lib/services/offline_storage_service.dart` — Ligne 56-65
**CREATE TABLE :**
```sql
CREATE TABLE cached_user_stats (
    user_id TEXT PRIMARY KEY,
    total_recordings INTEGER DEFAULT 0,
    validated_recordings INTEGER DEFAULT 0,
    rejected_recordings INTEGER DEFAULT 0,
    total_duration REAL DEFAULT 0.0,
    rank INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    last_updated TEXT NOT NULL
)
```
**INSERT (ligne 203) :**
```dart
'pending_recordings': stats.pendingRecordings,
```
**Problème :** La colonne `pending_recordings` n'existe pas dans le `CREATE TABLE`. L'insert crashera au runtime.

**Correction prescrite :** Ajouter la colonne dans le CREATE TABLE :
```sql
pending_recordings INTEGER DEFAULT 0,
```

---

#### MOB-002 · P1 · URL de production hardcodée

**Fichier :** `mobile_app/lib/services/api_service.dart` — Lignes 11-12
```dart
static const String baseUrl = 'https://backend-xelkoom-collect.onrender.com';
```
**Problème :** Aucune possibilité de switcher entre dev, staging et production.

**Correction prescrite :** Utiliser `--dart-define` ou un fichier `.env` :
```dart
static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
);
```
Build dev : `flutter run --dart-define=API_BASE_URL=http://localhost:8000`
Build prod : `flutter build apk --dart-define=API_BASE_URL=https://prod.api.com`

---

#### MOB-003 · P1 · Firebase déclaré mais jamais initialisé

**Fichier :** `mobile_app/pubspec.yaml` — Lignes 64-66
```yaml
firebase_core: ^2.24.2
firebase_analytics: ^10.7.4
firebase_crashlytics: ^3.4.8
```
**Fichier :** `mobile_app/lib/main.dart` — `Firebase.initializeApp()` n'est jamais appelé.
**Problème :** Aucun crash reporting en production. Les exceptions sont uniquement `print()`.

**Correction prescrite :** Initialiser Firebase dans `main()` avant `runApp()` :
```dart
void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    runApp(const ProviderScope(child: XelkoomApp()));
}
```

---

#### MOB-004 · P1 · 8+ dépendances inutilisées

**Fichier :** `mobile_app/pubspec.yaml`
| Paquet | Statut |
|--------|--------|
| `go_router` | Déclaré, jamais utilisé (utilise `Navigator.pushNamed`) |
| `hive` + `hive_flutter` | Déclaré, jamais utilisé (utilise `sqflite`) |
| `introduction_screen` | Déclaré, jamais importé |
| `showcaseview` | Déclaré, jamais importé |
| `lottie` | Déclaré, jamais importé |
| `confetti` | Déclaré, jamais importé |
| `flutter_svg` | Déclaré, jamais importé |
| `animated_text_kit` | Déclaré, jamais importé |

**Correction prescrite :** Supprimer toutes les dépendances non utilisées. Cela réduit la taille de l'APK et la surface d'attaque.

---

#### MOB-005 · P1 · Aucun test

**Fichier :** `mobile_app/test/widget_test.dart` — 1 seul test trivial (`MaterialApp` renders).
**Problème :** 0 test unitaire, 0 test d'intégration, 0 test de service.

**Correction prescrite :** Écrire des tests pour :
- `AuthService` (save/get/delete token)
- `ApiService` (mock Dio, intercepteurs 401)
- `OfflineStorageService` (CRUD SQLite)
- `AudioRecorderService` (formats, durée)
- Flux d'enregistrement complet (intégration)

**Cible :** ≥ 70% de couverture.

---

#### MOB-006 · P2 · `AudioRecorderService` = God Class (1135 lignes)

**Fichier :** `mobile_app/lib/services/audio_recorder_service.dart`
**Problème :** Recording, playback, codec detection, diagnostics, emulator detection et test methods dans un seul fichier.

**Correction prescrite :** Découper en :
- `RecordingService` — Enregistrement audio
- `PlaybackService` — Lecture audio
- `CodecDetector` — Détection du meilleur codec
- `AudioDiagnostics` — Outils de debug (à ne pas shipper en prod)

---

#### MOB-007 · P2 · `RecordingStatus` enum défini dans 2 fichiers avec des valeurs différentes

**Fichier 1 :** `mobile_app/lib/models/recording.dart` — `pending`, `validated`, `rejected`
**Fichier 2 :** `mobile_app/lib/providers/recording_provider.dart` — `idle`, `preparing`, `recording`, `stopped`, `uploading`, `uploaded`, `error`

**Correction prescrite :** Renommer l'enum du provider en `RecordingProcessState` pour éviter la collision.

---

#### MOB-008 · P2 · Cache de permissions ne s'expire jamais

**Fichier :** `mobile_app/lib/services/permission_service.dart`
**Problème :** `_cachedMicPermission` est `static` et jamais réinitialisé. Si l'utilisateur refuse la permission puis l'accorde dans les paramètres système, le cache garde `denied` jusqu'au restart de l'app.

**Correction prescrite :** Invalider le cache quand l'app revient au foreground (`WidgetsBindingObserver.didChangeAppLifecycleState`).

---

#### MOB-009 · P2 · Pas de localisation i18n

**Problème :** Toutes les chaînes sont hardcodées en français. Pas de support Wolof malgré la dépendance `flutter_localizations`.

**Correction prescrite :** Implémenter les fichiers `.arb` pour `fr` et `wo` (Wolof) au minimum.

---

### 4.6 CONFORMITÉ RGPD

---

#### GDPR-001 · P1 · Suppression utilisateur ne supprime pas les fichiers audio

**Fichier :** `backend/app/api/routes/users.py` — Lignes 87-93
```python
db.query(Recording).filter(Recording.user_id == current_user.id).delete()
db.delete(current_user)
db.commit()
```
**Problème :** Les enregistrements DB sont supprimés, mais les fichiers audio sur disque/S3 persistent. Violation Article 17 RGPD.

**Correction prescrite :**
```python
recordings = db.query(Recording).filter(Recording.user_id == current_user.id).all()
for recording in recordings:
    filepath = Path(settings.AUDIO_STORAGE_PATH) / recording.filepath
    if filepath.exists():
        filepath.unlink()
db.query(Recording).filter(Recording.user_id == current_user.id).delete()
db.delete(current_user)
db.commit()
```

---

#### GDPR-002 · P1 · Pas d'endpoint d'export de données personnelles

**Problème :** L'Article 20 RGPD exige la portabilité des données. Il n'existe aucun endpoint pour qu'un utilisateur exporte ses données personnelles et ses enregistrements.

**Correction prescrite :** Créer `GET /users/me/export` qui retourne un ZIP contenant :
- Les informations du profil (JSON)
- Tous les enregistrements audio (WAV)
- Les métadonnées associées

---

#### GDPR-003 · P2 · Admin soft-delete ne supprime pas les données

**Fichier :** `backend/app/api/routes/admin.py` — Lignes 723-737
```python
user.is_active = False  # "delete" = désactivation uniquement
```
**Correction prescrite :** Offrir deux options : désactivation (administrative) et suppression (RGPD) qui anonymise les données personnelles et supprime les fichiers audio.

---

#### GDPR-004 · P2 · Pas de mécanisme de révocation du consentement

**Problème :** Le consentement est enregistré à l'inscription (`consent_given=True`) mais il n'existe aucun endpoint pour le révoquer.

**Correction prescrite :** Créer `POST /users/me/revoke-consent` qui déclenche le même processus que la suppression RGPD.

---

#### GDPR-005 · P2 · Pas de politique de rétention des données

**Problème :** Aucun TTL ou nettoyage automatique pour les enregistrements rejetés, les comptes inactifs, ou les données temporaires.

**Correction prescrite :** Implémenter une tâche planifiée (cron/Celery beat) qui :
- Supprime les recordings rejetés après 90 jours
- Anonymise les comptes inactifs après 2 ans
- Nettoie les fichiers orphelins

---

### 4.7 API DESIGN & PERFORMANCE

---

#### API-001 · P1 · Traitement audio synchrone dans le handler HTTP

**Fichier :** `backend/app/api/routes/recordings.py` — Lignes 20-98
**Problème :** FFmpeg, librosa et Whisper s'exécutent dans le handler de requête HTTP. Pour un fichier volumineux, cela bloque le worker pendant plusieurs secondes.

**Correction prescrite :** Utiliser `BackgroundTasks` de FastAPI ou Celery (déjà dans requirements mais non utilisé) :
```python
from fastapi import BackgroundTasks

@router.post("/")
async def create_recording(..., background_tasks: BackgroundTasks):
    # Sauvegarder le fichier brut immédiatement
    # Créer le recording avec status="processing"
    background_tasks.add_task(process_audio, recording_id, filepath)
    return recording
```

---

#### API-002 · P2 · Pas de versioning API

**Problème :** Les routes sont à `/auth/login`, `/users/me`, etc. sans préfixe de version. Tout changement cassant affecte tous les clients simultanément.

**Correction prescrite :** Préfixer toutes les routes avec `/api/v1/` :
```python
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
```

---

#### API-003 · P2 · Health check retourne des données fausses

**Fichier :** `backend/app/main.py` — Lignes 112-118
```python
return {"status": "healthy", "database": "connected", "audio_storage": "accessible"}
```
**Correction prescrite :** Vérifier réellement la connexion DB et l'accès au stockage :
```python
@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception:
        db_status = "disconnected"
    storage_ok = os.path.isdir(settings.AUDIO_STORAGE_PATH)
    status = "healthy" if db_status == "connected" and storage_ok else "degraded"
    return {"status": status, "database": db_status, "audio_storage": "accessible" if storage_ok else "inaccessible"}
```

---

#### API-004 · P2 · Endpoint logs retourne des données fictives

**Fichier :** `backend/app/api/routes/admin.py` — Lignes 920-940
**Correction prescrite :** Implémenter la lecture réelle des logs ou retourner `501 Not Implemented`.

---

#### API-005 · P2 · Sentences endpoint public (sans auth)

**Fichier :** `backend/app/api/routes/sentences.py` — Lignes 95-100
**Problème :** `GET /sentences/` et `GET /sentences/distribution-stats` n'ont aucune dépendance d'authentification.

**Correction prescrite :** Ajouter `current_user: User = Depends(get_current_active_user)` si les phrases ne doivent pas être publiques.

---

#### API-006 · P3 · Pas de limite maximale sur le paramètre `limit`

**Fichier :** `backend/app/api/routes/recordings.py` — Ligne 108
```python
limit: int = 100,
```
**Correction prescrite :**
```python
limit: int = Query(default=100, ge=1, le=100),
```

---

### 4.8 CODE QUALITY

---

#### CQ-001 · P2 · `cloud_setup.py` importe un module inexistant

**Fichier :** `backend/app/core/cloud_setup.py` — Ligne 2
```python
from app.core.logger import get_logger
```
**Problème :** `app/core/logger.py` n'existe pas. Ce module crashera à l'import.

**Correction prescrite :** Supprimer le fichier ou corriger l'import :
```python
import logging
logger = logging.getLogger(__name__)
```

---

#### CQ-002 · P2 · `firebase_service.py` est vide

**Fichier :** `backend/app/services/firebase_service.py`
**Correction prescrite :** Supprimer le fichier ou l'implémenter.

---

#### CQ-003 · P2 · Bare `except` clauses

**Fichier :** `backend/app/services/audio_processing.py` — Lignes ~258, 262, 285
```python
except:
    return audio
```
**Correction prescrite :** Utiliser `except Exception:` au minimum.

---

#### CQ-004 · P2 · Structlog configuré mais jamais utilisé

**Fichier :** `backend/app/main.py` — Lignes 27-41 configurent `structlog`, mais tous les routes et services utilisent `logging.getLogger()`.

**Correction prescrite :** Soit utiliser `structlog` partout, soit supprimer la configuration structlog et standardiser sur `logging`.

---

#### CQ-005 · P2 · Double librairie JWT

**Fichier :** `backend/requirements.txt`
```
python-jose[cryptography]==3.3.0
PyJWT==2.10.1
```
**Problème :** Deux librairies JWT installées. Le code utilise uniquement `python-jose`. `python-jose` n'est plus maintenu.

**Correction prescrite :** Migrer vers `PyJWT` et supprimer `python-jose`.

---

#### CQ-006 · P2 · Whisper/torch dans les dépendances mais désactivé

**Fichier :** `backend/requirements.txt`
```
whisper==1.1.10
torch==2.2.0
```
**Fichier :** `backend/app/services/whisper_validation.py` — `self.enabled = False`
**Problème :** ~2 GB de dépendances pour une feature désactivée, gonflant l'image Docker.

**Correction prescrite :** Déplacer `whisper` et `torch` dans un fichier `requirements-whisper.txt` optionnel. Ne les installer que si la feature est activée.

---

#### CQ-007 · P3 · `datetime.utcnow()` déprécié

**Fichier :** `backend/app/core/auth.py` — Lignes 32-34
**Correction prescrite :** Utiliser `datetime.now(timezone.utc)`.

---

#### CQ-008 · P3 · `declarative_base()` import déprécié

**Fichier :** `backend/app/db/database.py` — Ligne 7
**Correction prescrite :** Utiliser `from sqlalchemy.orm import DeclarativeBase`.

---

### 4.9 CONFIGURATION & BUILD

---

#### CFG-001 · P2 · Starlette pinné explicitement

**Fichier :** `backend/requirements.txt` — Ligne 51
```
starlette==0.27.0
```
**Problème :** Version pinned incompatible avec les mises à jour de FastAPI. `starlette 0.27.0` a des vulnérabilités connues.

**Correction prescrite :** Supprimer la ligne. Laisser FastAPI gérer sa propre dépendance starlette.

---

#### CFG-002 · P2 · `docker-compose.cloud.yml` est vide

**Fichier :** `backend/docker-compose.cloud.yml`
**Correction prescrite :** Supprimer ou implémenter.

---

#### CFG-003 · P3 · Pas de `.env.example`

**Problème :** Les développeurs doivent lire `config.py` pour connaître les variables d'environnement requises.

**Correction prescrite :** Créer un `.env.example` avec toutes les variables documentées.

---

#### CFG-004 · P3 · Build script Windows incompatible

**Fichier :** `admin_dashboard_react/package.json`
```json
"build:prod": "NODE_ENV=production npm run build"
```
**Problème :** Syntaxe Unix. Ne fonctionne pas sur Windows.

**Correction prescrite :** Installer et utiliser `cross-env` :
```json
"build:prod": "cross-env NODE_ENV=production npm run build"
```

---

## 5. Plan d'Exécution par Sprints

### Sprint 0 — Sécurité Critique (Semaine 1)

| ID | Correction | Composant | Effort |
|----|-----------|-----------|--------|
| SEC-001 | Supprimer bypass authentification | Backend | 1h |
| SEC-002 | Rendre password obligatoire | Backend | 30min |
| SEC-003 | Supprimer défaut SECRET_KEY + validation | Backend | 1h |
| SEC-004 | Supprimer credentials du Dockerfile | Backend | 30min |
| SEC-005 | Supprimer credentials admin par défaut | Backend | 30min |
| SEC-006 | Migrer vers flutter_secure_storage | Mobile | 2h |
| SEC-007 | Supprimer query params login | Backend | 1h |
| CTR-001 | Corriger valeurs genre mobile | Mobile | 30min |
| CTR-002 | Corriger tranches d'âge mobile | Mobile | 15min |
| CTR-003 | Supprimer appel login-legacy | Mobile | 15min |
| MOB-001 | Corriger schema SQL offline | Mobile | 30min |

**Total estimé : ~8h**

### Sprint 1 — Cohérence & Stabilité (Semaines 2-3)

| ID | Correction | Composant | Effort |
|----|-----------|-----------|--------|
| CTR-004 | Corriger type IDs (number → string) | Frontend | 3h |
| CTR-005 | Ajouter `expires_in` au Token | Backend | 30min |
| CTR-006 | Ajouter `role` à UserWithStats | Backend | 30min |
| DB-001 | Générer migrations Alembic | Backend | 4h |
| DB-002 | Unifier type ID (sqlalchemy.Uuid) | Backend | 3h |
| DB-003 | Ajouter contrainte UNIQUE recordings | Backend | 1h |
| DB-004 | Ajouter index DB | Backend | 1h |
| ADM-001 | Corriger double pagination | Frontend | 2h |
| ADM-002 | Corriger division par zéro | Frontend | 30min |
| ADM-003 | Stats sur total réel | Frontend | 1h |
| ADM-004 | Ajouter route /balance | Frontend | 30min |
| SEC-008 | Token audio via header | Backend + Frontend | 3h |
| SEC-010 | Configurer keystore release | Mobile | 2h |
| SEC-015 | DEBUG=False par défaut | Backend | 15min |

**Total estimé : ~22h**

### Sprint 2 — RGPD & Performance (Semaines 4-5)

| ID | Correction | Composant | Effort |
|----|-----------|-----------|--------|
| GDPR-001 | Supprimer fichiers audio à la deletion | Backend | 2h |
| GDPR-002 | Créer endpoint export données | Backend | 4h |
| GDPR-003 | Implémenter hard-delete admin | Backend | 2h |
| GDPR-004 | Endpoint révocation consentement | Backend | 2h |
| API-001 | Traitement audio en background task | Backend | 4h |
| API-002 | Versioning API /api/v1/ | Backend | 3h |
| API-003 | Health check réel | Backend | 1h |
| DB-006 | Corriger N+1 queries | Backend | 2h |
| DB-007 | Configurer pool connexions | Backend | 30min |
| CTR-008 | Implémenter token refresh mobile | Mobile | 3h |
| ADM-005 | Recherche serveur-side | Backend + Frontend | 4h |
| SEC-012 | Protection path traversal | Backend | 1h |

**Total estimé : ~28h**

### Sprint 3 — Qualité & Tests (Semaines 6-8)

| ID | Correction | Composant | Effort |
|----|-----------|-----------|--------|
| MOB-002 | Configuration URL par environnement | Mobile | 2h |
| MOB-003 | Initialiser Firebase | Mobile | 2h |
| MOB-004 | Supprimer dépendances inutilisées | Mobile | 1h |
| MOB-005 | Tests mobile (70% couverture) | Mobile | 16h |
| MOB-006 | Refactor AudioRecorderService | Mobile | 4h |
| ADM-008 | Remplacer `any` par types stricts | Frontend | 4h |
| ADM-009 | Migrer react-query v5 | Frontend | 3h |
| ADM-010 | Ajouter Error Boundary | Frontend | 1h |
| CQ-001-008 | Nettoyage code backend | Backend | 4h |
| CFG-001-004 | Nettoyage config & build | Tous | 2h |
| ADM-013 | Supprimer deps frontend inutiles | Frontend | 1h |
| GDPR-005 | Tâche de rétention données | Backend | 3h |

**Total estimé : ~43h**

### Backlog — Améliorations (Post-Sprint 3)

| ID | Correction | Effort |
|----|-----------|--------|
| SEC-009 | Migrer JWT vers httpOnly cookie | 4h |
| SEC-011 | Certificate pinning mobile | 3h |
| SEC-013 | Restreindre CORS | 1h |
| MOB-007 | Renommer RecordingStatus enum | 1h |
| MOB-008 | Invalidation cache permissions | 2h |
| MOB-009 | Localisation i18n (fr + wo) | 8h |
| ADM-006 | PeriodFilter fonctionnel | 3h |
| ADM-007 | Corriger EngagementMetrics | 1h |
| DB-005 | CHECK constraints enums | 2h |
| API-004 | Logs endpoint réel | 3h |
| Tests backend (70% couverture) | 16h |

---

## 6. Critères d'Acceptation pour le Déploiement National

Avant tout déploiement à l'échelle nationale, les critères suivants **doivent** être satisfaits :

| # | Critère | Sprint cible |
|---|---------|-------------|
| 1 | Aucun issue P0 ouvert | Sprint 0 |
| 2 | Aucun issue P1 ouvert | Sprint 1 |
| 3 | Authentification sécurisée (password obligatoire, pas de bypass) | Sprint 0 |
| 4 | Secrets gérés via env vars (aucun hardcoding) | Sprint 0 |
| 5 | Migrations Alembic fonctionnelles | Sprint 1 |
| 6 | Cohérence des contrats API entre les 3 composants | Sprint 1 |
| 7 | Conformité RGPD (export, suppression, révocation) | Sprint 2 |
| 8 | Traitement audio asynchrone | Sprint 2 |
| 9 | ≥ 50% couverture de tests (backend + mobile) | Sprint 3 |
| 10 | Crash reporting opérationnel (Sentry + Firebase Crashlytics) | Sprint 3 |
| 11 | CI/CD avec lint, tests, et déploiement automatique | Sprint 3 |
| 12 | Health check fonctionnel | Sprint 2 |

---

## 7. Annexes

### 7.1 Inventaire complet des issues

| ID | Sévérité | Catégorie | Composant | Statut |
|----|----------|-----------|-----------|--------|
| SEC-001 | P0 | Sécurité | Backend | À corriger |
| SEC-002 | P0 | Sécurité | Backend | À corriger |
| SEC-003 | P0 | Sécurité | Backend | À corriger |
| SEC-004 | P0 | Sécurité | Backend | À corriger |
| SEC-005 | P0 | Sécurité | Backend | À corriger |
| SEC-006 | P0 | Sécurité | Mobile | À corriger |
| SEC-007 | P1 | Sécurité | Backend | À corriger |
| SEC-008 | P1 | Sécurité | Backend+Frontend | À corriger |
| SEC-009 | P1 | Sécurité | Frontend | Backlog |
| SEC-010 | P1 | Sécurité | Mobile | À corriger |
| SEC-011 | P1 | Sécurité | Mobile | Backlog |
| SEC-012 | P1 | Sécurité | Backend | À corriger |
| SEC-013 | P2 | Sécurité | Backend | À corriger |
| SEC-014 | P2 | Sécurité | Backend | À corriger |
| SEC-015 | P1 | Sécurité | Backend | À corriger |
| CTR-001 | P0 | Contrat API | Mobile | À corriger |
| CTR-002 | P0 | Contrat API | Mobile | À corriger |
| CTR-003 | P0 | Contrat API | Mobile | À corriger |
| CTR-004 | P0 | Contrat API | Frontend | À corriger |
| CTR-005 | P1 | Contrat API | Backend | À corriger |
| CTR-006 | P1 | Contrat API | Backend | À corriger |
| CTR-007 | P2 | Contrat API | Frontend | À corriger |
| CTR-008 | P2 | Contrat API | Mobile | À corriger |
| CTR-009 | P2 | Contrat API | Mobile | À corriger |
| DB-001 | P1 | Base de données | Backend | À corriger |
| DB-002 | P1 | Base de données | Backend | À corriger |
| DB-003 | P1 | Base de données | Backend | À corriger |
| DB-004 | P1 | Base de données | Backend | À corriger |
| DB-005 | P2 | Base de données | Backend | Backlog |
| DB-006 | P2 | Base de données | Backend | À corriger |
| DB-007 | P2 | Base de données | Backend | À corriger |
| ADM-001 | P1 | Dashboard | Frontend | À corriger |
| ADM-002 | P1 | Dashboard | Frontend | À corriger |
| ADM-003 | P1 | Dashboard | Frontend | À corriger |
| ADM-004 | P1 | Dashboard | Frontend | À corriger |
| ADM-005 | P1 | Dashboard | Frontend | À corriger |
| ADM-006 | P2 | Dashboard | Frontend | À corriger |
| ADM-007 | P2 | Dashboard | Frontend | À corriger |
| ADM-008 | P2 | Dashboard | Frontend | À corriger |
| ADM-009 | P2 | Dashboard | Frontend | À corriger |
| ADM-010 | P2 | Dashboard | Frontend | À corriger |
| ADM-011 | P3 | Dashboard | Frontend | Backlog |
| ADM-012 | P3 | Dashboard | Frontend | À corriger |
| ADM-013 | P3 | Dashboard | Frontend | À corriger |
| MOB-001 | P0 | Mobile | Mobile | À corriger |
| MOB-002 | P1 | Mobile | Mobile | À corriger |
| MOB-003 | P1 | Mobile | Mobile | À corriger |
| MOB-004 | P1 | Mobile | Mobile | À corriger |
| MOB-005 | P1 | Mobile | Mobile | À corriger |
| MOB-006 | P2 | Mobile | Mobile | À corriger |
| MOB-007 | P2 | Mobile | Mobile | Backlog |
| MOB-008 | P2 | Mobile | Mobile | Backlog |
| MOB-009 | P2 | Mobile | Mobile | Backlog |
| GDPR-001 | P1 | RGPD | Backend | À corriger |
| GDPR-002 | P1 | RGPD | Backend | À corriger |
| GDPR-003 | P2 | RGPD | Backend | À corriger |
| GDPR-004 | P2 | RGPD | Backend | À corriger |
| GDPR-005 | P2 | RGPD | Backend | Backlog |
| API-001 | P1 | API Design | Backend | À corriger |
| API-002 | P2 | API Design | Backend | À corriger |
| API-003 | P2 | API Design | Backend | À corriger |
| API-004 | P2 | API Design | Backend | À corriger |
| API-005 | P2 | API Design | Backend | À corriger |
| API-006 | P3 | API Design | Backend | Backlog |
| CQ-001 | P2 | Code Quality | Backend | À corriger |
| CQ-002 | P2 | Code Quality | Backend | À corriger |
| CQ-003 | P2 | Code Quality | Backend | À corriger |
| CQ-004 | P2 | Code Quality | Backend | À corriger |
| CQ-005 | P2 | Code Quality | Backend | À corriger |
| CQ-006 | P2 | Code Quality | Backend | À corriger |
| CQ-007 | P3 | Code Quality | Backend | Backlog |
| CQ-008 | P3 | Code Quality | Backend | Backlog |
| CFG-001 | P2 | Configuration | Backend | À corriger |
| CFG-002 | P2 | Configuration | Backend | À corriger |
| CFG-003 | P3 | Configuration | Tous | Backlog |
| CFG-004 | P3 | Configuration | Frontend | Backlog |

### 7.2 Comptage par sévérité

| Sévérité | Nombre |
|----------|--------|
| P0 (Critique) | 9 |
| P1 (Haut) | 24 |
| P2 (Moyen) | 27 |
| P3 (Bas) | 8 |
| **Total** | **68** |

### 7.3 Comptage par composant

| Composant | P0 | P1 | P2 | P3 | Total |
|-----------|----|----|----|----|-------|
| Backend | 5 | 12 | 18 | 4 | 39 |
| Frontend (Admin) | 1 | 5 | 6 | 3 | 15 |
| Mobile | 3 | 5 | 4 | 0 | 12 |
| Cross-component | 0 | 2 | 0 | 0 | 2 |
| **Total** | **9** | **24** | **28** | **7** | **68** |

---

*Ce document est la référence unique pour toutes les corrections à apporter au projet Xelkoom Data Collect avant son déploiement national. Chaque issue doit être traitée dans son sprint assigné et validée par revue de code.*
