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
</head>
<body>
    <nav class="container-fluid" style="background-color: #222; border-bottom: 2px solid #008C45;">
        <ul>
            <li><strong style="color: #008C45;">🐾 OBERON Admin</strong></li>
        </ul>
        <ul>
            <li><a href="#system" class="contrast">System</a></li>
            <li><a href="#tiles" class="contrast">Kafelki</a></li>
            <li>
                <form method="POST" style="margin:0;">
                    <input type="hidden" name="action" value="logout">
                    <button type="submit" class="outline" style="padding: 0.2rem 0.5rem; margin-left: 1rem; color: #ff5252; border-color: #ff5252;">Wyloguj</button>
                </form>
            </li>
        </ul>
    </nav>

    <main class="container">
        <!-- SEKCJA: SYSTEM -->
        <section id="system">
            <h3>⚙️ Ustawienia Systemu</h3>
            <div class="card" id="system-form-container">
                <form id="system-form">
                    <div class="grid">
                        <div>
                            <label for="app_name">Nazwa Aplikacji</label>
                            <input type="text" id="app_name" required>
                        </div>
                        <div>
                            <label for="primary_color">Kolor Główny (HEX)</label>
                            <input type="color" id="primary_color" required style="height: 3.5rem; padding: 0;">
                        </div>
                        <div>
                            <label for="ota_version">Wersja OTA</label>
                            <input type="number" step="0.1" id="ota_version" required>
                        </div>
                    </div>
                    <label for="notification">Powiadomienie</label>
                    <input type="text" id="notification">
                    <button type="submit">Zapisz System</button>
                </form>
            </div>
        </section>

        <hr>

        <!-- SEKCJA: KAFELKI -->
        <section id="tiles">
            <h3>🗂️ Zarządzanie Kafelkami</h3>
            <button class="outline" id="btn-add-tile" style="margin-bottom: 1rem;">+ Dodaj Kafelek</button>
            <div id="tiles-list">
                <!-- Kafelki ładowane przez JS -->
            </div>
            <button id="btn-save-tiles" style="margin-top: 1rem;">Zapisz Kafelki</button>
        </section>
    </main>

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