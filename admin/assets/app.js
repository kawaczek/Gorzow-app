/* OBERON MASTER ENGINE v7.0 - NEXT GEN */
document.addEventListener('DOMContentLoaded', () => {
    let tilesData = [], poiData = { points: [] }, currentPoiCat = '', adminMap;

    // --- TOAST SYSTEM ---
    const showToast = (msg) => {
        const container = document.getElementById('notification-toast');
        const toast = document.createElement('div');
        toast.className = 'toast-modern';
        toast.innerText = msg;
        container.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
    };

    // --- SPA NAVIGATION ---
    const navItems = document.querySelectorAll('.nav-item[data-tab]');
    const tabContents = document.querySelectorAll('.tab-content');

    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            const target = item.dataset.tab;
            navItems.forEach(i => i.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            
            item.classList.add('active');
            document.getElementById('tab-' + target).classList.add('active');
            
            if(target === 'tiles') initSortable();
            if(target === 'poi') initPoi();
        });
    });

    // --- SYSTEM CONFIG ---
    const fetchSystem = () => {
        fetch('api.php?action=get_system').then(r => r.json()).then(data => {
            document.getElementById('app_name').value = data.app_name || '';
            document.getElementById('primary_color').value = data.primary_color || '#008C45';
            document.getElementById('map_style').value = data.map_style || 'voyager';
            document.getElementById('notification').value = data.notification || '';
            document.documentElement.style.setProperty('--p', data.primary_color);
        });
    };
    document.getElementById('system-form').onsubmit = (e) => {
        e.preventDefault();
        const d = {
            app_name: document.getElementById('app_name').value,
            primary_color: document.getElementById('primary_color').value,
            ota_version: 7.0,
            map_style: document.getElementById('map_style').value,
            notification: document.getElementById('notification').value
        };
        saveData('save_system', d, 'System gotowy! 🐾');
    };

    // --- DASHBOARD (DRAG & DROP) ---
    const tilesList = document.getElementById('tiles-list');
    let sortableInstance;

    const fetchTiles = () => {
        fetch('api.php?action=get_tiles').then(r => r.json()).then(data => {
            tilesData = data.tiles || [];
            renderTiles();
        });
    };

    const renderTiles = () => {
        tilesList.innerHTML = '';
        tilesData.forEach((t, i) => {
            const el = document.createElement('div');
            el.className = 'tile-item';
            el.dataset.index = i;
            el.innerHTML = `
                <div class="tile-info">
                    <strong>${t.title}</strong>
                    <span>${t.type} • ${t.id}</span>
                </div>
                <div class="tile-actions">
                    <button class="circle-btn small" onclick="editTile(${i})">✏️</button>
                </div>
            `;
            tilesList.appendChild(el);
        });
        initSortable();
    };

    const initSortable = () => {
        if(sortableInstance) sortableInstance.destroy();
        sortableInstance = new Sortable(tilesList, {
            animation: 150,
            ghostClass: 'sortable-ghost',
            onEnd: (evt) => {
                const movedItem = tilesData.splice(evt.oldIndex, 1)[0];
                tilesData.splice(evt.newIndex, 0, movedItem);
            }
        });
    };

    window.editTile = (i) => {
        const t = tilesData[i];
        document.getElementById('tile-index').value = i;
        document.getElementById('tile-id').value = t.id;
        document.getElementById('tile-type').value = t.type;
        document.getElementById('tile-parent-id').value = t.parent_id || '';
        document.getElementById('tile-title').value = t.title;
        document.getElementById('tile-icon').value = t.icon || '';
        document.getElementById('tile-url').value = t.url || '';
        document.getElementById('tile-data-url').value = t.data_url || '';
        document.getElementById('tile-modal').showModal();
    };

    document.getElementById('btn-add-tile').onclick = () => {
        document.getElementById('tile-form').reset();
        document.getElementById('tile-index').value = '-1';
        document.getElementById('tile-modal').showModal();
    };

    document.getElementById('tile-form').onsubmit = (e) => {
        e.preventDefault();
        const i = parseInt(document.getElementById('tile-index').value);
        const t = {
            id: document.getElementById('tile-id').value,
            type: document.getElementById('tile-type').value,
            parent_id: document.getElementById('tile-parent-id').value,
            title: document.getElementById('tile-title').value,
            icon: document.getElementById('tile-icon').value,
            url: document.getElementById('tile-url').value,
            data_url: document.getElementById('tile-data-url').value
        };
        if(i === -1) tilesData.push(t); else tilesData[i] = t;
        renderTiles();
        document.getElementById('tile-modal').close();
    };

    document.getElementById('btn-save-tiles').onclick = () => {
        saveData('save_tiles', {tiles: tilesData}, 'Dashboard zsynchronizowany! 🚀');
    };

    // --- POI ENGINE ---
    const poiSelect = document.getElementById('poi-category-select');
    const poiPointsList = document.getElementById('poi-points-list');

    const initPoi = () => {
        fetch('api.php?action=list_poi_categories').then(r => r.json()).then(data => {
            poiSelect.innerHTML = '<option value="">Wybierz kategorię...</option>';
            data.categories.forEach(c => poiSelect.add(new Option(c, c)));
        });
    };

    poiSelect.onchange = (e) => {
        currentPoiCat = e.target.value;
        if(!currentPoiCat) { document.getElementById('poi-editor-container').style.display = 'none'; return; }
        fetch(`api.php?action=get_poi_category&category=${currentPoiCat}`).then(r => r.json()).then(data => {
            poiData = data;
            document.getElementById('poi-editor-container').style.display = 'block';
            renderPoiMap();
            renderPoiPoints();
        });
    };

    const renderPoiMap = () => {
        if(!adminMap) {
            adminMap = L.map('admin-map').setView([52.73, 15.23], 13);
            L.tileLayer('https://{s}.basemaps.cartocdn.com/voyager/{z}/{x}/{y}{r}.png', { attribution: '© OBERON' }).addTo(adminMap);
            adminMap.on('click', (e) => {
                const n = prompt('Nazwa punktu:');
                if(n) {
                    poiData.points.push({ name: n, lat: e.latlng.lat.toFixed(6), lng: e.latlng.lng.toFixed(6) });
                    renderPoiPoints();
                }
            });
        }
        setTimeout(() => adminMap.invalidateSize(), 200);
    };

    const renderPoiPoints = () => {
        poiPointsList.innerHTML = '';
        (poiData.points || []).forEach((p, i) => {
            const div = document.createElement('div');
            div.className = 'tile-item';
            div.style.padding = '10px 20px';
            div.innerHTML = `<div><strong>${p.name}</strong><span>${p.lat}, ${p.lng}</span></div>
                             <button class="circle-btn small danger" onclick="deletePoi(${i})">×</button>`;
            poiPointsList.appendChild(div);
        });
    };

    window.deletePoi = (i) => { poiData.points.splice(i, 1); renderPoiPoints(); };

    document.getElementById('btn-save-poi').onclick = () => {
        saveData(`save_poi_category&category=${currentPoiCat}`, poiData, 'Mapa POI zapisana! 📍');
    };

    document.getElementById('btn-new-poi-category').onclick = () => {
        const n = prompt('Nazwa nowej kategorii:');
        if(n) { 
            currentPoiCat = n.toLowerCase().replace(/\s+/g, '_');
            poiData = { points: [] };
            saveData(`save_poi_category&category=${currentPoiCat}`, poiData, 'Kategoria stworzona! 🐾');
            initPoi();
        }
    };

    const saveData = (action, data, msg) => {
        fetch(`api.php?action=${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        }).then(r => r.json()).then(res => { if(res.success) alert(msg); });
    };

    // --- BOOT ---
    fetchSystem();
    fetchTiles();
});
