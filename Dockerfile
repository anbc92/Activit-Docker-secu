# ---------- Etape 1 : build (jetee apres la construction) ----------
FROM node:22.23.5-alpine3.24 AS build
WORKDIR /app

# npm ci installe exactement les versions figees dans package-lock.json
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---------- Etape 2 : production (la seule image livree) ----------
FROM nginxinc/nginx-unprivileged:1.31.7-alpine3.24-slim AS production

# Applique les correctifs de securite disponibles, puis repasse en non-root
USER root
RUN apk upgrade --no-cache
USER 101

# On ne recupere que le resultat compile de l'etape build
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080
