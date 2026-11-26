#!/bin/bash
# Vytvoří instalační DMG (NAME.dmg) s NAME.app a odkazem na Applications.
# Použití na MacBooku:  ./scripts/make-dmg.sh   (volitelně po ./scripts/build-app.sh)
set -euo pipefail
cd "$(dirname "$0")/.."

DERIVED="build/DerivedData"
APP="$DERIVED/Build/Products/Release/NAME.app"

if [ ! -d "$APP" ]; then
    ./scripts/build-app.sh
fi

STAGING="build/dmg"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/NAME.app"
ln -s /Applications "$STAGING/Applications"

rm -f build/NAME.dmg
hdiutil create -volname "NAME" -srcfolder "$STAGING" -ov -format UDZO build/NAME.dmg

echo
echo "Hotovo: build/NAME.dmg — otevři ho a přetáhni NAME.app do Applications."
