<?php
include 'db.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}
header("Content-Type: application/json");

$user_id = $_POST['user_id'] ?? 1;

// Urutkan berdasarkan 'disematkan' (descending) lalu 'created_at' (terbaru)
$sql = "SELECT * FROM notes WHERE user_id = '$user_id' ORDER BY disematkan DESC, created_at DESC";
$result = $conn->query($sql);

$data = array();
while ($row = $result->fetch_assoc()) {
    // Konversi boolean
    $row['disematkan'] = $row['disematkan'] == 1;
    $data[] = $row;
}

echo json_encode($data);
?>