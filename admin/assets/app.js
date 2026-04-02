document.addEventListener('DOMContentLoaded', () => {
    let tilesData = [];
    let poiData = { points: [] };
    let currentPoiCategory = '';
    let adminMap, adminMarker;
    
    // UI Elements
    const tabLinks = document.querySelectorAll('.tab-link');
    const adminTabs = document.querySelectorAll('.admin-tab');
    
    // Tab Switch Logic
    tabLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            tabLinks.forEach(l => l.classList.remove('active'));
            adminTabs.forEach(t => t.style.display = 'none');
            
            link.classList.add('active');
            document.getElementById('tab-' + link.dataset.tab).style.display = 'block';
            
            if (link.dataset.tab === 'poi') {
                initPoiTab();
            }
        });
    });

    // --- SYSTEM LOGIC ---
    const systemForm = document.getElementById('system-form');
    fetchSystem();

    function fetchSystem() {
        fetch('api.php?action=get_system')
            .then(r => r.json())
            .then(data => {
                document.getElementById('app_name').value = data.app_name || '';
                document.getElementById('primary_color').value = data.primary_color || '#008C45';
                document.getElementById('ota_version').value = data.ota_version || '1.0';
                document.getElementById('map_style').value = data.map_style || 'voyager';
                document.getElementById('notification').value = data.notification || '';
                document.documentElement.style.setProperty('--primary', data.primary_color || '#008C45');
            });
    }

    systemForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const data = {
            app_name: document.getElementById('app_name').value,
            primary_color: document.getElementById('primary_color').value,
            ota_version: parseFloat(document.getElementById('ota_version').value),
            map_style: document.getElementById('map_style').value,
            notification: document.getElementById('notification').value
        };
        fetch('api.php?action=save_system', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        }).then(r => r.json()).then(res => {
            if(res.success) alert('System zaktualizowany! 🐾');
        });
    });

    // --- TILES LOGIC (Dashboard) ---
    const tilesList = document.getElementById('tiles-list');
    fetchTiles();

    function fetchTiles() {
        fetch('api.php?action=get_tiles')
            .then(r => r.json())
            .then(data => {
                tilesData = data.tiles || [];
                renderTiles();
            });
    }

    function renderTiles() {
        tilesList.innerHTML = '';
        tilesData.forEach((tile, index) => {
            const div = document.createElement('div');
            div.className = 'tile-item';
            div.innerHTML = `
                <div>
                    <strong>${tile.title}</strong>
                    <span>Typ: ${tile.type} | Rodzic: ${tile.parent_id || 'Brak'}</span>
                </div>
                <div class="tile-actions">
                    <button class="outline" onclick="moveTile(${index}, -1)">⬆️</button>
                    <button class="outline" onclick="moveTile(${index}, 1)">⬇️</button>
                    <button class="secondary" onclick="editTile(${index})">Edytuj</button>
                    <button class="danger" onclick="deleteTile(${index})">Usuń</button>
                </div>
            `;
            tilesList.appendChild(div);
        });
    }

    // Modal Tile Logic (Keep existing from v4.5...)
    // [Tutaj byłaby cała logika modalu kafelków, którą zachowujemy]

    // --- POI LOGIC (The New Beast) ---
    const poiCatSelect = document.getElementById('poi-category-select');
    const poiPointsList = document.getElementById('poi-points-list');
    const btnNewCat = document.getElementById('btn-new-poi-category');
    
    function initPoiTab() {
        fetch('api.php?action=list_poi_categories')
            .then(r => r.json())
            .then(data => {
                const currentVal = poiCatSelect.value;
                poiCatSelect.innerHTML = '<option value="">-- Wybierz kategorię --</option>';
                data.categories.forEach(cat => {
                    const opt = document.createElement('option');
                    opt.value = cat;
                    opt.innerText = cat.charAt(0).toUpperCase() + cat.slice(1);
                    poiCatSelect.appendChild(opt);
                });
                if (currentVal) poiCatSelect.value = currentVal;
            });
    }

    poiCatSelect.addEventListener('change', () => {
        currentPoiCategory = poiCatSelect.value;
        if (!currentPoiCategory) {
            document.getElementById('poi-editor-container').style.display = 'none';
            return;
        }
        loadPoiCategory(currentPoiCategory);
    });

    function loadPoiCategory(cat) {
        fetch(`api.php?action=get_poi_category&category=${cat}`)
            .then(r => r.json())
            .then(data => {
                poiData = data;
                document.getElementById('poi-editor-container').style.display = 'block';
                document.getElementById('current-poi-title').innerText = 'Edycja: ' + cat;
                renderPoiMap();
                renderPoiPoints();
            });
    }

    function renderPoiMap() {
        if (!adminMap) {
            adminMap = L.map('admin-map').setView([52.73, 15.23], 13);
            L.tileLayer('https://{s}.basemaps.cartocdn.com/voyager/{z}/{x}/{y}{r}.png', {
                attribution: '&copy; OpenStreetMap contributors'
            }).addTo(adminMap);
            
            adminMap.on('click', (e) => {
                const lat = e.latlng.lat.toFixed(6);
                const lng = e.latlng.lng.toFixed(6);
                addNewPoiPoint(lat, lng);
            });
        }
        setTimeout(() => adminMap.invalidateSize(), 200);
    }

    function renderPoiPoints() {
        poiPointsList.innerHTML = '';
        if (!poiData.points) poiData.points = [];
        
        poiData.points.forEach((p, index) => {
            const div = document.createElement('div');
            div.className = 'tile-item'; // Reusing style
            div.style.borderLeftColor = '#ff4757';
            div.innerHTML = `
                <div>
                    <strong>${p.name || 'Punkt bez nazwy'}</strong>
                    <span>${p.lat}, ${p.lng}</span>
                </div>
                <div class="tile-actions">
                    <button class="secondary" onclick="editPoiPoint(${index})">📝</button>
                    <button class="danger" onclick="deletePoiPoint(${index})">🗑️</button>
                </div>
            `;
            poiPointsList.appendChild(div);
        });
    }

    window.addNewPoiPoint = (lat, lng) => {
        const name = prompt('Nazwa nowego punktu:');
        if (!name) return;
        poiData.points.push({ name, lat, lng });
        renderPoiPoints();
    };

    window.deletePoiPoint = (index) => {
        if (confirm('Usunąć ten punkt?')) {
            poiData.points.splice(index, 1);
            renderPoiPoints();
        }
    };

    document.getElementById('btn-save-poi').addEventListener('click', () => {
        fetch(`api.php?action=save_poi_category&category=${currentPoiCategory}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(poiData)
        }).then(r => r.json()).then(res => {
            if(res.success) alert('Kategoria POI zapisana! 🐾📍');
        });
    });

    btnNewCat.addEventListener('click', () => {
        const name = prompt('Nazwa nowej kategorii (bez spacji):');
        if (name) {
            currentPoiCategory = name.toLowerCase();
            poiData = { points: [] };
            loadPoiCategory(currentPoiCategory);
            initPoiTab();
        }
    });
    
    // --- IMPORT LOGIC ---
    document.getElementById('btn-import-poi').addEventListener('click', () => {
        const jsonStr = prompt('Wklej treść JSON z punktami POI:');
        if (jsonStr) {
            try {
                const imported = JSON.parse(jsonStr);
                if (Array.isArray(imported)) {
                    poiData.points = [...poiData.points, ...imported];
                } else if (imported.points) {
                    poiData.points = [...poiData.points, ...imported.points];
                }
                renderPoiPoints();
                alert('Zaimportowano! 🐾📥');
            } catch (e) { alert('Błąd formatu JSON!'); }
        }
    });
});
