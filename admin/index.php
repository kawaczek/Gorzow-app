<?php
require_once 'auth.php';
if (!checkAuth()) {
?>
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
    <title>OBERON 7.0 - Wejście</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;800&display=swap" rel="stylesheet">
    <style>
        :root { --p: #008C45; }
        body { font-family: 'Plus Jakarta Sans', sans-serif; background: #ffffff; margin: 0; display: flex; align-items: center; justify-content: center; height: 100vh; }
        .login-box { text-align: center; width: 85%; max-width: 320px; }
        .avatar-circle { width: 80px; height: 80px; background: var(--p); border-radius: 30px; margin: 0 auto 2rem; display: flex; align-items: center; justify-content: center; font-size: 2.5rem; box-shadow: 0 20px 40px rgba(0,140,69,0.2); }
        h1 { font-weight: 800; font-size: 1.8rem; margin-bottom: 0.5rem; color: #1e293b; }
        input { background: #f1f5f9; border: 2px solid transparent; padding: 1.2rem; border-radius: 24px; width: 100%; margin: 1.5rem 0; font-size: 1rem; text-align: center; outline: none; transition: 0.3s; box-sizing: border-box; }
        input:focus { border-color: var(--p); background: white; box-shadow: 0 10px 20px rgba(0,0,0,0.05); }
        button { background: #1e293b; border: none; padding: 1.2rem; border-radius: 24px; width: 100%; color: white; font-weight: 800; cursor: pointer; transition: 0.3s; }
        button:active { transform: scale(0.95); }
    </style>
</head>
<body>
    <div class="login-box">
        <div class="avatar-circle">🐾</div>
        <h1>OBERON</h1>
        <p style="opacity: 0.5; font-size: 0.9rem;">Wpisz Złoty Klucz do Bastionu</p>
        <form method="POST">
            <input type="hidden" name="action" value="login">
            <input type="password" name="password" placeholder="••••••••" required autofocus>
            <button type="submit">ODBLOKUJ</button>
        </form>
    </div>
</body>
</html>
<?php exit; } ?>

<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
    <title>OBERON DASHBOARD</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <link rel="stylesheet" href="assets/style.css">
    <!-- SortableJS for Drag & Drop -->
    <script src="https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js"></script>
</head>
<body>
    <div class="app-shell">
        <!-- TOP BAR -->
        <header class="top-bar">
            <div class="user-pill">
                <div class="mini-avatar">🐾</div>
                <span>Witaj, <strong>Szefie</strong></span>
            </div>
            <div class="ota-status">
                <span class="pulse-dot"></span> Online
            </div>
        </header>

        <!-- MAIN CONTENT (TABS) -->
        <div class="tab-container">
            <!-- TAB: SYSTEM -->
            <div id="tab-system" class="tab-content active">
                <div class="bento-grid">
                    <div class="bento-card wide welcome-card">
                        <h2>⚙️ Ustawienia Bastionu</h2>
                        <p>Zarządzaj sercem swojej aplikacji.</p>
                    </div>
                    <div class="bento-card">
                        <form id="system-form">
                            <label>Nazwa Aplikacji</label>
                            <input type="text" id="app_name" required>
                            
                            <div class="grid-half">
                                <div>
                                    <label>Kolor Mocy</label>
                                    <input type="color" id="primary_color">
                                </div>
                                <div>
                                    <label>Styl Mapy</label>
                                    <select id="map_style">
                                        <option value="voyager">Voyager</option>
                                        <option value="light">Clear Light</option>
                                        <option value="dark">Deep Dark</option>
                                        <option value="satellite">Satelita</option>
                                    </select>
                                </div>
                            </div>
                            
                            <label>Powiadomienie</label>
                            <input type="text" id="notification">
                            
                            <button type="submit" class="action-btn main">Zapisz System</button>
                        </form>
                    </div>
                </div>
            </div>

            <!-- TAB: TILES (DASHBOARD) -->
            <div id="tab-tiles" class="tab-content">
                <div class="section-title">
                    <h3>📱 Twój Dashboard</h3>
                    <button id="btn-add-tile" class="circle-btn">+</button>
                </div>
                <p class="hint">Przytrzymaj i przeciągnij, aby zmienić kolejność.</p>
                <div id="tiles-list" class="sortable-list">
                    <!-- Dynamiczne kafelki -->
                </div>
                <div class="floating-save">
                    <button id="btn-save-tiles" class="action-btn dark">Zapisz Układ</button>
                </div>
            </div>

            <!-- TAB: POI -->
            <div id="tab-poi" class="tab-content">
                <div class="bento-card">
                    <h3>📍 Mapa Punktów</h3>
                    <div class="poi-header">
                        <select id="poi-category-select"></select>
                        <button id="btn-new-poi-category" class="icon-btn">✚</button>
                    </div>
                    
                    <div id="poi-editor-container" style="display:none;">
                        <div id="admin-map"></div>
                        <div id="poi-points-list" class="poi-points-list"></div>
                        <button id="btn-save-poi" class="action-btn">Zapisz POI</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- BOTTOM NAVIGATION -->
        <nav class="main-nav">
            <div class="nav-item active" data-tab="system">
                <div class="nav-icon">⚙️</div>
                <span>System</span>
            </div>
            <div class="nav-item" data-tab="tiles">
                <div class="nav-icon">📱</div>
                <span>Pulpit</span>
            </div>
            <div class="nav-item" data-tab="poi">
                <div class="nav-icon">📍</div>
                <span>Mapa</span>
            </div>
            <div class="nav-item logout-trigger">
                <form method="POST" id="logout-form"><input type="hidden" name="action" value="logout"></form>
                <div class="nav-icon">🚪</div>
                <span>Wyjdź</span>
            </div>
        </nav>
    </div>

    <!-- MODAL EDYCJI -->
    <dialog id="tile-modal">
        <div class="modal-body">
            <h3>Edytuj Element</h3>
            <form id="tile-form">
                <input type="hidden" id="tile-index">
                <input type="text" id="tile-title" placeholder="Tytuł" required>
                <div class="grid-half">
                    <select id="tile-type">
                        <option value="web">Strona</option>
                        <option value="folder">Folder</option>
                        <option value="live">Pogoda</option>
                        <option value="map">Mapa</option>
                    </select>
                    <input type="text" id="tile-icon" placeholder="Ikona">
                </div>
                <input type="text" id="tile-id" placeholder="ID (unikalne)">
                <input type="text" id="tile-parent-id" placeholder="ID Folderu (opcja)">
                <input type="text" id="tile-url" placeholder="Adres URL">
                <input type="text" id="tile-data-url" placeholder="Plik POI">
                
                <div class="modal-actions">
                    <button type="button" class="btn-text" onclick="document.getElementById('tile-modal').close()">Anuluj</button>
                    <button type="submit" class="btn-confirm">Gotowe</button>
                </div>
            </form>
        </div>
    </dialog>

    <div id="notification-toast"></div>

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="assets/app.js"></script>
</body>
</html>
