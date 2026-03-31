<?php
session_start();

function getAdminPassword() {
    return 'Kawak123#'; // Hasło Pancernej Bramy
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
        $adminPass = getAdminPassword();

        if ($pass === $adminPass) {
            $_SESSION['logged_in'] = true;
            header('Location: index.php');
            exit;
        } else {
            $login_error = "Błędne hasło, Szefie! 🐾";
        }
    }
 elseif ($_POST['action'] === 'logout') {
        session_destroy();
        header('Location: index.php');
        exit;
    }
}
?>