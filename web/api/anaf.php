<?php
// CORS Headers allowing secure browser access from Agreemint Web App
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Extract and sanitize CUI from query parameter or POST body
$rawCui = '';
if (isset($_GET['cui'])) {
    $rawCui = $_GET['cui'];
} else {
    $input = file_get_contents('php://input');
    $decoded = json_decode($input, true);
    if (is_array($decoded) && isset($decoded['cui'])) {
        $rawCui = $decoded['cui'];
    }
}

$cleanCui = preg_replace('/\D/', '', (string)$rawCui);
if (empty($cleanCui) || strlen($cleanCui) < 2 || strlen($cleanCui) > 10) {
    http_response_code(400);
    echo json_encode([
        'error' => 'CUI invalid. Introduceți un cod fiscal numeric între 2 și 10 cifre.'
    ]);
    exit;
}

$cuiInt = (int)$cleanCui;
$today = date('Y-m-d');
$payload = json_encode([
    [
        'cui' => $cuiInt,
        'data' => $today
    ]
]);

$ch = curl_init('https://webservicesp.anaf.ro/api/PlatitorTvaRest/v9/tva');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
curl_setopt($ch, CURLOPT_TIMEOUT, 12);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

if ($response === false || $httpCode !== 200) {
    http_response_code($httpCode ?: 502);
    echo json_encode([
        'error' => 'Nu s-a putut contacta serverul ANAF: ' . ($curlError ?: 'HTTP ' . $httpCode)
    ]);
    exit;
}

echo $response;
