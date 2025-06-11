#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./rollback.sh <tag-version>"
  exit 1
fi

TAG="$1"
BRANCH="release"

echo "Rollback de $BRANCH à $TAG"

git fetch --tags
git checkout "$BRANCH"
git reset --hard "$TAG"
git push origin "$BRANCH" --force

ROLLBACK_TAG="${TAG}-rollback-$(date +%s)"
git tag -a "$ROLLBACK_TAG" -m "Rollback to $TAG"
git push origin "$ROLLBACK_TAG"

echo "Rollback vers $TAG terminé avec tag $ROLLBACK_TAG"
