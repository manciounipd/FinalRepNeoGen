#!/usr/bin/env bash
set -e

REPO_DIR="$HOME/Script/FixNeogen"

# Vai nella directory del progetto
cd "$REPO_DIR" || {
  echo "Errore: directory $REPO_DIR non trovata."
  exit 1
}

echo "== Stato attuale =="
git status --short || exit 1

# Messaggio di commit: argomento oppure data/ora
COMMIT_MSG="$1"
if [ -z "$COMMIT_MSG" ]; then
  COMMIT_MSG="auto: $(date +"%Y-%m-%d %H:%M")"
fi

echo "== Aggiungo i file =="
git add .

# Controllo se ci sono cambiamenti da commitare
if git diff --cached --quiet; then
  echo "Niente da commitare, esco."
  exit 0
fi

echo "== Faccio il commit =="
git commit -m "$COMMIT_MSG"

echo "== Push su origin main =="
git push origin main

echo "Fatto ✅"