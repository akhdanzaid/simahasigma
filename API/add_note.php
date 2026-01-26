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
$title = $_POST['judul'];
$content = $_POST['isi'];
$color = $_POST['kode_warna'] ?? '0xFFFFF59D'; // Default Kuning

if (isset($_POST['id']) && !empty($_POST['id'])) {
    // MODE EDIT
    $id = $_POST['id'];
    $sql = "UPDATE notes SET judul='$title', isi='$content', kode_warna='$color' WHERE id='$id'";
} else {
    // MODE TAMBAH BARU
    $sql = "INSERT INTO notes (user_id, judul, isi, kode_warna) VALUES ('$user_id', '$title', '$content', '$color')";
}

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true, "message" => "Catatan disimpan"]);
} else {
    echo json_encode(["success" => false, "message" => $conn->error]);
}
?>