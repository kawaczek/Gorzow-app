<!DOCTYPE html>
<html>
<head>
    <title>Bastion Gorzów - Mapa</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        body { margin:0; padding:0; background: #f8fafc; }
        #map { height: 100vh; width: 100vw; }
        .poi-popup { text-align: center; padding: 5px; font-family: 'Segoe UI', sans-serif; }
        .nav-btn { background: #008C45; color: white; padding: 12px; border-radius: 15px; text-decoration: none; display: block; margin-top: 10px; font-weight: bold; font-size: 14px; }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        const urlParams = new URLSearchParams(window.location.search);
        let category = urlParams.get('data') || 'poi';
        // Jeśli category nie ma .json, dodaj ścieżkę
        const dataPath = category.endsWith('.json') ? category : `dane/poi/${category}.json`;
        
        const userLat = parseFloat(urlParams.get('lat')) || 52.73;
        const userLng = parseFloat(urlParams.get('lng')) || 15.23;

        const map = L.map('map', { zoomControl: false }).setView([userLat, userLng], 14);
        L.control.zoom({ position: 'bottomright' }).addTo(map);

        // --- DYNAMICZNY STYL MAPY Z SYSTEM.JSON ---
        fetch('dane/system.json?t=' + Date.now())
            .then(res => res.json())
            .then(sys => {
                let tileUrl = 'https://{s}.basemaps.cartocdn.com/voyager/{z}/{x}/{y}{r}.png'; // Domyślny Voyager
                let attr = '© CartoDB';

                if (sys.map_style === 'dark') {
                    tileUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
                } else if (sys.map_style === 'light') {
                    tileUrl = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
                } else if (sys.map_style === 'satellite') {
                    tileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
                    attr = '© Esri';
                }

                L.tileLayer(tileUrl, { attribution: attr }).addTo(map);
            });

        // Znacznik użytkownika 🐾
        L.marker([userLat, userLng], {
            icon: L.icon({
                iconUrl: 'https://cdn-icons-png.flaticon.com/512/684/684908.png',
                iconSize: [40, 40],
                iconAnchor: [20, 40]
            })
        }).addTo(map).bindPopup("<b>Twoja pozycja 🐾</b>");

        // Pobierz punkty POI z wybranej kategorii 🏙️
        fetch(dataPath + '?t=' + Date.now())
            .then(res => res.json())
            .then(data => {
                const points = data.points || data; // Obsługa starego i nowego formatu
                points.forEach(p => {
                    if(!p.lat || !p.lng) return;
                    const marker = L.marker([p.lat, p.lng]).addTo(map);
                    marker.bindPopup(`
                        <div class="poi-popup">
                            <b style="font-size: 16px;">${p.name}</b><br>
                            <a href="https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lng}" target="_blank" class="nav-btn">PROWADŹ MNIE 🚀</a>
                        </div>
                    `, { minWidth: 180 });
                });
            })
            .catch(err => console.error("Błąd ładowania punktów:", err));
    </script>
</body>
</html>
