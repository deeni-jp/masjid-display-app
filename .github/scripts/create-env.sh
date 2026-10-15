#!/usr/bin/env bash
# Creates .env for CI builds. .env holds the masjid's public configuration
# (name, Firebase client config, ...; see .env.example). In order:
#   1. a committed .env (e.g. in a masjid's own private copy of the repo),
#   2. the ENV_FILE repository variable (the whole .env file as its value),
#   3. .env.example (template defaults: enough for analyze and tests).
set -euo pipefail

if [ -f .env ]; then
  echo "Using the committed .env"
elif [ -n "${ENV_FILE:-}" ]; then
  printf '%s\n' "$ENV_FILE" > .env
  echo "Created .env from the ENV_FILE variable"
else
  cp .env.example .env
  echo "Created .env from .env.example (template defaults)"
fi
