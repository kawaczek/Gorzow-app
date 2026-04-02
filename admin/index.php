<?php
require_once 'auth.php';

if (!checkAuth()) {
?>
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bastion Gorzów - Logowanie</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@1/css/pico.min.css">
    <style>
        body { display: flex; align-items: center; justify-content: center; height: 100vh; background-color: #f8f9fa; color: #333; }
        .login-card { max-width: 400px; width: 100%; padding: 2.5rem; border-radius: 16px; background-color: #fff; box-shadow: 0 10px 30px rgba(0,0,0,0.05); border: 1px solid #eee; }
        .error { color: #ff4757; margin-bottom: 1rem; text-align: center; font-weight: 600; }
        button { background-color: #008C45 !important; border-color: #008C45 !important; border-radius: 8px; }
        input { border-radius: 8px !important; }
    </style>
</head>
<body>
    <div class="login-card">
        <h2 style="text-align: center; color: #008C45; font-weight: 800;">🐾 OBERON System</h2>
        <p style="text-align: center; margin-bottom: 2rem; color: #666;">Wymagana autoryzacja do Bastionu Gorzów.</p>
        <?php if (!empty($login_error)) echo '<div class="error">' . htmlspecialchars($login_error) . '</div>'; ?>
        <form method="POST">
            <input type="hidden" name="action" value="login">
            <input type="password" name="password" placeholder="Hasło Pancernej Bramy" required autofocus>
            <button type="submit">Wejdź</button>
        </form>
    </div>
</body>
</html>
<?php
    exit;
}
?>
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Panel Administratora - Bastion Gorzów</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@1/css/pico.min.css">
    <link rel="stylesheet" href="assets/style.css">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
</head>
<body>
    <nav class="container-fluid" style="background-color: #ffffff; border-bottom: 1px solid #ddd;">
        <ul>
            <li><strong style="color: #008C45;">🐾 OBERON Master</strong></li>
        </ul>
        <ul>
            <li><a href="#" class="tab-link active" data-tab="system">⚙️ System</a></li>
            <li><a href="#" class="tab-link" data-tab="tiles">📱 Dashboard</a></li>
            <li><a href="#" class="tab-link" data-tab="poi">📍 Mapa POI</a></li>
            <li>
                <form method="POST" style="margin:0;">
                    <input type="hidden" name="action" value="logout">
                    <button type="submit" class="outline" style="padding: 0.2rem 0.5rem; margin-left: 1rem; color: #ff4757; border-color: #ff4757; font-size: 0.8rem;">Wyjdź</button>
                </form>
            </li>
        </ul>
    </nav>

    <main class="container">
        <!-- ZAKŁADKA: SYSTEM -->
        <section id="tab-system" class="admin-tab">
            <div class="card">
                <h3>⚙️ Konfiguracja Główna</h3>
                <form id="system-form">
                    <div class="grid">
                        <div>
                            <label for="app_name">Nazwa Aplikacji</label>
                            <input type="text" id="app_name" required>
                        </div>
                        <div>
                            <label for="primary_color">Kolor Główny</label>
                            <input type="color" id="primary_color" required style="height: 3.5rem; padding: 0;">
                        </div>
                    </div>
                    <div class="grid">
                        <div>
                            <label for="ota_version">Wersja OTA</label>
                            <input type="number" step="0.1" id="ota_version" required>
                        </div>
                        <div>
                            <label for="map_style">Styl Mapy (Voyager!)</label>
                            <select id="map_style">
                                <option value="voyager">CartoDB Voyager (Zalecany)</option>
                                <option value="light">Light (Jasna)</option>
                                <option value="dark">Dark (Ciemna)</option>
                                <option value="satellite">Satellite (Satelita)</option>
                            </select>
                        </div>
                    </div>
                    <label for="notification">Powiadomienie Globalne</label>
                    <input type="text" id="notification">
                    <button type="submit">Zapisz Zmiany Systemowe</button>
                </form>
            </div>
        </section>

        <!-- ZAKŁADKA: KAFELKI -->
        <section id="tab-tiles" class="admin-tab" style="display:none;">
            <div class="card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
                    <h3>📱 Ikony i Foldery</h3>
                    <button class="outline" id="btn-add-tile" style="width: auto;">+ Dodaj Nowy</button>
                </div>
                <div id="tiles-list"></div>
                <button id="btn-save-tiles" style="margin-top: 1.5rem;">Zaktualizuj Dashboard Aplikacji</button>
            </div>
        </section>

        <!-- ZAKŁADKA: MAPA POI -->
        <section id="tab-poi" class="admin-tab" style="display:none;">
            <div class="card">
                <h3>📍 Zarządzanie Punktami POI</h3>
                <div class="grid">
                    <div>
                        <label for="poi-category-select">Wybierz Kategorię</label>
                        <select id="poi-category-select">
                            <option value="">-- Wybierz lub stwórz --</option>
                        </select>
                    </div>
                    <div style="display: flex; align-items: flex-end;">
                        <button class="outline" id="btn-new-poi-category" style="margin-bottom: var(--spacing);">Nowa Kategoria</button>
                    </div>
                </div>
                
                <hr>
                
                <div id="poi-editor-container" style="display:none;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                        <h4 id="current-poi-title">Edycja: </h4>
                        <button class="secondary" id="btn-import-poi" style="font-size: 0.8rem; width: auto;">Importuj JSON</button>
                    </div>
                    
                    <div id="admin-map" style="height: 300px; border-radius: 12px; margin-bottom: 1.5rem; border: 1px solid #ddd;"></div>
                    
                    <div id="poi-points-list">
                        <!-- Lista punktów w danej kategorii -->
                    </div>
                    
                    <button id="btn-save-poi" style="margin-top: 1.5rem;">Zapisz Kategorię na Serwerze</button>
                </div>
            </div>
        </section>
    </main>

    <!-- Modal Nowa Kategoria -->
    <dialog id="new-cat-modal">
        <article>
            <header>
                <a href="#close" aria-label="Close" class="close" id="btn-close-cat-modal"></a>
                <h3>Nowa Kategoria POI</h3>
            </header>
            <input type="text" id="new-cat-name" placeholder="np. defibrylatory">
            <footer>
                <button class="secondary" id="btn-cancel-cat-modal">Anuluj</button>
                <button id="btn-confirm-cat-modal">Stwórz</button>
            </footer>
        </article>
    </dialog>

    <!-- Modal edycji kafelka -->
    <dialog id="tile-modal">
        <article>
            <header>
                <a href="#close" aria-label="Close" class="close" id="btn-close-modal"></a>
                <h3 id="modal-title">Edytuj Kafelek</h3>
            </header>
            <form id="tile-form">
                <input type="hidden" id="tile-index">
                <label for="tile-id">ID Kafelka (np. pogoda)</label>
                <input type="text" id="tile-id" required>

                <div class="grid">
                    <div>
                        <label for="tile-type">Typ</label>
                        <select id="tile-type" required>
                            <option value="web">Web (Link)</option>
                            <option value="folder">📂 Folder</option>
                            <option value="live">Live (Pogoda)</option>
                            <option value="map">Map (POI)</option>
                            <option value="app_link">App Link</option>
                        </select>
                    </div>
                    <div>
                        <label for="tile-size">Rozmiar</label>
                        <select id="tile-size" required>
                            <option value="1x1">1x1 (Mały)</option>
                            <option value="2x2">2x2 (Średni)</option>
                            <option value="4x2">4x2 (Duży / Baner)</option>
                        </select>
                    </div>
                </div>

                <label for="tile-parent-id">ID Rodzica (zostaw puste dla Dashboardu)</label>
                <input type="text" id="tile-parent-id" placeholder="np. folder_miejski">

                <label for="tile-title">Tytuł</label>
                <input type="text" id="tile-title" required>

                <label for="tile-icon">Ikona (Material Icons)</label>
                <input type="text" id="tile-icon" placeholder="np. newspaper">

                <div id="field-url" class="dynamic-field">
                    <label for="tile-url">URL</label>
                    <input type="url" id="tile-url">
                </div>

                <div id="field-kind" class="dynamic-field" style="display:none;">
                    <label for="tile-kind">Kind (dla live)</label>
                    <input type="text" id="tile-kind" placeholder="np. weather">
                </div>
                
                <div id="field-data-url" class="dynamic-field" style="display:none;">
                    <label for="tile-data-url">Data URL (dla map)</label>
                    <input type="text" id="tile-data-url" placeholder="np. dane/poi.json">
                </div>

                <footer>
                    <a href="#cancel" role="button" class="secondary" id="btn-cancel-modal">Anuluj</a>
                    <button type="submit" id="btn-save-modal">Zatwierdź</button>
                </footer>
            </form>
        </article>
    </dialog>

    <script src="assets/app.js"></script>
</body>
</html>