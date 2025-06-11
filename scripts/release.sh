#!/bin/bash
set -e

rollback() {
  echo "Une erreur est survenue, rollback en cours..."

  git reset --hard
  git clean -fd
  git checkout "$CURRENT_BRANCH"

  echo "Suppression du tag $NEW_VERSION localement..."
  git tag -d "$NEW_VERSION" 2>/dev/null || true

  echo "Suppression du tag distant..."
  git push origin --delete "$NEW_VERSION" 2>/dev/null || true

  echo "Suppression de la release GitHub..."
  gh release delete "$NEW_VERSION" --yes 2>/dev/null || true

  git fetch origin --tags --prune --force

  echo "Rollback terminé."
  exit 1
}

trap rollback ERR

CURRENT_BRANCH="main"
RELEASE_BRANCH="release"

echo "Préparation de la branche $RELEASE_BRANCH depuis $CURRENT_BRANCH..."
git fetch origin
git checkout -B "$RELEASE_BRANCH" "origin/$RELEASE_BRANCH" || git checkout -b "$RELEASE_BRANCH"
git reset --hard "origin/$CURRENT_BRANCH"
git clean -fd

LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
COMMIT_RANGE="${LATEST_TAG}..HEAD"

echo "Détection du type de version..."
BREAKING=$(git log $COMMIT_RANGE --pretty=format:"%s" | grep -Ei "BREAKING CHANGE|major" || true)
FEATURE=$(git log $COMMIT_RANGE --pretty=format:"%s" | grep -Ei "^feat" || true)

CURRENT_VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

if [ -n "$BREAKING" ]; then
  MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
elif [ -n "$FEATURE" ]; then
  MINOR=$((MINOR + 1)); PATCH=0
else
  PATCH=$((PATCH + 1))
fi

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

git fetch origin --tags
while git tag -l | grep -q "^$NEW_VERSION$"; do
  echo "Le tag $NEW_VERSION existe déjà, incrementation..."
  PATCH=$((PATCH + 1))
  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
done

echo "Nouvelle version déterminée : $NEW_VERSION"
sed -i "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml
git add pubspec.yaml

echo "Génération du changelog..."
TEMP=$(mktemp)
echo "## [$NEW_VERSION] - $(date +%F)" > "$TEMP"
echo "" >> "$TEMP"

echo "### Added" >> "$TEMP"
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep "^feat" | sed 's/^feat: \(.*\)/- \1/' >> "$TEMP" || echo "- Aucun ajout" >> "$TEMP"
echo "" >> "$TEMP"

echo "### Changed" >> "$TEMP"
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "^fix|^refactor" | sed 's/^\(fix\|refactor\): \(.*\)/- \1: \2/' >> "$TEMP" || echo "- Aucun changement" >> "$TEMP"
echo "" >> "$TEMP"

if [ -f CHANGELOG.md ]; then
  cat CHANGELOG.md >> "$TEMP"
fi

mv "$TEMP" CHANGELOG.md
git add CHANGELOG.md

echo "Commit, tag et release..."
git commit -m "chore(release): $NEW_VERSION"
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

git push origin "$RELEASE_BRANCH" --force || rollback
git push origin "$NEW_VERSION" || rollback

gh release create "$NEW_VERSION" --title "Release $NEW_VERSION" --notes-file CHANGELOG.md

# echo "Release $NEW_VERSION publiée avec succès !"

echo "Simulation d'une erreur après création du tag..."
exit 42