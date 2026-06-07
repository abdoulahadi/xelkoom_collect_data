# 📐 PRD — Xelkoom : Plateforme communautaire de collecte de corpus ouverts pour langues africaines sous-dotées

> **Product Requirements Document** — version candidature **LINGUA Africa (Masakhane African Languages Hub, Cycle 3)**
> **Catégorie de dépôt** : **Catégorie 1 — Création de données** (livrable = corpus ouverts ; l'app = instrument de collecte participative communautaire).
> **Documents liés** : [Analyse de candidature](ANALYSE_CANDIDATURE_LINGUA_AFRICA.md) · [Appel à propositions](../candidature_masakhane.md) · [Description projet](DESCRIPTION_PROJET_COMPLET.md) · [Audit technique](AUDIT_REPORT.md)
> **Statut** : Draft v1 — Date : juin 2026

---

## 0. Comment lire ce document

Ce PRD distingue **trois niveaux** pour chaque exigence :
- **[EXISTE]** : déjà implémenté et vérifié dans le code (réutilisable tel quel).
- **[À FINIR]** : partiellement implémenté ou désactivé (stub) → à compléter.
- **[NOUVEAU]** : non implémenté, requis pour gagner l'appel.

Cette traçabilité est elle-même un argument : elle prouve que le projet part d'un **socle technique réel**, pas d'une idée sur papier.

---

## 1. Vision & énoncé produit

**Xelkoom** est une plateforme communautaire qui permet de **collecter, valider, documenter et publier des corpus vocaux (et textuels) ouverts** pour les langues africaines sous-dotées, en commençant par le **Wolof** et en s'étendant de façon pilote à un petit ensemble de langues sénégambiennes.

Le **livrable financé** est un **jeu de données ouvert, documenté et réutilisable** (parole + transcriptions), publié sous licence permissive sur des plateformes publiques (Hugging Face / Zenodo / GitHub). L'application mobile, le backend et le dashboard d'administration constituent l'**instrument de production** de ce corpus, via une **méthode de collecte participative communautaire**.

> **Énoncé produit** : *« Permettre à n'importe quelle communauté linguistique africaine de produire, en quelques semaines, un corpus vocal ouvert de qualité TTS/ASR, grâce à une app mobile de collecte, un pipeline de traitement audio standardisé et un atelier de modération/documentation. »*

---

## 2. Alignement avec LINGUA Africa (Catégorie 1)

| Objectif de l'appel (Catégorie 1) | Réponse Xelkoom | Niveau |
|---|---|---|
| Collecter des ensembles de données (texte/parole/vision) | Pipeline de collecte audio + transcriptions | [EXISTE] / [À FINIR] |
| Cas d'usage clairement défini dans un secteur prioritaire | Ancrage **éducation/alphabétisation** & **information santé publique** en Wolof | [NOUVEAU] |
| Diversité locuteurs, dialectes, sous-domaines | Métadonnées genre/âge + **dialecte/région à ajouter** | [À FINIR] |
| Annotation & validation normalisées | Modération + score qualité ; **validation ASR à réactiver** | [À FINIR] |
| Documentation des données (cadres standardisés) | **Data card / datasheet / format Croissant** | [NOUVEAU] |
| Publication sur HF / GitHub / Zenodo | **Pipeline d'export + publication** | [NOUVEAU] |
| Consentement éclairé & participation communautaire | Consentement RGPD intégré + **protocole participatif** | [EXISTE] / [À FINIR] |
| Licences ouvertes (Apache/MIT/CC) | **LICENSE code + licence dataset CC-BY** | [NOUVEAU] |
| Équilibre genre & inclusion | Démographie collectée + **équilibrage actif** | [À FINIR] |

---

## 3. Personas & parties prenantes

| Persona | Besoin principal | Surface produit |
|---|---|---|
| **Contributeur·rice communautaire** | Enregistrer facilement sa voix, comprendre l'usage, être reconnu·e | App mobile |
| **Animateur·rice communautaire / partenaire local** (radio, école, association) | Mobiliser des locuteurs, suivre la progression | App + tableau de bord léger |
| **Modérateur·rice / linguiste** | Valider la qualité, annoter, rejeter avec motif | Dashboard admin |
| **Administrateur·rice projet** | Gérer phrases, langues, utilisateurs, exporter le corpus | Dashboard admin |
| **Chercheur·e / réutilisateur·rice (écosystème)** | Télécharger un dataset documenté sous licence ouverte | Hugging Face / Zenodo |
| **Bailleur (LINGUA Africa)** | Vérifier l'impact, l'ouverture, la gouvernance | Rapports + datasets publiés |

---

## 4. Périmètre (Scope)

### 4.1 Dans le périmètre (cycle de subvention)
- Collecte vocale **participative** Wolof (langue pilote) + **2 à 4 langues sénégambiennes** (Sérère, Pulaar/Peul, Mandinka, Diola) selon partenariats.
- Modalités : **parole + texte** (phrase-source/transcription). Vision-langage **hors périmètre** ce cycle (option future).
- Pipeline complet : collecte → traitement audio → modération/validation → documentation → **publication du dataset ouvert**.
- Ancrage **secteur prioritaire** (éducation/alphabétisation et/ou santé publique).
- **Gouvernance des données** : consentement, droit à l'effacement, anonymisation, licence.

### 4.2 Hors périmètre (ce cycle)
- Entraînement/déploiement d'un modèle TTS/ASR à grande échelle (relève des Catégories 2/3).
- Modalité vision/OCR.
- Application destinée à l'utilisateur final dans un secteur (déploiement 50k+ utilisateurs = Catégorie 3).

---

## 5. État de l'art interne (As-Is) — synthèse des 3 apps

### 5.1 Backend (FastAPI) — [EXISTE]
- API REST complète : auth JWT, users, sentences, recordings, admin (≈ 34+ endpoints).
- **Pipeline audio réel** : conversion FFmpeg → **WAV mono 16 kHz PCM 16-bit**, normalisation RMS −20 dB, trim silence (librosa), **score qualité** (0–1), métadonnées (durée, sample rate, taille).
- **Modération** : statut pending/validated/rejected, notes admin, bulk.
- **RGPD** : suppression de compte, **export ZIP des données utilisateur**, révocation de consentement, **rétention** (purge rejetés 90 j, anonymisation comptes inactifs 2 ans, nettoyage orphelins).
- **Sélection équilibrée** des phrases (pondération inverse au nombre d'enregistrements).
- **Export metadata format LJSpeech** (TTS).
- **Stockage** local **ou S3** (détection auto, chiffrement AES256 côté S3).
- Sécurité : bcrypt, en-têtes OWASP, rate limiting (slowapi/Redis), CORS configurable.
- Déploiement : Docker multi-stage, Render, health checks.

**Limites backend** : Whisper **désactivé** (stub) ; **mono-langue** (`wo` codé en dur) ; pas d'export **audio ZIP en masse** ; pas de **dialecte/région** ; SQLite par défaut (PostgreSQL requis en prod) ; pas de scheduler de rétention ; tests partiels.

### 5.2 App mobile (Flutter) — [EXISTE]
- Auth (register/login/refresh JWT, stockage chiffré), onboarding 5 pages, **consentement RGPD explicite**, écran permissions.
- **Enregistrement** : `flutter_sound`, **16 kHz mono**, codec auto-détecté, lecture/relecture.
- **Offline-first** : SQLite local + **service de synchronisation** auto (toutes les 5 min, retry).
- **i18n bilingue Français/Wolof** (140+ chaînes), Leaderboard, profil/stats, historique paginé.
- Politique de confidentialité conforme **Code Numérique du Sénégal / CDP**.

**Limites mobile** : pas de **waveform**/feedback qualité temps réel ; **points/badges** annoncés mais non implémentés ; **collecte mono-langue** (pas de sélecteur de langue cible) ; durée min/max non contrôlée ; couverture de tests ≈ nulle.

### 5.3 Dashboard admin (React/TS) — [EXISTE]
- 8 pages (Dashboard, Moderation, Users, Sentences, Balance, Analytics, Settings, Login).
- **Modération audio** (lecteur HTML5, raccourcis clavier, notes, bulk), **CRUD phrases & users**, **import bulk** de phrases, **analytics Recharts** + démographie (genre/âge), **dashboard d'équilibrage**.
- Auth JWT (sessionStorage), permissions par rôle, export **JSON** client-side.

**Limites dashboard** : **WebSocket annoncé mais absent** (polling 30 s) ; **export CSV/ZIP** : API prête mais **UI manquante** ; **pas de sélecteur de langue** ; équilibrage phonétique/démographique non exposé ; aucun test.

---

## 6. Exigences fonctionnelles (To-Be)

> Priorité : **P0** = bloquant pour la candidature, **P1** = fort impact sur la note, **P2** = amélioration.

### 6.1 Collecte multilingue & multimodale légère
| ID | Exigence | Niveau | Prio |
|---|---|---|---|
| FR-01 | Gérer **N langues cibles de collecte** (champ `language` déjà en base) : sélecteur de langue dans l'app et le dashboard, filtrage des phrases par langue | [À FINIR] | **P0** |
| FR-02 | Associer chaque phrase à `language` + `dialect`/`region` optionnels | [NOUVEAU] | P1 |
| FR-03 | Couplage **texte ↔ parole** : exporter la transcription (phrase-source) avec chaque audio | [EXISTE] | **P0** |
| FR-04 | Contrôler la **durée min/max** d'enregistrement côté app (ex. 1–30 s) avant upload | [À FINIR] | P1 |
| FR-05 | **Feedback qualité** à l'enregistrement (niveau sonore / waveform basique, détection silence) | [NOUVEAU] | P2 |

### 6.2 Validation & assurance qualité
| ID | Exigence | Niveau | Prio |
|---|---|---|---|
| FR-06 | **Réactiver une validation automatique parole↔texte** (ASR/Whisper ou alternative) ou retirer la sur-promesse marketing | [À FINIR] | **P0** |
| FR-07 | Score qualité affiché et **éditable** en modération | [À FINIR] | P1 |
| FR-08 | Workflow modération multi-rôle : activer le rôle **moderator** (déjà en base, non câblé) | [À FINIR] | P1 |
| FR-09 | Double validation / accord inter-annotateurs pour un sous-échantillon (qualité scientifique) | [NOUVEAU] | P2 |

### 6.3 Documentation & publication du dataset (cœur Catégorie 1)
| ID | Exigence | Niveau | Prio |
|---|---|---|---|
| FR-10 | **Export du corpus en ZIP** (audio WAV + `metadata.csv`/manifest) depuis le dashboard (API existe, UI à ajouter) | [À FINIR] | **P0** |
| FR-11 | Générer une **fiche de données (datasheet / dataset card)** : provenance, locuteurs, conditions, format, splits, limites, biais | [NOUVEAU] | **P0** |
| FR-12 | Export au **format interopérable** (Common Voice-like / Hugging Face `datasets` / Croissant) avec splits train/dev/test | [NOUVEAU] | **P0** |
| FR-13 | **Pipeline de publication** vers Hugging Face / Zenodo (DOI) + dépôt GitHub du code | [NOUVEAU] | **P0** |
| FR-14 | Export **CSV** des métadonnées (déjà côté API) exposé en UI | [À FINIR] | P1 |

### 6.4 Gouvernance, éthique & conformité
| ID | Exigence | Niveau | Prio |
|---|---|---|---|
| FR-15 | **Licence** : ajouter `LICENSE` (code MIT/Apache-2.0) + **licence dataset CC-BY-4.0** documentée | [NOUVEAU] | **P0** |
| FR-16 | **Consentement éclairé** versionné, traçable et **révocable** (socle existant à renforcer) | [À FINIR] | **P0** |
| FR-17 | **Droit à l'effacement** & anonymisation (déjà implémentés) — documenter et exposer côté app | [EXISTE] | P1 |
| FR-18 | **Audit log** des actions admin (modération, suppression) pour la traçabilité | [NOUVEAU] | P1 |
| FR-19 | **Équilibrage genre/âge/dialecte** actif : tableau de bord d'équité + ciblage de collecte | [À FINIR] | P1 |
| FR-20 | Plan de **sensibilité aux conflits, genre, impact environnemental** (lignes directrices Masakhane) | [NOUVEAU] | P1 |

### 6.5 Engagement communautaire
| ID | Exigence | Niveau | Prio |
|---|---|---|---|
| FR-21 | **Espace partenaire/animateur** : suivi de progression par communauté/campagne | [NOUVEAU] | P1 |
| FR-22 | Finaliser la **gamification** réellement (points/badges) ou aligner le discours | [À FINIR] | P2 |
| FR-23 | Tableau de bord public **transparence** (heures collectées, langues, % validé) | [NOUVEAU] | P2 |

---

## 7. Exigences non-fonctionnelles (NFR)

| ID | Catégorie | Exigence | Niveau |
|---|---|---|---|
| NFR-01 | **Qualité audio** | WAV mono 16 kHz PCM 16-bit, normalisation −20 dB RMS, trim silence | [EXISTE] |
| NFR-02 | **Scalabilité** | PostgreSQL en production (pooling déjà prévu) ; stockage S3 | [À FINIR] |
| NFR-03 | **Sécurité** | JWT, bcrypt, en-têtes OWASP, rate limiting, CORS strict ; **corriger P0/P1 de l'audit** | [À FINIR] |
| NFR-04 | **Disponibilité** | Health checks, déploiement Docker/Render reproductible | [EXISTE] |
| NFR-05 | **Confidentialité** | Chiffrement transport + stockage (S3 AES256) ; chiffrement au repos DB à évaluer | [À FINIR] |
| NFR-06 | **Reproductibilité** | Scripts d'export déterministes, versionnage du dataset (semver + DOI) | [NOUVEAU] |
| NFR-07 | **Testabilité** | Couverture de tests cible ≥ 60 % backend, smoke tests mobile/dashboard | [NOUVEAU] |
| NFR-08 | **Accessibilité / i18n** | UI FR/WO ; extensible aux langues partenaires | [À FINIR] |
| NFR-09 | **Observabilité** | Logs JSON, métriques, Sentry optionnel | [EXISTE] |
| NFR-10 | **Coût / soutenabilité** | Hébergement à coût maîtrisé ; crédits compute LINGUA Africa pour traitement par lots | [NOUVEAU] |

---

## 8. Évolutions du modèle de données

| Entité | Champ à ajouter | Raison | Niveau |
|---|---|---|---|
| `Sentence` | `dialect`, `region`, `domain` (santé/éducation/…) | Diversité dialectale & ancrage sectoriel (FR-02) | [NOUVEAU] |
| `User` | `region`, `native_language`, `dialect` (optionnels, consentis) | Diversité locuteurs, équité (FR-19) | [NOUVEAU] |
| `Recording` | `transcription` (copie figée du texte), `consent_version`, `validation_method` | Reproductibilité, gouvernance (FR-03, FR-16) | [À FINIR] |
| `DatasetRelease` (nouvelle) | `version`, `language`, `license`, `doi`, `splits`, `stats`, `created_at` | Versionnage & publication (FR-12/13) | [NOUVEAU] |
| `AuditLog` (nouvelle) | `actor`, `action`, `target`, `timestamp`, `meta` | Traçabilité admin (FR-18) | [NOUVEAU] |

---

## 9. Indicateurs de succès (KPI / OKR)

### 9.1 KPI corpus (livrable principal)
- **Heures de parole validées** collectées (cible à fixer par budget, ex. *X heures*).
- **Nombre de locuteurs distincts** + **équilibre genre** (objectif ≥ 40 % de chaque genre).
- **Nombre de langues** couvertes (Wolof + 2–4).
- **Taux de validation** (validés / soumis) et **score qualité moyen**.
- **Couverture dialectale / régionale**.

### 9.2 KPI ouverture & réutilisation
- **Dataset publié** sur Hugging Face + **DOI Zenodo** (oui/non) + complétude de la **data card**.
- **Téléchargements / réutilisations** du dataset.
- **Licence ouverte** effective (CC-BY) — fichier présent.

### 9.3 KPI communauté & impact
- Nombre de **partenaires communautaires** mobilisés (radios, écoles, associations).
- Nombre de **contributeurs actifs** et rétention.
- Ancrage **sectoriel** démontré (jeu d'évaluation lié au cas d'usage).

---

## 10. Feuille de route (alignée période de subvention)

> Jalons exprimés en **livrables de données**, pas en fonctionnalités logicielles (exigence Catégorie 1).

| Phase | Durée indicative | Livrables clés | Exigences |
|---|---|---|---|
| **P0 — Fondations conformité** | Mois 1 | `LICENSE` + licence dataset, consentement versionné, PostgreSQL prod, correction P0/P1 audit | FR-15, FR-16, NFR-02/03 |
| **P1 — Multilingue & documentation** | Mois 1–2 | Sélecteur de langue (app+dashboard), `dialect`/`region`, export ZIP+CSV, ébauche data card | FR-01, FR-02, FR-10, FR-11, FR-14 |
| **P2 — Collecte participative** | Mois 2–4 | Campagnes communautaires (Wolof + langue 2), espace partenaire, équilibrage genre/dialecte | FR-19, FR-21 |
| **P3 — Validation & qualité** | Mois 3–5 | Validation auto réactivée ou alternative, rôle modérateur, accord inter-annotateurs (échantillon) | FR-06, FR-07, FR-08, FR-09 |
| **P4 — Publication v1** | Mois 5–6 | **Dataset v1 publié** (HF + Zenodo DOI) + data card + format interopérable + splits | FR-12, FR-13 |
| **P5 — Extension & pérennité** | Mois 6+ | Langues 3–4, rapport d'enseignements, plan de soutenabilité | FR-01, FR-20, NFR-10 |

---

## 11. Risques & mitigations

| Risque | Impact | Mitigation |
|---|---|---|
| **Survente technique** (Whisper « 95 % » alors que désactivé) | Crédibilité jury | FR-06 : réactiver/mesurer **ou** aligner le discours sur le réel |
| **Échelle insuffisante** (~49 enregistrements actuels) | Note faible | Cibles réalistes + campagnes communautaires + crédits compute pour traitement |
| **Absence de dataset publié** | Critère « ouverture » non rempli | FR-10/11/12/13 prioritaires (P0) |
| **Pas de licence** | Disqualifiant sur l'ouverture | FR-15 (P0) |
| **Éligibilité entité africaine** | Admissibilité | Documenter l'entité + partenaires + lettres de soutien |
| **Dette technique** (audit : 63 issues, 2 P0) | Pérennité fragile | NFR-03/07 : corriger P0/P1, ajouter tests/CI |
| **Données sensibles / éthique** | Conformité Masakhane | FR-16/17/18/20 : gouvernance formalisée |

---

## 12. Dépendances & ressources

- **Ressources de calcul** (crédits Azure/GCP LINGUA Africa) : traitement audio par lots, validation ASR, génération de splits.
- **Assistance technique LINGUA Africa** : curation des données, design d'évaluation/benchmark, bonnes pratiques de publication.
- **Partenaires communautaires** : recrutement de locuteurs, ancrage dialectal, légitimité.
- **Entité juridique africaine** : portage du contrat et conformité (exigence d'admissibilité).

---

## 13. Synthèse : ce qui transforme le projet en candidature gagnante

1. **Repositionner le livrable** : un **corpus ouvert publié et documenté**, pas « une plateforme ».
2. **Rendre l'ouverture tangible** : `LICENSE` + licence **CC-BY** + **dataset sur Hugging Face/Zenodo** + **data card** + format **interopérable**. *(P0)*
3. **Aligner le discours technique sur la réalité** (validation ASR) et **prouver la qualité** par des métriques honnêtes. *(P0)*
4. **Activer le multilingue** (le champ existe déjà) pour passer de Wolof-only à un **socle réplicable**. *(P0)*
5. **Formaliser la gouvernance éthique** (consentement versionné, effacement, audit, équité genre/dialecte). *(P0/P1)*
6. **Ancrer dans un secteur** (éducation/santé) avec bénéficiaires et voie d'impact clairs. *(P1)*
7. **Documenter la pérennité** : entité juridique, partenaires, plan de continuité, soutenabilité des coûts.

> Le code existant (backend mature, app mobile offline-first, dashboard de modération) est un **avantage compétitif réel** : la majorité des candidats partira de zéro. La valeur ajoutée du cycle de subvention n'est pas de « développer un outil », mais de **produire, documenter et ouvrir de la donnée** à l'échelle, en s'appuyant sur cet instrument déjà fonctionnel.
