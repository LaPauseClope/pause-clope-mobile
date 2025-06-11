#!/bin/bash

set -e  # Stop on any error

##########################################
#           Rollback Function            #
##########################################

rollback() {
  echo "Une erreur est survenue, démarrage du rollback..."

  # Rétablir l'état initial de la branche test
  git reset --hard HEAD
  git clean -fd
  git checkout "$CURRENT_BRANCH"

  echo "Retour à la branche $CURRENT_BRANCH effectué."
  echo "Suppression du tag $NEW_VERSION s’il a été créé..."

  git tag -d "$NEW_VERSION" 2>/dev/null || true
  git push origin --delete "$NEW_VERSION" 2>/dev/null || true
  gh release delete "$NEW_VERSION" --yes 2>/dev/null || true

  echo "Push du rollback vers $CURRENT_BRANCH..."
  git push origin "$CURRENT_BRANCH" --force

  echo "Rollback terminé. État restauré."
  exit 1
}

trap rollback ERR

CURRENT_BRANCH="test"

##########################################
#         1. Détection des commits       #
##########################################

echo "Détermination de la plage de commits..."
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LATEST_TAG" ]; then
  COMMIT_RANGE="HEAD"
else
  COMMIT_RANGE="$LATEST_TAG..HEAD"
fi

echo "Analyse des messages de commit pour déterminer le type de version..."
BREAKING_CHANGE=$(git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "BREAKING CHANGE|major" || true)
FEATURE=$(git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "^feat" || true)

CURRENT_VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

if [ -n "$BREAKING_CHANGE" ]; then
  echo "Changement majeur détecté"
  MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
elif [ -n "$FEATURE" ]; then
  echo "Nouvelle fonctionnalité détectée"
  MINOR=$((MINOR + 1)); PATCH=0
else
  echo "Changement mineur détecté"
  PATCH=$((PATCH + 1))
fi

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

##########################################
#     2. Nettoyage de tags existants     #
##########################################

echo "Récupération des tags distants..."
git fetch --tags

while git tag -l | grep -q "^$NEW_VERSION$"; do
  echo "Le tag $NEW_VERSION existe déjà. Suppression..."
  git tag -d "$NEW_VERSION" || true
  git push origin --delete "$NEW_VERSION" || true
  gh release delete "$NEW_VERSION" --yes || true
  PATCH=$((PATCH + 1))
  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
done

echo "Nouvelle version déterminée : $NEW_VERSION"

sed -i "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml
git add pubspec.yaml

##########################################
#        3. Génération du Changelog      #
##########################################

echo "Génération du changelog..."
TEMP_CHANGELOG=$(mktemp)
echo "## [$NEW_VERSION] - $(date +%F)" > "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"

echo "### Added" >> "$TEMP_CHANGELOG"
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "^feat" | sed 's/^feat: \(.*\)/- \1/' >> "$TEMP_CHANGELOG" || echo "- Aucun ajout" >> "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"

echo "### Changed" >> "$TEMP_CHANGELOG"
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "^fix|^refactor" | sed 's/^\(fix\|refactor\): \(.*\)/- \1: \2/' >> "$TEMP_CHANGELOG" || echo "- Aucun changement" >> "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"

if [ -f CHANGELOG.md ]; then
  echo "Ancien changelog détecté, fusion..."
  cat CHANGELOG.md >> "$TEMP_CHANGELOG"
fi

mv "$TEMP_CHANGELOG" CHANGELOG.md
git add CHANGELOG.md

##########################################
#        4. Commit, tag & push           #
##########################################

echo "Création du tag $NEW_VERSION"
git commit -m "chore(release): $NEW_VERSION"
exit 42  # 💥 erreur simulée ici !
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

echo "Poussage vers origin/$CURRENT_BRANCH"
git push origin "$CURRENT_BRANCH"
git push origin "$NEW_VERSION"

##########################################
#       5. Release GitHub (via gh)       #
##########################################

echo "Création de la release GitHub..."
gh release create "$NEW_VERSION" --title "Release $NEW_VERSION" --notes-file CHANGELOG.md

echo "Publication terminée avec succès !"
