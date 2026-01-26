<?php
error_reporting(0); 
date_default_timezone_set('Asia/Jakarta');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "ujat7577_dann";
$password = "akhdan05";
$dbname = "ujat7577_simahasigma"; 
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    // Kirim JSON error, JANGAN die("teks")
    echo json_encode(["error" => "Koneksi Database Gagal: " . $conn->connect_error]);
    exit();
}