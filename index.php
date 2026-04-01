<?php
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Cache-Control: post-check=0, pre-check=0', false);
header('Pragma: no-cache');
// Pancerny wykrywacz najnowszej wersji dla Bastionu Gorzow v2.2 🐾📡
$system_path = 'dane/system.json';
$version = '2.0'; 
$apk_url = '';

if (file_exists($system_path)) {
    $system = json_decode(file_get_contents($system_path), true);
    $version = $system['ota_version'] ?? $version;
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
        :root { --primary: #008C45; --bg: #000000; --text: #ffffff; }
        body { font-family: 'Ubuntu', sans-serif; background: var(--bg); color: var(--text); margin: 0; display: flex; align-items: center; justify-content: center; min-height: 100vh; text-align: center; }
        .container { background: #111; padding: 3rem; border-radius: 20px; border: 1px solid #333; max-width: 500px; width: 90%; }
        .icon-box { background: rgba(0,140,69,0.2); width: 100px; height: 100px; border-radius: 10px; margin: 0 auto 2rem; display: flex; align-items: center; justify-content: center; }
        img { width: 60px; }
        h1 { font-weight: 900; margin-bottom: 0.5rem; font-size: 2.5rem; color: var(--primary); }
        p { color: #888; margin-bottom: 2rem; }
        .btn { background: var(--primary); color: white; padding: 1.2rem 3rem; border-radius: 5px; text-decoration: none; font-weight: bold; display: inline-block; transition: transform 0.2s; text-transform: uppercase; letter-spacing: 1px; }
        .btn:hover { transform: scale(1.05); background: #00a852; }
        .footer { margin-top: 3rem; font-size: 0.7rem; color: #444; text-transform: uppercase; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon-box">
            <img src="assets/icon_gorzow.svg" alt="Gorzow Icon">
        </div>
        <h1>Gorzow v<?php echo $version; ?></h1>
        <p>Nowoczesny kafelkowy bastion Twojego miasta. Edycja Windows Phone Style.</p>
        <a href="<?php echo $apk_url; ?>" class="btn">Pobierz APK 🚀</a>
        <div class="footer">System OBERON & Alfred 🐾✨</div>
    </div>
</body>
</html>
