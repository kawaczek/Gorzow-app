# 🐾 Księga Procedur: Gorzow Bastion v3.0 (Backup Edition)

Dokumentacja procesów kompilacji, wersji i BEZWZGLĘDNEGO bezpieczeństwa danych.

## 1. Żelazna Zasada Backupu 🛡️
- **KAŻDA ZMIANA** w kodzie (Termux) musi być natychmiast zatwierdzona (commit) i wypchnięta (push) na GitHub.
- **GitHub traktujemy jako Pancerny Sejf (Backup)** na wypadek awarii środowiska lub błędów agenta.
- **Zdalne Repo**: https://github.com/kawaczek/Gorzow-app.git
- **Zakaz**: Nigdy nie wysyłamy plików `.env`, folderów `build/`, `.dart_tool/` oraz plików `.apk`.

## 2. Architektura Systemu 🏗️
- **Centrum Sterowania (Termux)**: Tu Gemini edytuje kod i zarządza backupem.
- **Fabryka (Minionek)**: Tu budujemy uniwersalne APK (v4.0) przy użyciu czystego Flutter SDK.
- **Bastion Danych (FTP)**: `gorzow.kawak.pl` serwuje dane JSON, mapy PHP i gotowe APK.

## 3. Procedura Wydania (Step-by-Step) 🚀
1.  **Kodowanie**: Zmiana w `lib/main.dart` lub innych plikach.
2.  **Backup**: `git add . && git commit -m "..." && git push`.
3.  **Desant**: `scp -r ~/projekty/gorzow minionek:~/projekty/`.
4.  **Budowa**: Na Minionku odpalamy `./o-build.sh`.
    - Skrypt podbija wersję w `manifest.json`.
    - Buduje uniwersalne APK.
    - Wysyła wszystko na FTP.
5.  **Synchronizacja Zwrotna**: Po buildzie pobieramy `manifest.json` z Minionka, aby Termux znał nową wersję.

## 4. Zarządzanie Treścią 🗺️
- Punkty POI edytujemy w `wersje/poi.json`.
- Zmiana kolorów i powiadomień w `wersje/manifest.json`.
- Zmiany w logice map w `map.php` na serwerze.

---
*Alfred (Backend Support) & Oberon (Frontend Spirit) 🐾✨*
*Zasada bezwzględnego backupu wprowadzona: 2026-03-31*
