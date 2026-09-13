#!/bin/bash
set -e
cd ~/Desktop/Fiori-Apps

if [ ! -d "apps/master-data-apps" ]; then
  echo "apps/master-data-apps not found — nothing to flatten. Checking current apps/ layout:"
  ls -1 apps/
  exit 0
fi

echo "=== Moving 12 master folders up into apps/ ==="
for d in apps/master-data-apps/*/; do
  slug=$(basename "$d")
  echo "  apps/master-data-apps/$slug -> apps/$slug"
  mv "apps/master-data-apps/$slug" "apps/$slug"
done

rmdir apps/master-data-apps

echo "=== git add (scoped to apps/ and old master-data-apps/ path only) ==="
git add -A -- apps master-data-apps
git status --short

git commit -m "Flatten master-data-apps into apps/ so all 45 apps sit side by side"
git push origin main

echo "=== DONE. apps/ folder count now: ==="
find apps -mindepth 1 -maxdepth 1 -type d | wc -l
