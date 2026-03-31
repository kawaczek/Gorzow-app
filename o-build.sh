#!/bin/bash
set -e
cd ~/projekty/gorzow

# 0. Lokalny Skarbiec (Obejście Snapa) 🐾🛡️
export PUB_CACHE="$HOME/projekty/gorzow/.pub-cache"
mkdir -p "$PUB_CACHE"

echo 'System OBERON: Universal Build Script v4.1 (Tile Edition) 🐾🏗️📡'

# 1. Załaduj Skarbiec .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "BŁĄD: Brak Skarbca .env! 🐾🛑"
    exit 1
fi

# 2. Pobieranie wersji z dane/system.json
OLD_VER=$(grep -oP '(?<="ota_version": )[0-9.]+' dane/system.json)
NEW_VER=$(echo "scale=1; $OLD_VER + 0.1" | bc)
if [[ $NEW_VER == .* ]]; then NEW_VER="0$NEW_VER"; fi

BUILD_NUM=$(echo "$NEW_VER * 10" | bc | cut -d'.' -f1)

echo "Aktualizacja Mocy: v$OLD_VER -> v$NEW_VER (Build: $BUILD_NUM) 🐾✨"

FLUTTER_BIN="$HOME/sdk/flutter/bin/flutter"

# 3. Aktualizacja plików lokalnych
echo "Pobieram części do Lokalnego Skarbca... 🐾📦"
$FLUTTER_BIN pub get

sed -i "s/version: .*/version: 0.0.$BUILD_NUM+$BUILD_NUM/g" pubspec.yaml
sed -i "s/\"ota_version\": .*/\"ota_version\": $NEW_VER/g" dane/system.json
sed -i "s/_currentAppVersion = .*/_currentAppVersion = $NEW_VER; \/\/ v$NEW_VER/g" lib/main.dart

# 4. Budowanie APK UNIWERSALNEGO (Pancerne) 🏗️
echo 'Buduję duszę UNIWERSALNĄ (armv7, arm64, x86_64)... 🐾🏗️'
$FLUTTER_BIN build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# 5. Przygotowanie paczki
NEW_APK_NAME="gorzow_v${NEW_VER}.apk"
mkdir -p wersje
rm -f wersje/*.apk
cp build/app/outputs/flutter-apk/app-release.apk wersje/$NEW_APK_NAME

# 6. DESANT FTP (gorzow.kawak.pl) 🐾🚀
echo "Rozpoczynam Desant FTP na $FTP_HOST... 🐾📡"
curl --ftp-create-dirs -T "wersje/$NEW_APK_NAME" -u "$FTP_USER:$FTP_PASS" "ftp://$FTP_HOST/wersje/$NEW_APK_NAME"
curl -T "map.php" -u "$FTP_USER:$FTP_PASS" "ftp://$FTP_HOST/map.php"
curl -T "index.php" -u "$FTP_USER:$FTP_PASS" "ftp://$FTP_HOST/index.php"

echo "Wysyłam dane systemowe... 🐾📦"
for f in dane/*.json; do
    echo "Wysyłam $f... 🐾📦"
    curl --ftp-create-dirs -T "$f" -u "$FTP_USER:$FTP_PASS" "ftp://$FTP_HOST/dane/$(basename $f)"
done

echo "System OBERON: Misja v$NEW_VER zakończona sukcesem! 🐾🏆"
