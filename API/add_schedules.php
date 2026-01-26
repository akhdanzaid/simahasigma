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
$subject = $_POST['mata_kuliah'];
$lecturer = $_POST['dosen'];
$room = $_POST['ruangan'];
$day = $_POST['hari'];
$start = $_POST['jam_mulai'];
$end = $_POST['jam_selesai'];
$type = $_POST['jenis_kelas'];
// Field Baru
$semester = $_POST['semester'];
$startDate = $_POST['tgl_mulai']; // Format YYYY-MM-DD

if (isset($_POST['id']) && !empty($_POST['id'])) {
    $id = $_POST['id'];
    $sql = "UPDATE schedules SET 
            mata_kuliah='$subject', dosen='$lecturer', ruangan='$room', 
            hari='$day', jam_mulai='$start', jam_selesai='$end', 
            jenis_kelas='$type', semester='$semester', tgl_mulai='$startDate' 
            WHERE id='$id'";
} else {
    $sql = "INSERT INTO schedules 
            (user_id, mata_kuliah, dosen, ruangan, hari, jam_mulai, jam_selesai, jenis_kelas, semester, tgl_mulai, diarsipkan) 
            VALUES 
            ('$user_id', '$subject', '$lecturer', '$room', '$day', '$start', '$end', '$type', '$semester', '$startDate', 0)";
}

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => $conn->error]);
}
?>