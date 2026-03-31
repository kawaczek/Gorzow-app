document.addEventListener('DOMContentLoaded', () => {
    let tilesData = [];
    
    // Elements
    const systemForm = document.getElementById('system-form');
    const tilesList = document.getElementById('tiles-list');
    const btnAddTile = document.getElementById('btn-add-tile');
    const btnSaveTiles = document.getElementById('btn-save-tiles');
    
    // Modal Elements
    const tileModal = document.getElementById('tile-modal');
    const tileForm = document.getElementById('tile-form');
    const tileTypeSelect = document.getElementById('tile-type');
    const dynamicFields = document.querySelectorAll('.dynamic-field');
    
    // Load Data
    fetchSystem();
    fetchTiles();
    
    // --- SYSTEM LOGIC ---
    function fetchSystem() {
        fetch('api.php?action=get_system')
            .then(r => r.json())
            .then(data => {
                document.getElementById('app_name').value = data.app_name || '';
                document.getElementById('primary_color').value = data.primary_color || '#008C45';
                document.getElementById('ota_version').value = data.ota_version || '1.0';
                document.getElementById('notification').value = data.notification || '';
                // Update CSS variable
                document.documentElement.style.setProperty('--primary', data.primary_color || '#008C45');
            });
    }

    systemForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const data = {
            app_name: document.getElementById('app_name').value,
            primary_color: document.getElementById('primary_color').value,
            ota_version: parseFloat(document.getElementById('ota_version').value),
            notification: document.getElementById('notification').value
        };
        fetch('api.php?action=save_system', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        }).then(r => r.json()).then(res => {
            if(res.success) alert('System zapisany! 🐾');
            else alert('Błąd: ' + res.error);
        });
    });

    // --- TILES LOGIC ---
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
                    <strong>${tile.title} (${tile.id})</strong>
                    <span>Typ: ${tile.type} | Rozmiar: ${tile.size}</span>
                </div>
                <div class="tile-actions">
                    <button class="outline" onclick="moveTile(${index}, -1)" ${index === 0 ? 'disabled' : ''}>⬆️</button>
                    <button class="outline" onclick="moveTile(${index}, 1)" ${index === tilesData.length - 1 ? 'disabled' : ''}>⬇️</button>
                    <button class="secondary" onclick="editTile(${index})">Edytuj</button>
                    <button class="danger" onclick="deleteTile(${index})">Usuń</button>
                </div>
            `;
            tilesList.appendChild(div);
        });
    }

    window.moveTile = (index, dir) => {
        if (index + dir < 0 || index + dir >= tilesData.length) return;
        const temp = tilesData[index];
        tilesData[index] = tilesData[index + dir];
        tilesData[index + dir] = temp;
        renderTiles();
    };

    window.deleteTile = (index) => {
        if (confirm('Na pewno usunąć ten kafelek, Szefie?')) {
            tilesData.splice(index, 1);
            renderTiles();
        }
    };

    btnSaveTiles.addEventListener('click', () => {
        fetch('api.php?action=save_tiles', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ tiles: tilesData })
        }).then(r => r.json()).then(res => {
            if(res.success) alert('Kafelki zapisane! 🐾');
            else alert('Błąd: ' + res.error);
        });
    });

    // --- MODAL LOGIC ---
    tileTypeSelect.addEventListener('change', (e) => {
        dynamicFields.forEach(f => f.style.display = 'none');
        if (e.target.value === 'web' || e.target.value === 'app_link') {
            document.getElementById('field-url').style.display = 'block';
        } else if (e.target.value === 'live') {
            document.getElementById('field-kind').style.display = 'block';
        } else if (e.target.value === 'map') {
            document.getElementById('field-data-url').style.display = 'block';
        }
    });

    btnAddTile.addEventListener('click', () => {
        document.getElementById('modal-title').innerText = 'Dodaj Kafelek';
        document.getElementById('tile-index').value = '';
        tileForm.reset();
        tileTypeSelect.dispatchEvent(new Event('change'));
        tileModal.showModal();
    });

    window.editTile = (index) => {
        const tile = tilesData[index];
        document.getElementById('modal-title').innerText = 'Edytuj Kafelek';
        document.getElementById('tile-index').value = index;
        
        document.getElementById('tile-id').value = tile.id;
        document.getElementById('tile-type').value = tile.type;
        document.getElementById('tile-size').value = tile.size;
        document.getElementById('tile-title').value = tile.title;
        document.getElementById('tile-icon').value = tile.icon || '';
        document.getElementById('tile-url').value = tile.url || '';
        document.getElementById('tile-kind').value = tile.kind || '';
        document.getElementById('tile-data-url').value = tile.data_url || '';
        
        tileTypeSelect.dispatchEvent(new Event('change'));
        tileModal.showModal();
    };

    document.getElementById('btn-close-modal').addEventListener('click', (e) => { e.preventDefault(); tileModal.close(); });
    document.getElementById('btn-cancel-modal').addEventListener('click', (e) => { e.preventDefault(); tileModal.close(); });

    tileForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const index = document.getElementById('tile-index').value;
        const type = document.getElementById('tile-type').value;
        
        const tile = {
            id: document.getElementById('tile-id').value,
            type: type,
            size: document.getElementById('tile-size').value,
            title: document.getElementById('tile-title').value,
        };
        
        if (document.getElementById('tile-icon').value) tile.icon = document.getElementById('tile-icon').value;
        
        if (type === 'web' || type === 'app_link') tile.url = document.getElementById('tile-url').value;
        else if (type === 'live') tile.kind = document.getElementById('tile-kind').value;
        else if (type === 'map') tile.data_url = document.getElementById('tile-data-url').value;
        
        if (index === '') {
            tilesData.push(tile);
        } else {
            tilesData[index] = tile;
        }
        
        renderTiles();
        tileModal.close();
    });
});