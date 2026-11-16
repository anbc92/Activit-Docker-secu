# TP : Sécurisation d'une image et d'un conteneur Docker

Audit et sécurisation de l'image Docker de l'application **Quiz Docker** (Vite / JavaScript) avant un déploiement en production.

## Résultat en un coup d'œil

| Critère | Image initiale | Image sécurisée |
|---|---|---|
| Image de base | `node:18-alpine` (fin de vie) | `nginx-unprivileged:1.31.7-alpine3.24-slim` |
| Utilisateur | root | nginx (non root) |
| Taille sur disque | 243 Mo | 29,4 Mo (-88 %) |
| Paquets | 283 | 26 |
| CVE (C / H / M / L) | 13 / 92 / 94 / 17 | 0 / 1 / 0 / 0 |
| Score Docker Scout | E (28 %) | C (56 %) |

## Missions

| Mission | Contenu |
|---|---|
| [Mission 1](MISSION1.md) | Audit de l'image initiale et risques identifiés |
| [Mission 2](MISSION2.md) | Dockerfile sécurisé (multi-stage, non root, image slim) |
| [Mission 3](MISSION3.md) | Comparaison avant / après, publication sur Docker Hub |

## Images publiées

- `anasb92/quiz-docker:initial`
- `anasb92/quiz-docker:secure`

https://hub.docker.com/r/anasb92/quiz-docker

Lancer l'image sécurisée :

```bash
docker run -d --name quiz-secure -p 8091:8080 --memory=128m --cpus=0.5 --read-only --tmpfs /tmp --security-opt no-new-privileges:true --cap-drop ALL anasb92/quiz-docker:secure
```

Puis ouvrir http://localhost:8091.

## Contenu du dépôt

| Fichier | Rôle |
|---|---|
| `Dockerfile.initial` | Dockerfile d'origine |
| `Dockerfile` | Dockerfile sécurisé |
| `.dockerignore` | Fichiers exclus de l'image |
| `audit-initial-*.txt` | Résultats des analyses avant sécurisation |
| `audit-secure-*.txt` | Résultats des analyses après sécurisation |
| `rapport/` | Rapport du TP |
