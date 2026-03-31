<?php
session_start();

function getEnvVar($key) {
    $envPath = __DIR__ . '/../.env';
    if (!file_exists($envPath)) return null;
    $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        list($k, $v) = explode('=', $line, 2);
        if (trim($k) === $key) return trim($v);
    }
    return null;
}

function checkAuth() {
    if (!isset($_SESSION['logged_in']) || $_SESSION['logged_in'] !== true) {
        return false;
    }
    return true;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    if ($_POST['action'] === 'login') {
        $pass = $_POST['password'] ?? '';
        $adminPass = getEnvVar('ADMIN_PASSWORD');
        
        if ($pass === $adminPass) {
            $_SESSION['logged_in'] = true;
            header('Location: index.php');
            exit;
        } else {
            $login_error = "Błędne hasło, Szefie! 🐾";
        }
    } elseif ($_POST['action'] === 'logout') {
        session_destroy();
        header('Location: index.php');
        exit;
    }
}
?>