# Gestion des Incidents Informatiques

Plateforme web de gestion des tickets d'incidents informatiques, des affectations aux techniciens et du suivi des interventions, développée avec **PostgreSQL** et **Flask**.

> Projet réalisé dans le cadre du module **Bases de Données Avancées PostgreSQL** — Licence 3 TDSI, Faculté des Sciences et Techniques, Université Cheikh Anta Diop de Dakar (UCAD).
>
> Laboratoire d'Algèbre, de Cryptologie, de Géométrie Algébrique et Applications (LACGAA)
> Encadrante : Dr Aminata NGOM

## Table des matières

- [Contexte](#contexte)
- [Fonctionnalités](#fonctionnalités)
- [Architecture](#architecture)
- [Stack technique](#stack-technique)
- [Structure du projet](#structure-du-projet)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Variables d'environnement](#variables-denvironnement)
- [Comptes de démonstration](#comptes-de-démonstration)
- [Rôles et permissions](#rôles-et-permissions)
- [Sécurité](#sécurité)
- [Auteurs](#auteurs)
- [Licence](#licence)

## Contexte

Dans une organisation, le suivi des pannes informatiques (« incidents ») est souvent fait de manière informelle (appels, messages, tableurs), ce qui fait perdre la trace de qui a signalé quoi, qui s'en est occupé, et si le problème a réellement été résolu.

Ce projet centralise, sécurise et trace de bout en bout le traitement des incidents informatiques d'une organisation, en s'appuyant fortement sur les mécanismes avancés de PostgreSQL (contraintes, vues, fonctions/procédures PL/pgSQL, triggers, transactions, rôles et privilèges, audit) plutôt que sur la seule couche applicative.

## Fonctionnalités

- Authentification sécurisée (mots de passe hachés avec `scrypt` via Werkzeug)
- Trois profils utilisateurs (Utilisateur, Technicien, Administrateur) avec des interfaces et droits différenciés
- Création, affectation, suivi et clôture des incidents
- Historique complet : commentaires, interventions, affectations
- Tableau de bord avec statistiques par statut
- Journal d'audit complet (qui a fait quoi, et quand), alimenté automatiquement par un trigger PostgreSQL
- Double barrière de sécurité : contrôle applicatif (Flask) **et** contrôle au niveau de la base (`SET ROLE` + privilèges PostgreSQL)

## Architecture

Le projet est organisé en trois couches :

1. **Couche données** — PostgreSQL : tables, contraintes, vues, fonctions/procédures PL/pgSQL, triggers, rôles et privilèges.
2. **Couche applicative** — Flask (Python), organisée en trois Blueprints (`auth`, `incidents`, `admin`), avec `psycopg2` comme pilote d'accès à PostgreSQL.
3. **Couche présentation** — templates Jinja2 (HTML) et une feuille de style CSS commune.

Le point clé de l'architecture : chaque utilisateur connecté voit sa connexion PostgreSQL basculer automatiquement sur son rôle métier via `SET ROLE` (voir `app/db.py`). Ainsi, même si une faille existait côté applicatif, PostgreSQL refuserait quand même les opérations non autorisées.

## Stack technique

| Composant | Technologie |
|---|---|
| Base de données | PostgreSQL 16 |
| Backend | Python 3 / Flask |
| Driver base de données | psycopg2 |
| Authentification | Werkzeug (`scrypt`) |
| Templates | Jinja2 |
| Modélisation | Merise (MCD réalisé avec Looping) |

## Structure du projet

```
gestion-incidents-informatiques/
├── app/
│   ├── __init__.py          # Fabrique de l'application (create_app)
│   ├── auth.py              # Blueprint authentification (login/logout)
│   ├── incidents.py         # Blueprint métier (dashboard, incidents, audit)
│   ├── admin.py             # Blueprint administration (utilisateurs)
│   ├── db.py                # Connexion PostgreSQL + SET ROLE
│   ├── helpers.py           # Décorateurs de sécurité (login/rôles)
│   ├── static/css/          # Feuille de style
│   └── templates/           # Pages HTML (Jinja2)
├── sql/
│   ├── script_examen_BDD.sql     # Script complet de création de la base
│   ├── roles_privileges.sql      # Création des rôles et privilèges
│   └── transactions_demo.sql     # Démonstration COMMIT/ROLLBACK/SAVEPOINT
├── scripts/
│   └── migrer_mots_de_passe.py   # Migration des mots de passe vers un hash sécurisé
├── config.py                # Configuration (variables d'environnement)
├── run.py                   # Point d'entrée de l'application
├── requirements.txt         # Dépendances Python
├── .env.example             # Modèle de configuration (à copier en .env)
└── README.md
```

## Prérequis

- Python 3.10 ou supérieur
- PostgreSQL 14 ou supérieur
- pip

## Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/VOTRE_PSEUDO/gestion-incidents-informatiques.git
cd gestion-incidents-informatiques

# 2. Créer un environnement virtuel (recommandé)
python -m venv venv
source venv/bin/activate      # Sous Windows : venv\Scripts\activate

# 3. Installer les dépendances
pip install -r requirements.txt

# 4. Créer la base de données
psql -U postgres -c "CREATE DATABASE gestion_des_incidents_informatiques"

# 5. Importer le schéma complet (tables, contraintes, vues, fonctions, triggers, données de test)
psql -U postgres -d gestion_des_incidents_informatiques -f sql/script_examen_BDD.sql

# 6. Créer les rôles PostgreSQL et attribuer les privilèges
psql -U postgres -d gestion_des_incidents_informatiques -f sql/roles_privileges.sql

# 7. Configurer les variables d'environnement
cp .env.example .env
# puis éditer .env avec vos propres valeurs (mot de passe, clé secrète...)

# 8. Lancer l'application
python run.py
```

L'application est ensuite accessible sur `http://127.0.0.1:5000`.

## Déploiement avec Docker

Le projet peut être lancé entièrement avec Docker, sans installer Python ni PostgreSQL sur la machine.

### Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et lancé

### Lancement

```bash
# 1. Copier le fichier d'environnement
cp .env.example .env
# puis éditer .env : renseigner DB_PASSWORD, POSTGRES_PASSWORD et FLASK_SECRET_KEY

# 2. Construire les images et démarrer les conteneurs
docker compose up --build
```

Au premier démarrage, PostgreSQL importe automatiquement `sql/script_examen_BDD.sql` (schéma + données de test) puis `sql/roles_privileges.sql` (rôles et privilèges) — aucune commande manuelle n'est nécessaire.

L'application est ensuite accessible sur `http://localhost:5000`.

### Commandes utiles

```bash
# Lancer en arrière-plan
docker compose up -d

# Voir les logs de l'application
docker compose logs -f web

# Arrêter les conteneurs (les données PostgreSQL sont conservées)
docker compose down

# Arrêter et supprimer aussi les données PostgreSQL (repart de zéro)
docker compose down -v

# Se connecter à la base depuis le conteneur PostgreSQL
docker compose exec db psql -U postgres -d gestion_des_incidents_informatiques
```

## Variables d'environnement

Voir `.env.example` pour le modèle complet.

| Variable | Description |
|---|---|
| `DB_HOST` | Hôte PostgreSQL (ex. `localhost`) |
| `DB_PORT` | Port PostgreSQL (défaut `5432`) |
| `DB_NAME` | Nom de la base de données |
| `DB_USER` | Rôle applicatif de connexion (`app_login`) |
| `DB_PASSWORD` | Mot de passe du rôle `app_login` |
| `FLASK_SECRET_KEY` | Clé secrète Flask (sessions) — à générer aléatoirement |

## Comptes de démonstration

Ces comptes existent uniquement dans le jeu de données de test importé par `script_examen_BDD.sql` :

| Rôle | Email | Mot de passe |
|---|---|---|
| ADMIN | aminatadiallo@gmail.com | motdepasse123 |
| TECHNICIEN | souleymaneba@gmail.com | motdepasse456 |
| UTILISATEUR | aissatougaye@gmail.com | motdepasse789 |

> À ne conserver qu'en environnement local/démonstration. Ne jamais utiliser ces identifiants sur un déploiement accessible publiquement.

## Rôles et permissions

Cinq rôles PostgreSQL composent l'architecture de sécurité : `postgres` (superutilisateur, administration uniquement), `app_login` (seul point d'entrée de l'application, sans privilège propre), et trois rôles métier `admin_role`, `technicien_role`, `utilisateur_role` correspondant aux trois profils applicatifs.

| Page | UTILISATEUR | TECHNICIEN | ADMIN |
|---|---|---|---|
| Tableau de bord | Oui | Oui | Oui |
| Liste des incidents | Oui | Oui | Oui |
| Nouvel incident | Oui | Non | Oui |
| Détail d'un incident | Oui (lecture) | Oui | Oui |
| Affecter / changer statut / intervention / clôture | Non | Oui | Oui |
| Ajouter un commentaire | Oui | Oui | Oui |
| Journal d'audit | Non | Non | Oui |
| Gestion des utilisateurs | Non | Non | Oui |

## Sécurité

- Mots de passe hachés avec l'algorithme `scrypt` (module `werkzeug.security`), jamais stockés en clair
- Requêtes SQL systématiquement paramétrées (`%s`) via `psycopg2` — aucune concaténation de chaînes, protection contre l'injection SQL
- Double barrière de contrôle d'accès : décorateurs Flask (`login_required`, `roles_required`) **et** privilèges PostgreSQL réels par rôle
- Audit automatique de toute modification des incidents via trigger PostgreSQL (`trg_audit_incident`), indépendant du code applicatif

## Auteurs

- Aminata Diallo
- Aissatou Gaye

Encadrante : Dr Aminata NGOM

## Licence

Projet académique — voir le fichier [LICENSE](LICENSE).
