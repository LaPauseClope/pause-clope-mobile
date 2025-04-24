#!/bin/bash

# Script de publication unifiée

# 1. Incrémenter la version en SemVer
echo "Incrémentation de la version SemVer..."
# Extraction de la version actuelle depuis pubspec.yaml
CURRENT_VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
# Incrémenter le patch (ex: 1.0.0 -> 1.0.1)
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
# Mettre à jour pubspec.yaml avec la nouvelle version
sed -i "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml
git add pubspec.yaml

# 2. Générer un changelog propre
echo "Génération du changelog..."
# Création ou ajout au CHANGELOG.md (simplifié ici)
echo "## [$NEW_VERSION] - $(date +%F)" > CHANGELOG.md
echo "### Changed" >> CHANGELOG.md
echo "- Mise à jour vers la version $NEW_VERSION" >> CHANGELOG.md
echo "" >> CHANGELOG.md
git add CHANGELOG.md

# 3. Créer un tag Git
echo "Création du tag Git pour la version v$NEW_VERSION..."
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

# 4. Pousser le tag et les commits
echo "Poussage des commits et du tag..."
git commit -m "chore(release): v$NEW_VERSION"
git push origin main
git push origin "v$NEW_VERSION"

# 5. Créer une release publique (GitHub)
echo "Création de la release publique..."
gh release create "v$NEW_VERSION" --title "Release v$NEW_VERSION" --notes-file CHANGELOG.md

echo "Publication terminée avec succès !"
