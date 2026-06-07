# 🎯 Analyse de candidature — LINGUA Africa (Masakhane African Languages Hub, Cycle 3)

> **Objet** : Choix de la catégorie de dépôt + analyse critique de l'adéquation du projet **Xelkoom** à l'appel à propositions LINGUA Africa.
> **Date limite de soumission** : 15 juin 2026 (23h59 WAT).
> **Document de référence** : [candidature_masakhane.md](../candidature_masakhane.md)

---

## 1. Synthèse exécutive (TL;DR)

| Élément | Constat |
|---|---|
| **Catégorie recommandée** | **Catégorie 1 — Création de données** (objectif principal & usage principal des fonds) |
| **Alternative stratégique** | **Catégorie 2 — Développement d'outils/infrastructure** (Xelkoom = plateforme réutilisable et multilingue, financement x2) |
| **Force majeure** | Langue sous-dotée (Wolof) + collecte communautaire mobile + pipeline audio standardisé TTS |
| **Risque majeur** | Échelle actuelle très faible (~**49 enregistrements**, 1000 phrases), **aucun dataset publié**, **pas de LICENSE**, validation qualité (Whisper) **désactivée** |
| **Verdict** | Très bon alignement *thématique*, mais le dossier doit passer d'une **plateforme** à un **livrable de données ouvert, documenté et publié** pour être compétitif |

---

## 2. Sur quelle catégorie déposer ?

L'appel précise que les propositions couvrant plusieurs activités doivent être déposées **« dans la catégorie qui reflète le mieux l'objectif principal et l'utilisation principale des fonds demandés »**.

### 2.1 Catégorie 1 — Création de données ✅ (recommandée)
- **Soutien** : jusqu'à **50 000 $** en espèces + **50 000 $** de crédits de calcul.
- **Pourquoi c'est le meilleur fit** : le cœur de Xelkoom est la **collecte, validation et documentation d'un corpus vocal Wolof** destiné à l'entraînement/évaluation TTS. C'est exactement la portée de la Catégorie 1 (collecte, annotation/validation, documentation, considérations éthiques, licences ouvertes).
- L'appel **encourage explicitement** les stratégies de Xelkoom : *« crowdsourcing, enregistrement sur mobile ou partenariats avec médias locaux / établissements d'enseignement »*.

### 2.2 Catégorie 2 — Développement de modèles ou d'outils (alternative à fort potentiel)
- **Soutien** : jusqu'à **100 000 $** + **100 000 $** de crédits — **le double**.
- **Argument** : Xelkoom n'est pas qu'un dataset, c'est une **infrastructure technique réutilisable** (API FastAPI, app Flutter, dashboard React, pipeline audio, sélection équilibrée de phrases) **extensible à d'autres langues africaines**. Cela correspond à *« Infrastructure technique et outils : création de pipelines/outils réutilisables… interopérables »*.
- **Condition pour y prétendre** : il faudrait positionner le livrable principal comme **l'outil open-source de collecte** (avec benchmark/évaluation), et non le corpus seul.

### 2.3 Catégorie 3 — Applications sectorielles ❌ (non recommandée en l'état)
- **Soutien** : jusqu'à 250 000 $ + 400 000 $.
- **Pourquoi c'est risqué** : exige un **déploiement réel touchant 50 000–100 000 utilisateurs** dans un secteur prioritaire (santé, éducation, agriculture, inclusion financière, services publics), co-conçu avec les communautés, avec impact social/économique mesurable. Xelkoom **n'a pas encore d'application destinée à l'utilisateur final** dans un secteur. À viser pour un futur cycle.

### 2.4 Recommandation finale
> **Déposer en Catégorie 1** pour un dossier solide et crédible, **OU** en **Catégorie 2** si l'équipe peut crédibiliser Xelkoom comme **outil/infrastructure open-source multilingue avec benchmark** (financement doublé). Éviter la Catégorie 3 ce cycle.

---

## 2bis. Positionnement retenu : Catégorie 1 — collecte participative communautaire

> **Décision de cadrage** : le livrable financé est **la donnée** (corpus ouverts), **pas la plateforme**. L'app Xelkoom est présentée comme l'**instrument de référence** d'une **méthode de collecte participative communautaire**.

### 2bis.1 Règle d'or à respecter
En Catégorie 1, **les fonds doivent servir principalement à produire/valider/documenter de la donnée** — pas à développer du logiciel. La plateforme est le **moyen**, le **dataset ouvert** est la **fin**. Tout budget majoritairement orienté « dev » ferait basculer le dossier en Catégorie 2.

