# Exercice 2 : intégrer le Dockerfile sécurisé dans Docker Compose

Le fichier [`docker-compose.yml`](docker-compose.yml) construit l'image à partir du [`Dockerfile`](Dockerfile) sécurisé et lance l'application avec les mêmes protections que le `docker run` du TP de sécurisation.

## Exigences et mise en œuvre

| Exigence | Dans `docker-compose.yml` |
|---|---|
| Service nommé `quiz-docker` | `services: quiz-docker:` |
| Construction automatique depuis le Dockerfile | `build: context: .` et `dockerfile: Dockerfile` |
| Image nommée `quiz-docker:secure` | `image: quiz-docker:secure` |
| Port 8082 sur l'hôte vers le port interne du serveur | `"8082:8080"` (nginx non root écoute sur 8080) |
| Redémarrage automatique adapté | `restart: unless-stopped` : relance en cas de panne ou de redémarrage de Docker, mais respecte un arrêt volontaire |
| Sécurisation du conteneur | `user: "101"`, `read_only: true`, `tmpfs: /tmp`, `cap_drop: ALL`, `no-new-privileges:true` |
| Limitation des ressources | `mem_limit: 128m`, `cpus: 0.5`, `pids_limit: 50` |

## Correspondance avec le `docker run` sécurisé

| `docker run` | `docker-compose.yml` |
|---|---|
| `docker build -t quiz-docker:secure .` | `build:` + `image:` |
| `--name quiz-docker` | `container_name: quiz-docker` |
| `-p 8082:8080` | `ports: - "8082:8080"` |
| `--memory=128m` | `mem_limit: 128m` |
| `--cpus=0.5` | `cpus: 0.5` |
| `--read-only` | `read_only: true` |
| `--tmpfs /tmp` | `tmpfs: - /tmp` |
| `--security-opt no-new-privileges:true` | `security_opt: - no-new-privileges:true` |
| `--cap-drop ALL` | `cap_drop: - ALL` |
| `--pids-limit 50` | `pids_limit: 50` |

## Cycle de vie avec Docker Compose

| Commande | Rôle |
|---|---|
| `docker compose up -d --build` | Construire l'image puis créer et démarrer le conteneur |
| `docker compose ps` | Voir l'état du service |
| `docker compose logs -f` | Suivre les logs en direct |
| `docker compose stop` | Arrêter sans supprimer |
| `docker compose start` | Redémarrer un service arrêté |
| `docker compose restart` | Arrêter puis relancer |
| `docker compose config` | Vérifier la configuration finale |
| `docker compose down` | Arrêter et supprimer le conteneur et le réseau |

## Vérifications

| Test | Commande | Résultat attendu |
|---|---|---|
| Application | http://localhost:8082 | Quiz affiché |
| Utilisateur | `docker compose exec quiz-docker whoami` | `nginx` |
| Lecture seule | `docker compose exec quiz-docker touch /usr/share/nginx/html/pirate.html` | `Read-only file system` |
| Limites | `docker stats quiz-docker --no-stream` | Limite mémoire de 128 Mio |
