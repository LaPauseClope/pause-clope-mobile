#!/bin/bash
set -e

echo "✅ Propagation auto vers main"

git fetch origin
git checkout main
git pull origin main

git merge origin/release --strategy=ours -m "chore: auto-merge release into main"
git push origin main

echo "🎉 Branche main mise à jour depuis release"
