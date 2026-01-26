<?php
include 'db.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}
header("Content-Type: application/json");

$id = $_POST['id'];
$rawStatus = $_POST['status']; 

// Logika: '0' = Pulihkan (Aktif), '1' = Arsipkan
$status = ($rawStatus == '0') ? 0 : 1;
$today = date('Y-m-d');

if ($status == 0) {
    // Jika dipulihkan, reset tgl_mulai ke hari ini
    $sql = "UPDATE schedules SET diarsipkan = 0, tgl_mulai = '$today' WHERE id = '$id'";
} else {
    $sql = "UPDATE schedules SET diarsipkan = 1 WHERE id = '$id'";
}

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true, "new_status" => $status]);
} else {
    echo json_encode(["success" => false, "message" => $conn->error]);
}
?>