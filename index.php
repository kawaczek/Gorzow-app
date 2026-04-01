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
        :root { --primary: #008C45; --bg: #f8f9fa; --text: #333333; }
        body { font-family: 'Ubuntu', sans-serif; background: var(--bg); color: var(--text); margin: 0; display: flex; align-items: center; justify-content: center; min-height: 100vh; text-align: center; }
        .container { background: #ffffff; padding: 3rem; border-radius: 32px; box-shadow: 0 10px 40px rgba(0,0,0,0.05); max-width: 500px; width: 90%; border: 1px solid #eee; }
        .icon-box { background: rgba(0,140,69,0.05); width: 120px; height: 120px; border-radius: 30px; margin: 0 auto 2.5rem; display: flex; align-items: center; justify-content: center; }
        img { width: 70px; }
        h1 { font-weight: 900; margin-bottom: 0.5rem; font-size: 2.8rem; color: var(--primary); }
        p { color: #666; margin-bottom: 2.5rem; line-height: 1.6; }
        .btn { background: var(--primary); color: white; padding: 1.4rem 3.5rem; border-radius: 16px; text-decoration: none; font-weight: 800; display: inline-block; transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275); text-transform: uppercase; letter-spacing: 1px; box-shadow: 0 8px 25px rgba(0,140,69,0.25); }
        .btn:hover { transform: translateY(-5px); box-shadow: 0 15px 35px rgba(0,140,69,0.3); background: #00a852; }
        .footer { margin-top: 4rem; font-size: 0.75rem; color: #aaa; font-weight: 600; letter-spacing: 1px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon-box">
            <img src="assets/icon_gorzow.svg" alt="Gorzow Icon">
        </div>
        <h1>Gorzow v<?php echo $version; ?></h1>
        <p>Nowoczesny agregator Twojego miasta.<br>Edycja <strong>Modern Agregator 3.x</strong></p>
        
        <?php if (!empty($apk_url)): ?>
            <a href="<?php echo $apk_url; ?>" class="btn">Pobierz APK 🚀</a>
            <p style="margin-top: 1rem; font-size: 0.8rem; color: #555;">
                Ostatnia aktualizacja: <?php echo date("d.m.Y H:i", filemtime($apk_url)); ?>
            </p>
        <?php else: ?>
            <p style="color: #ff4757;">Brak dostępnych wersji APK 🐾</p>
        <?php endif; ?>

        <div class="footer">Alfred & Oberon | System v3.0 🐾✨</div>
    </div>
</body>
</html>
