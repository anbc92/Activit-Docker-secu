# Mission 4 : Docker Hardened Images (DHI)

Atelier réalisé : [Migrating a Node app to Docker Hardened Images](https://docs.docker.com/guides/lab-dhi-node/), lancé avec :

```bash
docker compose -p labspace -f oci://dockersamples/labspace-dhi-node up -d
```

## Qu'est-ce qu'une Docker Hardened Image ?

| Caractéristique | Explication |
|---|---|
| Distroless | L'image runtime ne contient ni shell ni gestionnaire de paquets, seulement ce qu'il faut pour exécuter l'application |
| Deux variantes | `-dev` (shell, npm) pour l'étape de build ; runtime (minimale) pour la production |
| Non root par défaut | Aucune configuration `USER` à ajouter |
| Mises à jour continues | Images reconstruites dès qu'un correctif est publié |
| Attestations signées | SBOM (CycloneDX, SPDX), provenance SLSA, VEX, rapports Scout |
| Registry | Version gratuite sur `dhi.io` (identifiants Docker Hub) |

## Déroulé du lab

| Module | Ce qui a été fait |
|---|---|
| 1. Introduction | Présentation des DHI |
| 2. Setup | Organisation `anasb92`, tier gratuit, connexion à `dhi.io` |
| 3. Analyse de départ | Build de l'app Node sur `node:24-trixie-slim` (`demo-node-doi:v1`), test (« Hello World! »), scan Scout |
| 4. Migration | Dockerfile multi-stage `dhi.io/node:24-debian13-dev` → `dhi.io/node:24-debian13`, test, scan, comparaison |
| 5. Attestations | Liste des attestations, SBOM, VEX (FIPS/STIG : réservés au tier payant) |

## Dockerfile migré vers DHI

```dockerfile
FROM dhi.io/node:24-debian13-dev AS build
ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm i --omit=dev

FROM dhi.io/node:24-debian13 AS production
ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY src ./src
COPY package*.json ./
EXPOSE 3000
CMD ["node", "src/app.js"]
```

## Résultats du lab (app Node de démonstration)

| Critère | Image classique `node:24-trixie-slim` | Image DHI `dhi.io/node:24-debian13` |
|---|---|---|
| Taille compressée | 84 Mo | 43 Mo (-41 Mo) |
| Paquets | 320 | 80 (-240) |
| CVE (C / H / M / L) | 1 / 9 / 17 / 29 | 1 / 1 / 4 / 9 |
| CVE de l'image de base | 0 / 8 / 13 / 28 | Aucune remontée |
| Shell dans le conteneur | Oui | **Non** (`exec: "sh": executable file not found`) |
| Application | Hello World! | Hello World! |

Les CVE restantes de l'image DHI ne viennent pas de la base : elles viennent des dépendances npm de l'application (`proxy-addr` 2.0.7 : 1 critique, `body-parser` 2.2.2 : 1 élevée). Elles se corrigent en mettant à jour ces dépendances dans `package.json`, pas en changeant d'image.

## Comparaison avec mon image sécurisée (quiz-docker:secure)

| Critère | Mon image sécurisée | Image DHI |
|---|---|---|
| Base de production | `nginx-unprivileged:1.31.7-alpine3.24-slim` | `dhi.io/node:24-debian13` |
| Taille compressée | 9,3 Mo | 43 Mo (contient le runtime Node) |
| Paquets | 26 | 80 |
| CVE de l'image de base | 1 élevée | Aucune remontée |
| Non root | Oui (configuré à la main : image unprivileged + `USER 101`) | Oui, par défaut |
| Shell et gestionnaire de paquets | Oui (`sh`, `apk`) | Non (distroless) |
| Correctifs de sécurité | `apk upgrade` à chaque build (moins reproductible) | Fournis et maintenus par Docker |
| SBOM / provenance / VEX | Non | Oui, signés |
| Effort de durcissement | Élevé (audit, 3 itérations) | Faible (changer le `FROM`) |

## Analyse

- **Ce que DHI apporte en plus** : l'absence de shell (un attaquant ne peut pas lancer de commandes dans le conteneur), des correctifs maintenus par Docker sans `apk upgrade`, et les attestations signées qui manquaient à mon image (risque résiduel identifié en Mission 3).
- **Ce que mon image fait aussi bien** : pour un site statique, nginx slim reste beaucoup plus léger (9 Mo contre 43 Mo), car il n'embarque pas Node.
- **La leçon principale** : les CVE restantes de l'image DHI venaient du code applicatif (dépendances npm). Une image de base durcie ne remplace pas la mise à jour des dépendances de l'application.

## Recommandation pour la production

Utiliser une DHI comme base de production : une DHI nginx pour le quiz (fichiers statiques), une DHI node pour une application serveur. On garde le multi-stage et les options `docker run` de la Mission 2, on supprime le `apk upgrade` (correctifs gérés par Docker), et on récupère SBOM, provenance et VEX signés. La version gratuite (`dhi.io`) suffit ; le tier payant ajoute les variantes FIPS/STIG pour les environnements réglementés.
