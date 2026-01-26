<?php
include 'db.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}
header("Content-Type: application/json");

$nama = $_POST['nama_lengkap'] ?? '';
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? ''; // Diterima dalam bentuk Hash dari Flutter

if(empty($nama) || empty($email) || empty($password)) {
    echo json_encode(["success" => false, "message" => "Semua data wajib diisi"]);
    exit;
}

// Cek email duplikat
$check = "SELECT id FROM users WHERE email = '$email'";
$res = $conn->query($check);

if($res->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Email sudah digunakan"]);
} else {
    // Insert data user baru
    $sql = "INSERT INTO users (nama_lengkap, email, password, semester_saat_ini) VALUES ('$nama', '$email', '$password', 1)";
    if($conn->query($sql)) {
        echo json_encode(["success" => true, "message" => "Registrasi berhasil"]);
    } else {
        echo json_encode(["success" => false, "message" => "Gagal menyimpan data"]);
    }
}
?>