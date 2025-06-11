#!/bin/bash
set -e

BRANCH="release"

echo "Rollback automatique de la branche '$BRANCH'..."

# Récupération des tags triés par date
git fetch origin --tags
TAGS=($(git tag --sort=-creatordate))

if [ "${#TAGS[@]}" -lt 1 ]; then
  echo "Aucun tag disponible pour rollback."
  exit 1
fi

LAST_TAG="${TAGS[0]}"
echo "Revenir sur le dernier tag valide : $LAST_TAG"

# Reset de la branche release
git checkout "$BRANCH"
git reset --hard "$LAST_TAG"

# Push forcé
git push origin "$BRANCH" --force

echo "Rollback terminé. '$BRANCH' pointe maintenant sur $LAST_TAG"