<?php
include 'db.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}
header("Content-Type: application/json");

$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? ''; // Hash dari Flutter

$sql = "SELECT id, nama_lengkap, password FROM users WHERE email = '$email'";
$result = $conn->query($sql);

if($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    // Bandingkan password hash
    if($password === $user['password']) {
        echo json_encode([
            "success" => true,
            "user_id" => (int)$user['id'],
            "nama" => $user['nama_lengkap'],
            "message" => "Login berhasil"
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Password salah"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Email tidak terdaftar"]);
}
?>