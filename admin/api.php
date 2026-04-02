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
$poiDir = __DIR__ . '/../dane/poi/';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($action === 'get_tiles') {
        if (file_exists($tilesPath)) echo file_get_contents($tilesPath);
        else echo json_encode(['tiles' => []]);
    } elseif ($action === 'get_system') {
        if (file_exists($systemPath)) echo file_get_contents($systemPath);
        else echo json_encode([]);
    } elseif ($action === 'list_poi_categories') {
        $files = glob($poiDir . "*.json");
        $categories = array_map(function($f) { return basename($f, ".json"); }, $files);
        echo json_encode(['categories' => $categories]);
    } elseif ($action === 'get_poi_category') {
        $cat = $_GET['category'] ?? '';
        $path = $poiDir . $cat . ".json";
        if (file_exists($path)) echo file_get_contents($path);
        else echo json_encode(['points' => []]);
    } else {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if ($action === 'save_tiles') {
        if (isset($input['tiles'])) {
            $jsonData = json_encode(['tiles' => $input['tiles']], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            if (file_put_contents($tilesPath, $jsonData, LOCK_EX)) echo json_encode(['success' => true]);
            else { http_response_code(500); echo json_encode(['error' => 'Failed to write tiles.json']); }
        }
    } elseif ($action === 'save_system') {
        $jsonData = json_encode($input, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if (file_put_contents($systemPath, $jsonData, LOCK_EX)) echo json_encode(['success' => true]);
        else { http_response_code(500); echo json_encode(['error' => 'Failed to write system.json']); }
    } elseif ($action === 'save_poi_category') {
        $cat = $_GET['category'] ?? '';
        if (!$cat) { http_response_code(400); echo json_encode(['error' => 'No category specified']); exit; }
        $path = $poiDir . $cat . ".json";
        $jsonData = json_encode($input, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if (file_put_contents($path, $jsonData, LOCK_EX)) echo json_encode(['success' => true]);
        else { http_response_code(500); echo json_encode(['error' => 'Failed to write ' . $cat . '.json']); }
    } else {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
    }
}
?>