### 2bis.2 Les 3 garde-fous de crédibilité

| # | Garde-fou | À faire | À éviter (survente) |
|---|---|---|---|
| 1 | **Donnée d'abord, app comme instrument** | Livrable = *« N heures de parole + transcriptions validées, publiées sous licence ouverte avec fiche de données »* | Présenter « la plateforme » comme le produit |
| 2 | **Multimodal réaliste** | **Parole** (force actuelle) + **texte** (1000 phrases déjà disponibles). Vision-langage **seulement** si un cas d'usage le justifie | Annoncer texte+parole+vision « pour toutes langues » avec ~49 enregistrements |
| 3 | **Multilingue progressif** | **Wolof (pilote)** + **2 à 4 langues sénégambiennes** (Sérère, Pulaar/Peul, Mandinka, Diola) via partenaires | Promettre 10–30 langues ce cycle |

### 2bis.3 Pourquoi « participatif communautaire » marque des points
- **Explicitement encouragé** par l'appel : *« crowdsourcing, enregistrement mobile, partenariats avec médias locaux, établissements d'enseignement, organisations communautaires ou culturelles »*.
- **Aligné Ubuntu/Masakhane** : place « les voix et priorités de la communauté au centre ».
- Coche directement les critères **« Engagement communautaire et collaboration »** et **« Ouverture et réutilisabilité »**.

### 2bis.4 Formulation suggérée du résumé (point 1 du dossier)
> *« Xelkoom mobilise une **méthode de collecte participative communautaire** — via une application mobile de référence — pour produire, valider et documenter des **corpus vocaux et textuels ouverts** de langues africaines sous-dotées. Cycle 1 : un corpus Wolof de référence (parole + transcriptions) et une extension pilote à [2–4 langues] menée avec des partenaires communautaires, publiés sous licence ouverte (CC-BY) avec fiches de données, prêts pour l'entraînement et l'évaluation de systèmes TTS/ASR. »*

Ce cadrage : ✅ reste en Catégorie 1, ✅ valorise communautaire/multimodal/multilingue, ✅ évite la survente, ✅ couvre « collecter, organiser, documenter, licences ouvertes ».

### 2bis.5 Implications concrètes sur le dossier
- **Budget (point 16)** : majorité allouée à la **collecte/validation/documentation** (animation communautaire, défraiement des locuteurs, contrôle qualité, publication), minorité au support technique de l'app.
- **Méthodologie (point 9)** : décrire le **protocole participatif** (recrutement des locuteurs, consentement, sessions communautaires, boucle de validation).
- **Calendrier (point 11)** : jalons en **heures de parole / nombre de locuteurs / langues couvertes**, pas en fonctionnalités logicielles.
- **Résultats (point 10)** : datasets publiés + fiches, pas « une plateforme livrée ».

---

## 3. Ce que le projet respecte déjà (points forts)

| # | Critère d'évaluation LINGUA Africa | Comment Xelkoom y répond | Preuve dans le repo |
|---|---|---|---|
| 1 | **Langues sous-représentées** | Focus Wolof (12M+ locuteurs, <5% des langues africaines outillées) | [docs/DESCRIPTION_PROJET_COMPLET.md](DESCRIPTION_PROJET_COMPLET.md) |
| 2 | **Collecte mobile / crowdsourcing** (explicitement encouragée) | App Flutter d'enregistrement communautaire | [mobile_app/](../mobile_app/) |
| 3 | **Pipeline normalisé qualité données** | WAV mono 16 kHz, normalisation RMS, trim silence | [backend/app/services/audio_processing.py](../backend/app/services/audio_processing.py) |
| 4 | **Métadonnées locuteur** (diversité genre/âge) | Champs `gender`, `age_range` sur `User` | [backend/app/models/__init__.py](../backend/app/models/__init__.py) |
| 5 | **Consentement / RGPD** | Champ `consent_given`, service de rétention | [backend/app/services/data_retention.py](../backend/app/services/data_retention.py) |
| 6 | **Modération / assurance qualité** | Dashboard de modération, `quality_score`, statut `pending/validated/rejected` | [admin_dashboard_react/](../admin_dashboard_react/) |
| 7 | **Intention d'ouverture** | Badge licence MIT, architecture pensée open-source | [README.md](../README.md) |
| 8 | **Documentation** | Documentation projet riche et structurée | [docs/](../docs/) |
| 9 | **Ancrage africain / Ubuntu** | Projet centré Sénégal, langue véhiculaire | [docs/DESCRIPTION_PROJET_COMPLET.md](DESCRIPTION_PROJET_COMPLET.md) |

