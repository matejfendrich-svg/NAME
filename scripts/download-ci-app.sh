#!/bin/bash
# Stáhne hotový NAME.app z posledního zeleného CI buildu (bez nutnosti instalovat Xcode).
# Vyžaduje přihlášený `gh` (gh auth login). Použití: ./scripts/download-ci-app.sh
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="matejfendrich-svg/NAME"
BRANCH="vibe/name-app-aaf646"

if ! command -v gh >/dev/null 2>&1; then
    echo "Chyba: není nainstalovaný GitHub CLI (gh). Nainstaluj ho: brew install gh"
    exit 1
fi

echo "==> Hledám poslední CI build…"
RUN_ID=$(gh run list --repo "$REPO" --branch "$BRANCH" --workflow Build --limit 1 --json databaseId,conclusion --jq '.[] | select(.conclusion=="success") | .databaseId' | head -1)
if [ -z "$RUN_ID" ]; then
    echo "Chyba: nenašel jsem žádný úspěšný build. Spusť nejdřív CI nebo použij make dmg (vyžaduje Xcode)."
    exit 1
fi

echo "==> Stahuji artifact NAME.app z běhu $RUN_ID…"
rm -rf build/ci
mkdir -p build/ci
gh run download "$RUN_ID" --repo "$REPO" -n NAME-app -D build/ci

# Odstranění karantény, aby šel ad-hoc podepsaný build spustit
xattr -dr com.apple.quarantine build/ci/NAME.app 2>/dev/null || true

echo
echo "Hotovo: build/ci/NAME.app"
echo "Instalace:  sudo cp -R build/ci/NAME.app /Applications/   (nebo přetáhni myší)"
