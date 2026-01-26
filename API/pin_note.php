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
// Menerima status baru (true/1 atau false/0)
$status = ($_POST['pin_status'] === 'true' || $_POST['pin_status'] === '1') ? 1 : 0;

$sql = "UPDATE notes SET disematkan='$status' WHERE id='$id'";

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => $conn->error]);
}
?>