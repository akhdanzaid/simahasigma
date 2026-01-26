<?php
error_reporting(0);
include 'db.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}

// Menghapus output buffer agar benar-benar hanya JSON yang terkirim
ob_clean(); 
header("Content-Type: application/json");

$user_id = $_POST['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(["success" => false, "message" => "ID User tidak ditemukan"]);
    exit;
}

// Query mengambil field 'semester_saat_ini' sesuai simahasigma_db.sql
$sql = "SELECT nama_lengkap, jurusan, semester_saat_ini, foto_profil FROM users WHERE id = '$user_id'";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    if ($row['foto_profil']) {
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $host = $_SERVER['HTTP_HOST'];
        // Mengambil path folder tempat file ini berada secara otomatis
        $path = str_replace(basename($_SERVER['SCRIPT_NAME']), "", $_SERVER['SCRIPT_NAME']);
        $base_url = $protocol . "://" . $host . $path;
        
        $row['foto_url'] = $base_url . "uploads/" . $row['foto_profil'];
    } else {
        $row['foto_url'] = null;
    }

    echo json_encode([
        "success" => true,
        "data" => $row
    ]);
} else {
    echo json_encode(["success" => false, "message" => "User ID $user_id tidak ditemukan"]);
}
?>