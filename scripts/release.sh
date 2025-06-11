#!/bin/bash

set -e

##########################################
#           Rollback Function            #
##########################################
rollback() {
  echo "Une erreur est survenue, rollback en cours..."

  git reset --hard
  git clean -fd
  git checkout "$CURRENT_BRANCH"

  echo "Retour à la branche $CURRENT_BRANCH"
  echo "🗑 Suppression du tag $NEW_VERSION localement (s’il existe)..."
  git tag -d "$NEW_VERSION" 2>/dev/null || true

  echo "Suppression du tag distant (s’il existe)..."
  git push --delete origin "$NEW_VERSION" 2>/dev/null || true

  echo "Suppression de la release GitHub si présente..."
  gh release delete "$NEW_VERSION" --yes 2>/dev/null || true

  echo "Refetch des tags propres depuis origin..."
  git fetch origin --tags --prune --force

  echo "Rollback terminé. État restauré."
  exit 1
}

trap rollback ERR

##########################################
#        Variables de configuration      #
##########################################
CURRENT_BRANCH="backupmain"  # À remplacer par "main" en prod
RELEASE_BRANCH="release"

##########################################
#         1. Préparation des branches    #
##########################################
echo "Synchronisation avec $CURRENT_BRANCH..."
git fetch origin
git checkout -B "$RELEASE_BRANCH" "origin/$RELEASE_BRANCH" || git checkout -b "$RELEASE_BRANCH"
git reset --hard "origin/$CURRENT_BRANCH"
git clean -fd

##########################################
#         2. Détection des commits       #
##########################################
echo "Détermination de la plage de commits..."
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
COMMIT_RANGE="${LATEST_TAG}..HEAD"

echo "Analyse des messages de commit..."
BREAKING_CHANGE=$(git log $COMMIT_RANGE --pretty=format:"%s" | grep -E "BREAKING CHANGE|major" || true)
FEATURE=$(git log $COMMIT_RANGE --pretty=format:"%s" | grep -E "^feat" || true)

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
#     3. Nettoyage de tags existants     #
##########################################
echo "Vérification des tags existants..."
git fetch origin --tags
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
#        4. Génération du changelog      #
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
  echo "Fusion avec changelog existant..."
  cat CHANGELOG.md >> "$TEMP_CHANGELOG"
fi

mv "$TEMP_CHANGELOG" CHANGELOG.md
git add CHANGELOG.md

##########################################
#       5. Commit, tag, push, release    #
##########################################
echo "Création du commit et du tag $NEW_VERSION..."
git commit -m "chore(release): $NEW_VERSION"
# exit 42
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

echo "Push vers origin/$RELEASE_BRANCH et le tag..."
git push origin "$RELEASE_BRANCH" --force || rollback
git push origin "$NEW_VERSION" || rollback

echo "Création de la release GitHub..."
gh release create "$NEW_VERSION" --title "Release $NEW_VERSION" --notes-file CHANGELOG.md

echo "Publication terminée avec succès."