---

## 4. Ce qu'on peut nettement améliorer (analyse critique)

> Classé par impact sur la note d'évaluation. 🔴 = bloquant/critique, 🟠 = important, 🟡 = à renforcer.

### 4.1 🔴 Échelle du corpus très en deçà des cibles
- **Constat** : ~**49 dossiers audio** réellement présents pour **1000 phrases** dans [data/text_part_1.txt](../data/text_part_1.txt). Les docs annoncent « 10 000+ enregistrements ».
- **Risque** : décalage entre l'ambition affichée et la réalité → crédibilité affaiblie.
- **À faire** : fixer des **cibles chiffrées réalistes et mesurables** (ex. *X heures de parole validée*, *N locuteurs distincts*, *équilibre H/F*, *couverture dialectale*), avec jalons mensuels dans le **calendrier (point 11 du dossier)**.

### 4.2 🔴 Aucun jeu de données publié (exigence forte de l'appel)
- **Constat** : rien sur **Hugging Face / GitHub / Zenodo**. L'appel exige la publication sur *« plateformes accessibles au public… avec documentation appropriée »*.
- **À faire** :
  - Publier un **échantillon de corpus** (même réduit) sur Hugging Face Datasets.
  - Fournir une **fiche de données (datasheet / dataset card)** : provenance, locuteurs, conditions d'enregistrement, format, splits train/test, limites, biais.
  - Adopter un format **interopérable** (manifest type Common Voice / Croissant).

### 4.3 🔴 Licence ouverte non matérialisée
- **Constat** : **aucun fichier `LICENSE`** dans le dépôt malgré le badge MIT du README.
- **À faire** : ajouter `LICENSE` (code : **MIT/Apache-2.0**) et **licence dédiée au dataset** (recommandé : **CC-BY-4.0** ou **CC0**, conformément à l'esprit « biens publics numériques » de Masakhane). Documenter la chaîne de droits/consentement → licence.

### 4.4 🟠 Validation qualité (Whisper) désactivée dans le code
- **Constat** : [backend/app/services/whisper_validation.py](../backend/app/services/whisper_validation.py) — `self.enabled = False`, modèle non chargé. Les docs revendiquent pourtant un *« Whisper fine-tuné Wolof, 95%+ de précision »*.
- **Risque** : **survente technique** facilement détectable par des évaluateurs experts (Microsoft AI for Good, Masakhane).
- **À faire** : soit **réactiver et mesurer réellement** la validation (transcription + similarité), soit **réaligner le discours** sur ce qui est effectivement implémenté. Présenter des **métriques honnêtes**.

### 4.5 🟠 Ancrage faible dans un cas d'usage sectoriel
- **Constat** : corpus TTS « générique ». L'appel **priorise** les données *« ancrées dans une application clairement définie et à fort impact »* (santé, éducation, agriculture, inclusion financière, services publics).
- **À faire** : rattacher la collecte à **un secteur** (ex. **éducation/alphabétisation** ou **information santé publique** en Wolof) et expliciter **bénéficiaires + voie vers l'impact** (critère « Voie vers l'impact et clarté quant aux bénéficiaires »).

### 4.6 🟠 Éligibilité, partenariats & lettres de soutien
- **Constat** : l'appel exige une **entité africaine légalement enregistrée** et **valorise fortement** les consortiums et l'engagement communautaire (points 13 & 14 du dossier).
- **À faire** :
  - Documenter l'**entité juridique** (ONG / entreprise sociale / institut basé en Afrique).
  - Nouer des **partenariats** (universités sénégalaises, radios/médias locaux, écoles, organisations culturelles) + **lettres de soutien**.
  - Démontrer un **équilibre de genre** et une **diversité régionale** de l'équipe (préférence du jury).

### 4.7 🟠 Gouvernance des données & éthique à formaliser
- **Constat** : consentement réduit à un booléen ; pas de protocole formel.
- **À faire** : rédiger un **plan de gouvernance des données** : consentement éclairé documenté, **droit à l'effacement** (RGPD), protection/anonymisation des contributeurs, **sensibilité au genre et aux conflits**, **impact environnemental** (exigés par les lignes directrices Masakhane). Mentionner l'atténuation des **biais** (dialectes, genre, âge).

