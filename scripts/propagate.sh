#!/bin/bash
set -e

echo "✅ Propagation auto vers backupmain"

git fetch origin
git checkout backupmain
git pull origin backupmain

git merge origin/release --strategy=ours -m "chore: auto-merge release into backupmain"
git push origin backupmain

echo "🎉 Branche backupmain mise à jour depuis release"
