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
$is_archived = isset($_POST['is_archived']) ? $_POST['is_archived'] : 0;
$semester_filter = isset($_POST['semester']) ? $_POST['semester'] : 'Semua';

// --- LOGIKA OTOMATIS: AUTO-ARCHIVE ---
// Hanya mengarsipkan jika semester < semester_saat_ini ATAU sudah lewat 18 minggu (14 + (uts (2) + uas (2))
$conn->query("UPDATE schedules SET diarsipkan = 1 
              WHERE user_id = '$user_id' AND diarsipkan = 0 
              AND tgl_mulai IS NOT NULL 
              AND (DATE_ADD(tgl_mulai, INTERVAL 18 WEEK) < CURDATE())");

// --- AMBIL DATA ---
$sql = "SELECT * FROM schedules WHERE user_id = '$user_id' AND diarsipkan = '$is_archived'";

if ($is_archived == 1 && $semester_filter != 'Semua') {
    $sql .= " AND semester = '$semester_filter'";
}

$sql .= " ORDER BY jam_mulai ASC";
$result = $conn->query($sql);
$data = [];
while ($row = $result->fetch_assoc()) { $data[] = $row; }
echo json_encode($data);
?>