### 4.8 🟡 Conception d'évaluation / benchmark absente
- **Constat** : pas de **split test figé** ni de **métriques** définies (point 8 « Tâches et conception de l'évaluation »).
- **À faire** : définir un **jeu d'évaluation tenu à l'écart**, des métriques (ex. MOS/intelligibilité pour TTS, WER pour ASR de contrôle), et un **protocole d'analyse comparative**.

### 4.9 🟡 Robustesse technique & pérennité
- **Constat** : l'audit interne recense **63 problèmes** dont **2 P0** ([docs/AUDIT_REPORT.md](AUDIT_REPORT.md)) ; WebSocket désactivé, route `/balance` manquante, division par zéro, usages `any`.
- **Risque** : affaiblit l'argument **« viabilité / continuité au-delà du financement »** (critère d'éligibilité).
- **À faire** : corriger les P0/P1, ajouter **tests**, CI, et un **plan de soutenabilité** (maintenance, hébergement, modèle de continuité).

### 4.10 🟡 Documentation de reproductibilité
- **À faire** : `DATA_CARD.md`, `MODEL_CARD.md` (le cas échéant), scripts d'export reproductibles (CSV/ZIP existent côté admin — les documenter), et un **guide de contribution** communautaire.

---

## 5. Alignement avec les critères d'évaluation (scorecard)

| Critère d'évaluation officiel | État actuel | Note indicative |
|---|---|---|
| Admissibilité (entité africaine enregistrée) | À documenter | ⚠️ À prouver |
| Langues sous-représentées | Wolof, excellent | ✅ Fort |
| Adéquation objectifs LINGUA Africa | Bon (données ouvertes) | ✅ Bon |
| Ouverture & réutilisabilité | Intention oui, **publication non** | 🔴 À corriger |
| Engagement communautaire & partenariats | Mobile oui, **partenariats formels non** | 🟠 À renforcer |
| Voie vers l'impact & bénéficiaires | Flou (pas de secteur ciblé) | 🟠 À préciser |
| Structure du partenariat | Non documentée | 🟠 À construire |
| Adéquation du budget | À rédiger (point 16) | ⚠️ À faire |

---

## 6. Plan d'action prioritaire avant le 15 juin 2026

**Bloquants (à traiter en premier)**
1. Choisir la **catégorie** (recommandé : **Catégorie 1**, ou Catégorie 2 si pivot « outil »).
2. Ajouter un fichier **`LICENSE`** (code) + **licence dataset (CC-BY-4.0)**.
3. **Publier un échantillon** du corpus + **dataset card** sur Hugging Face/Zenodo.
4. Aligner le **discours technique** sur la réalité (Whisper) — ou le réactiver et mesurer.

**Importants**
5. Sécuriser l'**entité juridique africaine** + **partenaires** + **lettres de soutien**.
6. Rédiger le **plan de gouvernance des données & éthique** (consentement, effacement, biais, genre, environnement).
7. Ancrer la collecte dans **un secteur prioritaire** + définir **bénéficiaires** et voie d'impact.
8. Définir la **conception d'évaluation** (split test + métriques).

**À renforcer**
9. Corriger les **P0/P1** de l'audit, ajouter **tests/CI**, plan de **pérennité**.
10. Rédiger le **budget** justifié (point 16) et les **ressources de calcul** (point 17).

---

## 7. Conclusion

Xelkoom dispose d'un **socle thématique et technique réellement pertinent** pour LINGUA Africa : langue sous-dotée, collecte mobile communautaire, pipeline TTS standardisé. La candidature la plus solide consiste à déposer en **Catégorie 1 (Création de données)** — ou en **Catégorie 2** en pivotant vers « outil/infrastructure réutilisable » pour doubler le financement.

Le travail décisif des prochaines semaines n'est **pas** d'ajouter des fonctionnalités, mais de transformer la plateforme en **livrable ouvert, documenté et publié** : une **licence explicite**, un **dataset publié avec sa fiche**, un **discours technique honnête**, un **ancrage sectoriel + bénéficiaires**, et une **gouvernance éthique formalisée**. Ces éléments répondent directement aux critères d'évaluation et feront la différence entre une bonne idée et une proposition financée.
