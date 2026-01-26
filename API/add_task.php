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


$user_id = $_POST['user_id'] ?? 1;
$title = $_POST['judul_tugas'];
$subject = $_POST['mata_kuliah'];
$desc = $_POST['deskripsi'] ?? '';
$deadline = $_POST['tenggat_waktu'];
$link = $_POST['link_pengumpulan'] ?? '';
// Terima mendesak sebagai 1 atau 0
$is_urgent = ($_POST['mendesak'] == 'true' || $_POST['mendesak'] == '1') ? 1 : 0;

if (isset($_POST['id']) && !empty($_POST['id'])) {
    // --- MODE EDIT ---
    $id = $_POST['id'];
    $sql = "UPDATE tasks SET 
            judul_tugas='$title', 
            mata_kuliah='$subject', 
            deskripsi='$desc', 
            tenggat_waktu='$deadline', 
            link_pengumpulan='$link', 
            mendesak='$is_urgent' 
            WHERE id='$id'";
} else {
    // --- MODE TAMBAH BARU ---
    $sql = "INSERT INTO tasks (user_id, judul_tugas, mata_kuliah, deskripsi, tenggat_waktu, link_pengumpulan, mendesak, diarsipkan) 
            VALUES ('$user_id', '$title', '$subject', '$desc', '$deadline', '$link', '$is_urgent', 0)";
}

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true, "message" => "Berhasil disimpan"]);
} else {
    echo json_encode(["success" => false, "message" => "Gagal SQL: " . $conn->error]);
}
?>