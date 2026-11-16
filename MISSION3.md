# Mission 3 : comparaison avant / après sécurisation

## Commandes utilisées

| Action | Commande |
|---|---|
| Construire l'image sécurisée | `docker build -t quiz-docker:secure .` |
| Lancer le conteneur sécurisé | `docker run -d --name quiz-secure -p 8091:8080 --memory=128m --cpus=0.5 --read-only --tmpfs /tmp --security-opt no-new-privileges:true --cap-drop ALL quiz-docker:secure` |
| Analyser les vulnérabilités | `docker scout quickview quiz-docker:secure` |
| Renommer pour Docker Hub | `docker tag quiz-docker:secure anasb92/quiz-docker:secure` |
| Publier | `docker push anasb92/quiz-docker:secure` |

## Vérifications

| Test | Commande | Résultat |
|---|---|---|
| Application | http://localhost:8091 | Quiz fonctionnel |
| Utilisateur | `docker exec quiz-secure whoami` | `nginx` (non root) |
| Lecture seule | `docker exec quiz-secure touch /usr/share/nginx/html/pirate.html` | `Read-only file system` |
| Socket Docker | `docker inspect -f '{{json .Mounts}}' quiz-secure` | `[]` |
| Mémoire | `docker stats quiz-secure --no-stream` | 7,3 Mio / 128 Mio |

## Tableau comparatif

| Critère | Image initiale | Image sécurisée |
|---|---|---|
| Image de base | `node:18-alpine` (fin de vie) | `nginx-unprivileged:1.31.7-alpine3.24-slim` |
| Tag précis | Non | Oui |
| Utilisateur | root | nginx (UID 101) |
| Outils de développement | Node, npm, Yarn, Vite, node_modules | Aucun |
| .dockerignore | Minimal | Renforcé |
| Multi-stage build | Non | Oui |
| Limitation des ressources | Non | 128 Mo, 0,5 CPU |
| Restriction des privilèges | Non | Lecture seule, cap-drop ALL, no-new-privileges |
| Accès au socket Docker | Non | Non |
| Taille sur disque | 243 Mo | 29,4 Mo (-88 %) |
| Taille compressée | 60,2 Mo | 8,3 Mo (-86 %) |
| Paquets | 283 | 26 |
| CVE critiques | 13 | 0 |
| CVE élevées | 92 | 1 |
| CVE moyennes | 94 | 0 |
| CVE faibles | 17 | 0 |
| Failles activement exploitées | 2 | 0 |
| Score Docker Scout | E (28 %) | C (56 %) |

## Évolution des CVE

| Gravité | Initiale | v1 multi-stage | v2 alpine-slim | v3 apk upgrade |
|---|---|---|---|---|
| Critiques | 13 | 9 | 1 | 0 |
| Élevées | 92 | 27 | 2 | 1 |
| Moyennes | 94 | 6 | 0 | 0 |
| Faibles | 17 | 5 | 0 | 0 |
| Total | 216 | 47 | 3 | 1 |

## Questions d'analyse

| Question | Réponse |
|---|---|
| Améliorations les plus significatives ? | Le multi-stage (retire Node et les outils de build : 216 → 47 CVE) et l'image slim (retire curl et les modules XML : 47 → 3 CVE). |
| La taille a-t-elle diminué ? Pourquoi ? | Oui, 243 → 29,4 Mo : l'image ne contient plus l'environnement de compilation, seulement nginx et le dossier dist. |
| Image totalement sécurisée ? | Non : 1 CVE élevée sans correctif disponible, pas de SBOM ni de provenance signées, et de nouvelles failles apparaîtront. |

| Dans le Dockerfile | Au lancement (docker run) |
|---|---|
| Image de base minimale | Limite mémoire et CPU |
| Utilisateur non root | Lecture seule |
| Tags précis | Retrait des capacités Linux |
| COPY plutôt que ADD | no-new-privileges |
| Multi-stage | Pas de socket Docker monté |
| .dockerignore | |

## Mesures complémentaires pour la production

| Mesure | Intérêt |
|---|---|
| Scan automatique en CI/CD | Bloquer le déploiement si une faille critique apparaît |
| SBOM et provenance signées | Prouver le contenu et l'origine de l'image |
| Image verrouillée par digest | Garantir que l'image ne change jamais |
| --pids-limit et HEALTHCHECK | Contrer les fork bombs, détecter les pannes |
| Reverse proxy HTTPS | Chiffrer le trafic |
| Docker Hardened Image | Base encore plus réduite et maintenue (Mission 4) |

## Liens

- Images publiées : https://hub.docker.com/r/anasb92/quiz-docker (tags `initial` et `secure`)
