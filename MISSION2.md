# Mission 2 : sécurisation de l'image et du conteneur

## Principe

Le quiz a besoin de Node pour être compilé, mais pas pour être servi : une fois compilé, ce n'est qu'un dossier `dist` de fichiers statiques. Un build multi-étapes compile avec Node, puis ne livre que `dist` dans un serveur nginx minimal et non root.

## Dockerfile sécurisé

```dockerfile
# ---------- Etape 1 : build (jetee apres la construction) ----------
FROM node:22.23.5-alpine3.24 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---------- Etape 2 : production (la seule image livree) ----------
FROM nginxinc/nginx-unprivileged:1.31.7-alpine3.24-slim AS production
USER root
RUN apk upgrade --no-cache
USER 101
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
```

## `.dockerignore`

```
node_modules
dist
.git
.gitignore
Dockerfile*
.dockerignore
*.txt
*.md
rapport
*.docx
```

## Application des recommandations

| Recommandation | Où | Mise en œuvre |
|---|---|---|
| Image de base minimale | Dockerfile | `nginx-unprivileged` en variante `alpine-slim`, sans Node |
| Pas de root | Dockerfile | Image non root + `USER 101` |
| `.dockerignore` | Fichier | Renforcé (Dockerfiles, rapports, `.git`, `node_modules`) |
| Tags précis | Dockerfile | `node:22.23.5-alpine3.24` et `nginx-unprivileged:1.31.7-alpine3.24-slim` |
| `COPY` plutôt que `ADD` | Dockerfile | Uniquement des `COPY` |
| Limiter ressources et privilèges | `docker run` | `--memory=128m --cpus=0.5 --read-only --tmpfs /tmp --security-opt no-new-privileges:true --cap-drop ALL` |
| Multi-stage build | Dockerfile | Étapes `build` puis `production`, avec `COPY --from=build` |
| Socket Docker non exposé | `docker run` | Aucun montage (`Mounts = []`) |
| Vérifier régulièrement | Outils | Docker Scout avant et après chaque modification |

Autres choix : `npm ci` (installation fidèle au `package-lock.json`) et fichiers du site appartenant à root, lisibles mais non modifiables par nginx.

## Démarche en trois itérations

| Version | Modification | Paquets | C | H | M | L |
|---|---|---|---|---|---|---|
| Initiale | `node:18-alpine`, root, une seule étape | 283 | 13 | 92 | 94 | 17 |
| v1 | Multi-stage + `nginx-unprivileged:alpine` | 88 | 9 | 27 | 6 | 5 |
| v2 | Variante `alpine-slim` | 26 | 1 | 2 | 0 | 0 |
| v3 (finale) | Ajout de `apk upgrade` | 26 | 0 | 1 | 0 | 0 |

## Analyse après la v1

`docker scout cves --only-severity critical,high quiz-docker:secure` a montré que toutes les failles restantes venaient de l'image de base nginx :

| Paquet | Critiques | Élevées | Utile pour servir le quiz ? |
|---|---|---|---|
| curl | 7 | 17 | Non |
| zlib | 1 | 1 | Oui |
| brotli | 1 (activement exploitée) | 0 | Non |
| expat | 0 | 4 | Non |
| libxslt | 0 | 3 (dont 1 activement exploitée) | Non |
| libxml2 | 0 | 1 (pas de correctif) | Non |
| musl | 0 | 1 | Oui |

La variante `alpine-slim` supprime curl et les modules XML : ce qui n'est pas installé ne peut pas être vulnérable. `apk upgrade` corrige ensuite la dernière faille critique (zlib).

Compromis de `apk upgrade` : l'image est plus sûre, mais un peu moins reproductible (les versions dépendent du jour du build). D'où l'intérêt de reconstruire et scanner régulièrement en CI/CD.
