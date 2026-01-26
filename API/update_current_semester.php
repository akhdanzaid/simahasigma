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
$new_semester = $_POST['semester_saat_ini'];

// Perbarui profil
$sql1 = "UPDATE users SET semester_saat_ini = '$new_semester' WHERE id = '$user_id'";
$conn->query($sql1);

// Arsipkan jadwal lama
$sql2 = "UPDATE schedules SET diarsipkan = 1 WHERE user_id = '$user_id' AND semester < '$new_semester'";
$conn->query($sql2);

// Kirim respon balik ke Flutter
echo json_encode(["success" => true, "message" => "Semester diperbarui & jadwal lama diarsipkan"]);
?>