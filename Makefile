.PHONY: app dmg zip notarize ci-app clean run

# Sestaví NAME.app (Release) do build/ — spusť na MacBooku
app:
	./scripts/build-app.sh

# Vytvoří instalační DMG build/NAME.dmg
dmg:
	./scripts/make-dmg.sh

# Jen ZIP build/NAME.zip
zip:
	./scripts/build-app.sh

# Notarizace (vyžaduje Apple Developer ID, viz scripts/notarize.sh)
notarize:
	./scripts/notarize.sh

# Stáhne hotový NAME.app z CI (bez Xcode, potřeba přihlášený gh)
ci-app:
	./scripts/download-ci-app.sh

# Spustí aplikaci v Debug přímo z Xcode buildu
run:
	xcodebuild -project NAME.xcodeproj -scheme NAME -configuration Debug build
	open build/DerivedData/Build/Products/Debug/NAME.app

clean:
	rm -rf build
