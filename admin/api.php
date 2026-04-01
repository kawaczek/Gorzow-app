<?php
require_once 'auth.php';

header('Content-Type: application/json');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Cache-Control: post-check=0, pre-check=0', false);
header('Pragma: no-cache');

if (!checkAuth()) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

$action = $_GET['action'] ?? '';
$tilesPath = __DIR__ . '/../dane/tiles.json';
$systemPath = __DIR__ . '/../dane/system.json';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($action === 'get_tiles') {
        if (file_exists($tilesPath)) {
            echo file_get_contents($tilesPath);
        } else {
            echo json_encode(['tiles' => []]);
        }
    } elseif ($action === 'get_system') {
        if (file_exists($systemPath)) {
            echo file_get_contents($systemPath);
        } else {
            echo json_encode([]);
        }
    } else {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if ($action === 'save_tiles') {
        if (isset($input['tiles'])) {
            $jsonData = json_encode(['tiles' => $input['tiles']], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            if (file_put_contents($tilesPath, $jsonData, LOCK_EX)) {
                echo json_encode(['success' => true]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to write tiles.json']);
            }
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid data format']);
        }
    } elseif ($action === 'save_system') {
        if ($input) {
            $jsonData = json_encode($input, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            if (file_put_contents($systemPath, $jsonData, LOCK_EX)) {
                echo json_encode(['success' => true]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to write system.json']);
            }
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid data format']);
        }
    } else {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
    }
}
?>