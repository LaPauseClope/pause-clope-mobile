#!/bin/bash

set -e

BRANCH="release"

echo "Rollback automatique de la branche '$BRANCH' à la version précédente..."

# Récupère tous les tags (classés par ordre chronologique)
git fetch origin --tags
TAGS=($(git tag --sort=-creatordate))

if [ "${#TAGS[@]}" -lt 2 ]; then
  echo "Pas assez de tags pour faire un rollback."
  exit 1
fi

# Le dernier tag est la version actuelle, on veut celle juste avant
PREVIOUS_TAG="${TAGS[1]}"

echo "Dernier tag précédent : $PREVIOUS_TAG"

# Basculer sur la branche de release et reset
git checkout "$BRANCH"
git reset --hard "$PREVIOUS_TAG"

# Push forcé vers la branche release
git push origin "$BRANCH" --force

echo "Rollback terminé. La branche '$BRANCH' pointe maintenant sur $PREVIOUS_TAG"