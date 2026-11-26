# NAME

Pojmenováváč fotografií pro macOS — nativní SwiftUI aplikace, která hromadně přejmenovává
fotografie na disku podle jejich pořadí na timeline (např. `01 - Vylet_Praha.jpg`, `02 - Vylet_Praha.jpg`).
 Fotografie se nikdy neupravují — mění se výhradně názvy souborů.

## Funkce

- **Timeline** — vkládání fotek přetažením z Finderu, přes „Otevřít s…“ nebo tlačítkem „Přidat fotografie“;
  řazení přetahováním (drag-to-reorder se zobrazeným slotem), štítky s pořadovým číslem, odebrání přes „×“,
  tlačítko „Seřadit dle EXIF“.
- **Export** — celá timeline najednou (fluid grid), živý náhled názvů, konfigurace pojmenování
  (konstantní název, pozice čísla, formát čísla `1 / 01 / 001 / 0001 / I / A`, oddělovač, počáteční číslo),
  tabulka přejmenování s červeným zvýrazněním kolizí, přejmenování na místě nebo kopie do zvolené složky,
  undo po přejmenování.
- Černobílý design s vysokým kontrastem (jediná barva: červená `#D40000` pro chyby/kolize);
  v tmavém režimu macOS se paleta invertuje. Všechny ovládací prvky mají hover/pressed stavy (120–180 ms).
- Podporované formáty: JPEG, PNG, HEIC/HEIF, TIFF, WebP + RAW (CR2, CR3, ARW, NEF, DNG, ORF, RW2, RAF, PEF).
- App Sandbox, lokalizace čeština (`cs.lproj/Localizable.strings`), konfigurace pojmenování v UserDefaults.

## Technické požadavky

- Swift 5.9+, SwiftUI, macOS 13 Ventura+, architektura MVVM.
- Miniatury asynchronně přes ImageIO, přejmenování přes `FileManager.moveItem` (dvoufázově, aby šlo i v cyklu).

## Build

Otevři `NAME.xcodeproj` v Xcode 15+ a spusť target **NAME** (⌘R).

## Rozhodnutí nad rámec specifikace (sekce 11)

1. Tmavý režim: paleta se invertuje podle režimu systému.
2. RAW formáty: podporovány (CR2, CR3, ARW, NEF, DNG, ORF, RW2, RAF, PEF).
3. Přejmenování probíhá v původních složkách; navíc je režim „Kopie do vybrané složky“.
4. Jméno aplikace v menu baru: **NAME**.
5. Undo po přejmenování: ano („Vrátit přejmenování“).
6. Řazení podle EXIF data: ano, tlačítko „Seřadit dle EXIF“.
7. Ikona: jednoduchá černobílá (tři bílé sloupce rostoucí výšky na černém pozadí) v `Assets.xcassets`.

Další dokumentovaná rozhodnutí jsou přímo v komentářích v kódu (např. varianta oddělovače „spojovník“
vychází jako `" - "`, aby odpovídala příkladu `01 - Vylet_Praha.jpg` ze specifikace).
