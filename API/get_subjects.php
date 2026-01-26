<?php
error_reporting(0);
include 'db.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}
header("Content-Type: application/json; charset=UTF-8");

$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : 0;

if ($user_id == 0) {
    echo json_encode([]); // Kembalikan array kosong jika ID tidak valid
    exit;
}

$data = [];
// Pastikan hanya mengambil matkul yang aktif (tidak diarsipkan) milik user tersebut
$sql = "SELECT DISTINCT mata_kuliah FROM schedules 
        WHERE user_id = '$user_id' AND diarsipkan = 0 
        ORDER BY mata_kuliah ASC";

$result = $conn->query($sql);
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $data[] = $row['mata_kuliah'];
    }
}
echo json_encode($data);
?>