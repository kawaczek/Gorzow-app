# 🐾 BIBLIA BASTIONU GORZOW v2.2 (System OBERON) 🛡️

Ten dokument jest przeznaczony dla Agenta Gemini CLI zarządzającego projektem. Zawiera kompletną mapę drogową, protokoły komunikacyjne i logikę silnika.

## 1. STRUKTURA IMPERIUM (ŚRODOWISKO) 🏗️
- **TERMUX (MASTER)**: Główny węzeł. Tu edytujemy kod (`~/projekty/gorzow`). Zarządza backupem (Git) i steruje Minionkiem (SSH).
- **MINIONEK (WORKER)**: Laptop Asus (`ssh minionek`). Fabryka APK.
    - **Flutter SDK**: `~/sdk/flutter/bin/flutter`.
    - **Android SDK**: `~/sdk/android`.
    - **Emulator**: `Gorzow_Emulator` (Android 34, x86_64).
    - **Protokół SSH**: Sesje są nieinteraktywne - ZAWSZE używaj pełnych ścieżek do binariów.
- **SERWER FTP (PRODUKCJA)**: `gorzow.kawak.pl`. Hostuje dane i pliki APK.
    - Dane logowania: Skarbiec `.env` w Termuxie.
- **GITHUB (BACKUP)**: `kawaczek/Gorzow-app`. Żelazna zasada: commit po każdej zmianie.

## 2. MAPA PLIKÓW (LOGIKA) 📂
- `lib/main.dart`: Silnik kafelkowy. Główne klasy:
    - `TileDashboard`: Zarządza siatką, trybem edycji i cachem.
    - `_buildTile`: Renderuje kafelki na podstawie rozmiarów (1x1, 2x2, 4x2).
    - `_fetchData`: Pobiera JSONy z serwera i zapisuje w `SharedPreferences`.
- `dane/system.json`: Globalna konfiguracja (kolory, nazwa, wersja OTA).
- `dane/tiles.json`: Definicja kafelków. Typy: `live` (pogoda), `web` (linki), `map` (POI), `app_link` (zewnętrzne apki).
- `o-build.sh`: Skrypt-orkiestrator na Minionku.
    - Funkcja: Podbija wersję w `system.json`, buduje Universal APK, robi desant na FTP.
- `index.php`: Strona główna. Skrypt PHP automatycznie wykrywa najnowsze APK w folderze `wersje/` na podstawie daty modyfikacji i manifestu.
- `map.php`: Silnik mapy (Leaflet JS). Aplikacja ładuje go w WebView, przekazując parametry `lat`, `lng` i `data`.

## 3. PROTOKOŁY OPERACYJNE (ROZKAZY) 📡
### Budowa nowej wersji:
1.  **Backup**: `cd ~/projekty/gorzow && git add . && git commit -m "..." && git push`
2.  **Synchronizacja**: `scp -r lib assets dane android .env pubspec.yaml o-build.sh index.php map.php minionek:~/projekty/gorzow/`
3.  **Kompilacja**: `ssh minionek "cd ~/projekty/gorzow && ./o-build.sh"`
4.  **Weryfikacja (Emulator)**: 
    - Odpalenie: `ssh minionek "~/sdk/android/emulator/emulator -avd Gorzow_Emulator -no-window &"`
    - Instalacja i bieg: `ssh minionek "cd ~/projekty/gorzow && ~/sdk/flutter/bin/flutter run --release -d emulator-5554"`

### Ratowanie systemu (Fixes):
- **Problem z Gradle**: `ssh minionek "cd ~/projekty/gorzow/android && ./gradlew clean"`
- **Brak paczek**: `ssh minionek "cd ~/projekty/gorzow && ~/sdk/flutter/bin/flutter pub get"`
- **Regeneracja Androida**: `ssh minionek "cd ~/projekty/gorzow && rm -rf android && ~/sdk/flutter/bin/flutter create . --platforms android"`

## 4. FILOZOFIA "PANCERNEJ BRAMY" 🛡️
- **Minimalizm Fluttera**: Unikaj natywnych bibliotek mapowych i skomplikowanych pluginów. Korzystaj z WebView + PHP/JS na serwerze (większa elastyczność, brak błędów kompilacji).
- **Universal Build**: Nigdy nie buduj tylko na `arm64-v8a`. Zawsze `flutter build apk` bez flag platformy, aby APK działało na każdym telefonie Szefa.
- **Dynamiczność**: Jak najwięcej logiki (układ kafelków, linki, powiadomienia) trzymaj w JSON na serwerze. Cel: aktualizacja aplikacji bez wysyłania nowego APK.

## 5. ZASADY BEZWZGLĘDNE 🐾
1.  Nigdy nie modyfikuj `lib/main.dart` bez wcześniejszego backupu oryginału.
2.  Zawsze sprawdzaj `flutter doctor` na Minionku przy błędach buildu.
3.  `.env` jest święty i tajny - nigdy nie trafia na GitHub.

---
*Alfred (Logistyka) & Oberon (Duch Systemu) 🐾✨*
*Data spisania: 2026-03-31 (v2.2)*
