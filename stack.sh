#!/usr/bin/env bash
# Gestion de la stack docker locale (postgres auth/user + mailpit).
# Usage : ./stack <commande> [service]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# Projet cible : ../matcha_microservices par defaut, surchargeable via MATCHA_DIR
ROOT_DIR="$(cd "${MATCHA_DIR:-$SCRIPT_DIR/../matcha_microservices}" && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yaml"
ENV_FILE="$ROOT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Fichier .env introuvable ($ENV_FILE). Copie .env.exemple en .env et remplis-le." >&2
  exit 1
fi

compose() {
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --project-directory "$ROOT_DIR" "$@"
}

usage() {
  cat <<EOF
Usage : ./stack <commande> [service]

  up [service]       lance la stack (ou un service) et attend qu'elle soit healthy
  down               arrete et supprime les conteneurs (les donnees sont gardees)
  stop [service]     arrete sans supprimer
  restart [service]  redemarre
  ps                 etat des conteneurs
  logs [service]     suit les logs
  clean              down + suppression des volumes (EFFACE les bases)
EOF
}

cmd="${1:-}"
shift || true

case "$cmd" in
  up)      compose up -d --wait "$@" && compose ps ;;
  down)    compose down ;;
  stop)    compose stop "$@" ;;
  restart) compose restart "$@" ;;
  ps)      compose ps ;;
  logs)    compose logs -f "$@" ;;
  clean)
    read -r -p "Supprimer les volumes (toutes les donnees des bases) ? [y/N] " ok
    [[ "$ok" == "y" || "$ok" == "Y" ]] && compose down -v || echo "Annule."
    ;;
  ""|-h|--help|help) usage ;;
  *) echo "Commande inconnue : $cmd" >&2; usage; exit 1 ;;
esac
