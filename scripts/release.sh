#!/bin/bash

set -e

rollback() {
  echo "ROLLBACK TRIGGERED"

  git reset --hard HEAD~1
  git clean -fd
  git checkout "$CURRENT_BRANCH"

  echo "Suppression du tag $NEW_VERSION..."
  git tag -d "$NEW_VERSION" 2>/dev/null || true
  git push origin --delete "$NEW_VERSION" 2>/dev/null || true
  gh release delete "$NEW_VERSION" --yes 2>/dev/null || true

  echo "Push du rollback vers $CURRENT_BRANCH..."
  git push origin "$CURRENT_BRANCH" --force

  echo "Rollback terminé."
  exit 1
}

trap rollback ERR
CURRENT_BRANCH="release"

echo "🔍 Détection de la version précédente..."
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
COMMIT_RANGE="${LATEST_TAG}..HEAD"

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
echo "Nouvelle version : $NEW_VERSION"

git fetch --tags

while git tag -l | grep -q "^$NEW_VERSION$"; do
  echo "Tag $NEW_VERSION existe déjà. Suppression..."
  git tag -d "$NEW_VERSION" || true
  git push origin --delete "$NEW_VERSION" || true
  gh release delete "$NEW_VERSION" --yes || true
  PATCH=$((PATCH + 1))
  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
done

sed -i "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml
git add pubspec.yaml

TEMP_CHANGELOG=$(mktemp)
echo "## [$NEW_VERSION] - $(date +%F)" > "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"
echo "### Added" >> "$TEMP_CHANGELOG"
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "^feat" | sed 's/^feat: \(.*\)/- \1/' >> "$TEMP_CHANGELOG" || echo "- Aucun ajout" >> "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"
echo "### Changed" >> "$TEMP_CHANGELOG"
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -E "^fix|^refactor" | sed 's/^\(fix\|refactor\): \(.*\)/- \1: \2/' >> "$TEMP_CHANGELOG" || echo "- Aucun changement" >> "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"
[ -f CHANGELOG.md ] && cat CHANGELOG.md >> "$TEMP_CHANGELOG"
mv "$TEMP_CHANGELOG" CHANGELOG.md
git add CHANGELOG.md

git commit -m "chore(release): $NEW_VERSION"
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

git push origin "$CURRENT_BRANCH"
git push origin "$NEW_VERSION"

gh release create "$NEW_VERSION" --title "Release $NEW_VERSION" --notes-file CHANGELOG.md

echo "Release $NEW_VERSION publiée avec succès !"
