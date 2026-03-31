<!DOCTYPE html>
<html>
<head>
    <title>Gorzow - Mapa</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        body { margin:0; padding:0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        #map { height: 100vh; width: 100vw; }
        .poi-popup { text-align: center; padding: 5px; }
        .nav-btn { background: #008C45; color: white; padding: 12px; border-radius: 15px; text-decoration: none; display: block; margin-top: 15px; font-weight: bold; box-shadow: 0 5px 15px rgba(0,140,69,0.3); }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        const urlParams = new URLSearchParams(window.location.search);
        const dataFile = urlParams.get('data') || 'poi.json';
        const userLat = parseFloat(urlParams.get('lat')) || 52.73;
        const userLng = parseFloat(urlParams.get('lng')) || 15.23;

        const map = L.map('map').setView([userLat, userLng], 14);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap'
        }).addTo(map);

        // Znacznik użytkownika 🐾
        L.marker([userLat, userLng], {
            icon: L.icon({
                iconUrl: 'https://cdn-icons-png.flaticon.com/512/684/684908.png',
                iconSize: [35, 35],
                iconAnchor: [17, 35]
            })
        }).addTo(map).bindPopup("<b>Ty tu jesteś 🐾</b>");

        // Pobierz punkty POI 🏙️
        fetch(dataFile)
            .then(res => res.json())
            .then(data => {
                data.forEach(p => {
                    const marker = L.marker([p.lat, p.lng]).addTo(map);
                    marker.bindPopup(`
                        <div class="poi-popup">
                            <b style="font-size: 16px;">${p.name}</b><br>
                            <span style="color: #666;">${p.desc || ''}</span><br>
                            <a href="https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lng}" target="_blank" class="nav-btn">NAWIGUJ 🚀</a>
                        </div>
                    `, { minWidth: 200 });
                });
            })
            .catch(err => console.error("Błąd ładowania punktów:", err));
    </script>
</body>
</html>
