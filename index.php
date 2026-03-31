<?php
// Pancerny wykrywacz najnowszej wersji dla Bastionu Gorzow v1.0 🐾📡
$manifest_path = 'wersje/manifest.json';
$version = '1.0'; 
$apk_url = '';

if (file_exists($manifest_path)) {
    $manifest = json_decode(file_get_contents($manifest_path), true);
    $version = $manifest['app_config']['ota_version'] ?? $version;
}

$files = glob("wersje/*.apk");
if (!empty($files)) {
    usort($files, function($a, $b) { return filemtime($b) - filemtime($a); });
    $apk_url = $files[0];
} else {
    $apk_url = "wersje/gorzow_v" . $version . ".apk";
}
?>
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gorzow - Cyfrowy Bastion</title>
    <link href="https://fonts.googleapis.com/css2?family=Ubuntu:wght@300;400;700&display=swap" rel="stylesheet">
    <style>
        :root { --primary: #008C45; --bg: #f8fafc; --text: #1e293b; }
        body { font-family: 'Ubuntu', sans-serif; background: var(--bg); color: var(--text); margin: 0; display: flex; align-items: center; justify-content: center; min-height: 100vh; text-align: center; }
        .container { background: white; padding: 3rem; border-radius: 50px; box-shadow: 0 20px 50px rgba(0,0,0,0.05); max-width: 500px; width: 90%; }
        .icon-box { background: rgba(0,140,69,0.1); width: 120px; height: 120px; border-radius: 40px; margin: 0 auto 2rem; display: flex; align-items: center; justify-content: center; }
        img { width: 80px; }
        h1 { font-weight: 900; margin-bottom: 0.5rem; font-size: 2.5rem; color: var(--primary); }
        p { color: #64748b; margin-bottom: 2rem; }
        .btn { background: var(--primary); color: white; padding: 1rem 2.5rem; border-radius: 25px; text-decoration: none; font-weight: bold; display: inline-block; transition: transform 0.2s; box-shadow: 0 10px 20px rgba(0,140,69,0.2); }
        .btn:hover { transform: translateY(-3px); }
        .footer { margin-top: 3rem; font-size: 0.8rem; color: #94a3b8; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon-box">
            <img src="assets/icon_gorzow.svg" alt="Gorzow Icon" onerror="this.src='https://cdn-icons-png.flaticon.com/512/684/684908.png'">
        </div>
        <h1>Gorzow v<?php echo $version; ?></h1>
        <p>Twój nowoczesny bastion miasta. Lekka i zawsze aktualna aplikacja dla mieszkańców Gorzowa.</p>
        <a href="<?php echo $apk_url; ?>" class="btn">POBIERZ APK 🚀</a>
        <div class="footer">System OBERON & Alfred 🐾✨</div>
    </div>
</body>
</html>
