#!/bin/bash

set -e  # Stop script on any error

##########################################
#        Variables de configuration      #
##########################################

UPSTREAM_BRANCH="backupmain"
CURRENT_BRANCH="release"

##########################################
#           Synchronisation base         #
##########################################

echo "Synchronisation avec $UPSTREAM_BRANCH..."

git checkout "$CURRENT_BRANCH"
git reset --hard
git clean -fd
git fetch origin "$UPSTREAM_BRANCH"

# Rebase avec résolution automatique des conflits (stratégie ours)
if ! git rebase -X ours origin/$UPSTREAM_BRANCH; then
  echo "Échec du rebase automatique même avec stratégie ours. Abandon du script."
  git rebase --abort || true
  exit 1
fi

##########################################
#         Détermination de version       #
##########################################

echo "Détermination de la plage de commits..."
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
COMMIT_RANGE="${LATEST_TAG}..HEAD"

echo "Analyse des messages de commit pour déterminer le type de version..."
BREAKING_CHANGE=$(git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "BREAKING CHANGE|major" || true)
FEATURE=$(git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "^feat" || true)

CURRENT_VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

if [ -n "$BREAKING_CHANGE" ]; then
  MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
elif [ -n "$FEATURE" ]; then
  MINOR=$((MINOR + 1)); PATCH=0
else
  PATCH=$((PATCH + 1))
fi

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

##########################################
#         Nettoyage de tags existants    #
##########################################

echo "Vérification des tags existants..."
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
#          Génération changelog          #
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
#      Commit, tag & release GitHub      #
##########################################

echo "Création du commit et du tag $NEW_VERSION..."
git commit -m "chore(release): $NEW_VERSION"
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

echo "Push vers origin/$CURRENT_BRANCH et le tag..."
git push origin "$CURRENT_BRANCH"
git push origin "$NEW_VERSION"

echo "Création de la release GitHub..."
gh release create "$NEW_VERSION" --title "Release $NEW_VERSION" --notes-file CHANGELOG.md

echo "Publication terminée avec succès."
