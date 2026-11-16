# Mission 1 : audit de l'image initiale

Image auditée : `quiz-docker:initial`, construite avec le Dockerfile de l'exercice 2 (voir `Dockerfile.initial`).

## Commandes utilisées

| Objectif | Commande |
|---|---|
| Construire l'image | `docker build -t quiz-docker:initial .` |
| Lancer et tester | `docker run -d --name quiz-initial -p 8090:3000 quiz-docker:initial` |
| Image de base | `docker exec quiz-initial cat /etc/os-release` et `docker exec quiz-initial node --version` |
| Utilisateur | `docker exec quiz-initial whoami` et `docker exec quiz-initial ps` |
| Taille | `docker image ls quiz-docker` |
| Couches | `docker image history quiz-docker:initial` |
| Vulnérabilités | `docker scout quickview quiz-docker:initial` et `docker scout cves quiz-docker:initial` |

Les résultats bruts sont conservés dans les fichiers `audit-initial-*.txt`.

## Résultats

| Critère | Constat |
|---|---|
| Fonctionnement | Quiz fonctionnel sur http://localhost:8090 |
| Image de base | `node:18-alpine` (Alpine 3.21.3, Node 18.20.8) |
| Utilisateur | root (PID 1 : `serve` exécuté en root) |
| Taille sur disque | 243 Mo |
| Taille compressée | 60,2 Mo |
| Paquets | 283 |
| CVE critiques / élevées / moyennes / faibles | 13 / 92 / 94 / 17 |
| Score Docker Scout | E (28 %), 2 politiques sur 7 |

## Analyse des couches

| Couche | Taille | Contenu |
|---|---|---|
| Alpine (base) | 8,5 Mo | Système de base |
| Installation de Node.js | 122 Mo | Node 18 et utilisateur `node` (inutilisé) |
| Installation de Yarn | 5,5 Mo | Gestionnaire de paquets inutile en production |
| `RUN npm install` | 29,9 Mo | `node_modules` (Vite, esbuild, Rollup) |
| `COPY . .` | 283 Ko | Code source du quiz |
| `RUN npm install -g serve && npm run build` | 16,4 Mo | `serve` et dossier `dist` |

Le code de l'application pèse moins de 1 Mo : plus de 99 % de l'image ne sert pas à l'exécuter.

## Tableau de l'état initial et des risques

| Critère | État initial | Risque identifié |
|---|---|---|
| Image de base | `node:18-alpine` | Node 18 en fin de vie, image figée depuis 19 mois |
| Tag | `18-alpine` (imprécis) | Contenu pouvant changer d'un build à l'autre |
| Utilisateur | root | Une faille de l'application donne les droits root dans le conteneur |
| Outils de développement | npm, Yarn, Vite, `node_modules` | Logiciels inutiles en production, donc failles inutiles |
| Multi-stage build | Non | Build et exécution dans la même image |
| `.dockerignore` | Minimal | Fichiers parasites possibles dans l'image |
| Limites de ressources | Aucune | Le conteneur peut saturer l'hôte |
| Restrictions de privilèges | Aucune | Capacités Linux par défaut, écriture partout |
| Socket Docker | Non exposé | Aucun risque (à conserver) |
| CVE | 216, dont 105 critiques ou élevées | Failles connues, toutes corrigeables |
| Failles activement exploitées (CISA KEV) | 2 | Risque d'exploitation immédiat |

## Questions

| Question | Réponse |
|---|---|
| L'image est-elle adaptée à la production ? | Non : exécution en root, Node 18 en fin de vie, 105 CVE critiques ou élevées, outils de développement embarqués. |
| Quels composants sont réellement nécessaires ? | Uniquement le dossier `dist` compilé et un serveur web. Node, npm, Yarn, Vite et `node_modules` ne servent qu'à la compilation. |
| Quels risques de sécurité ? | Root, image de base en fin de vie, CVE connues dont 2 activement exploitées, surface d'attaque élevée, aucune limite de ressources ni de privilèges, tag imprécis. |
| Améliorations prioritaires ? | 1. Ne plus tourner en root. 2. Multi-stage pour retirer Node et les outils. 3. Images maintenues avec tags précis. 4. Limiter ressources et privilèges au lancement. |

Remarque : Scout valide la politique « No outdated base images » alors que Node 18 est en fin de vie, car le tag `18-alpine` n'est simplement plus mis à jour. Un outil d'analyse ne remplace pas l'analyse humaine.
