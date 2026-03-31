# 🐾 Biblia Bastionu: Projekt GORZOW v2.2 (Tile Edition)

To jest dokument operacyjny dla Agenta Gemini CLI. Zawiera kompletną wiedzę o architekturze, komunikacji i logice systemu. **Czytaj i stosuj bezwzględnie.**

## 1. Architektura Systemu (Model "Bastion") 🏗️
System składa się z czterech filarów:
1.  **Termux (Centrum Dowodzenia)**: Główne miejsce edycji kodu i zarządzania backupem.
2.  **Minionek (Fabryka APK)**: Laptop Asus (alias `minionek`). Posiada czysty Flutter SDK w `~/sdk/flutter` oraz Emulator Androida. Służy wyłącznie do budowania i testowania APK.
3.  **Serwer FTP (`gorzow.kawak.pl`)**: Produkcja. Serwuje dane (JSON), silnik map (PHP) i pliki instalacyjne (APK).
4.  **GitHub (Pancerny Sejf)**: Repozytorium `kawaczek/Gorzow-app`. Każda zmiana **MUSI** tam trafić przed buildem.

## 2. Struktura Projektu 📂
- `lib/main.dart`: Serce aplikacji. Zawiera **TileEngine** (silnik kafelkowy Windows Phone Style).
- `dane/`: Konfiguracja dynamiczna (wysyłana na serwer).
    - `system.json`: Nazwa aplikacji, kolory, wersja OTA, powiadomienia.
    - `tiles.json`: Definicja kafelków (układ, rozmiary, ikony, akcje).
- `wersje/`: Katalog na serwerze i lokalnie na pliki APK i dane specyficzne dla map (np. `poi.json`).
- `assets/`: Zasoby graficzne (ikona SVG).
- `o-build.sh`: Skrypt automatyzujący budowę Universal APK i desant na FTP.
- `index.php`: Inteligentna strona pobierania (Dark Mode, auto-wykrywanie wersji).
- `map.php`: Silnik mapy oparty na Leaflet JS (ładowany przez WebView w aplikacji).

## 3. Komunikacja i Rozkazy 📡
### SSH (Minionek)
- Połączenie: `ssh minionek`.
- Ścieżka projektu: `~/projekty/gorzow`.
- **UWAGA**: W sesjach nieinteraktywnych używaj pełnych ścieżek: `~/sdk/flutter/bin/flutter`.
### FTP (Produkcja)
- Host: `ftp.dm72001.domenomania.eu` (zmienne w `.env`).
- Katalog główny: `/`. Pliki danych: `/dane/`. APK: `/wersje/`.
### GitHub (Backup)
- Repo: `https://github.com/kawaczek/Gorzow-app.git`.
- Zasada: `git add . && git commit -m "..." && git push`.

## 4. Logika Aplikacji (Tile Engine) 📱
- **Zasilanie**: Dane pobierane przy starcie z `dane/system.json` i `dane/tiles.json`.
- **Cache**: Wykorzystuje `shared_preferences`. Jeśli serwer nie odpowiada, ładuje ostatnie znane kafelki.
- **Interakcja**: 
    - Krótkie kliknięcie: Otwiera moduł (WebView, Mapa, AppLink).
    - Przycisk Edytuj (AppBar): Włącza tryb `ReorderableGridView` - pozwala na przesuwanie kafelków (Drag & Drop).
- **Rozmiary kafelków**: `1x1` (mały), `2x2` (średni/kwadrat), `4x2` (szeroki).
- **Moduły**:
    - `web`: Otwiera URL w WebView.
    - `map`: Otwiera `map.php?data=...` z przekazaniem lokalizacji GPS.
    - `app_link`: Otwiera zewnętrzną aplikację przez Package Name (App Bridge).

## 5. Procedura Budowy i Desantu (KRYTYCZNA) 🚀
Zawsze wykonuj te kroki w podanej kolejności:
1.  **Backup**: `git push` do chmury.
2.  **Desant Kodu**: `scp -r lib assets dane android .env pubspec.yaml o-build.sh index.php map.php minionek:~/projekty/gorzow/`.
3.  **Build na Minionku**: `ssh minionek "cd ~/projekty/gorzow && ./o-build.sh"`.
    - Skrypt `o-build.sh` sam podbija wersję, buduje Universal APK i wysyła wszystko na FTP.
4.  **Test Emulatora**: `ssh minionek "~/sdk/flutter/bin/flutter run --release -d emulator-5554"`.

## 6. Rozwiązywanie Problemów 🛠️
- **Błąd "Android Embedding"**: Jeśli Minionek narzeka, usuń folder `android/` i wywołaj `flutter create . --platforms android`.
- **Błąd "Package not found"**: Użyj lokalnego `PUB_CACHE` (wpisane w `o-build.sh`).
- **Błąd Instalacji APK**: Zawsze buduj wersję **Universal** (bez flagi `--target-platform`), aby pasowała do wszystkich procesorów.

---
*Dokument zatwierdzony przez OBERONA v2.2. Nie zmieniać bez rozkazu Szefa.* 🐾🛡️
