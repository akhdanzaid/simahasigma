<?php
include 'db.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}
header("Content-Type: application/json; charset=UTF-8");

$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : 1;

// trim() untuk menghapus spasi di depan/belakang
// Jika kosong atau null, paksa jadi 'Semua'
$subject_filter = isset($_POST['subject']) ? trim($_POST['subject']) : 'Semua';
if (empty($subject_filter) || $subject_filter == 'null') {
    $subject_filter = 'Semua';
}

$data = [];

// LOGIKA OTOMATIS SERVER:
// 1. DONE: Jika diarsipkan = 1 (Manual user check selesai)
// 2. EXPIRED/GAGAL: Jika waktu sekarang > tenggat waktu (Otomatis masuk riwayat gagal)
// 3. URGENT: Jika user tandai mendesak ATAU waktu tinggal < 2 hari (48 jam)
// 4. NORMAL: Sisanya

$sql = "SELECT *,
    (CASE 
        WHEN diarsipkan = 1 THEN 'done'
        WHEN tenggat_waktu < NOW() THEN 'expired' 
        WHEN mendesak = 1 OR (tenggat_waktu > NOW() AND tenggat_waktu <= DATE_ADD(NOW(), INTERVAL 48 HOUR)) THEN 'urgent'
        ELSE 'normal'
    END) as status_server
FROM tasks 
WHERE user_id = '$user_id'";

// Logika Filter 
if ($subject_filter !== 'Semua') {
    $safe_subject = $conn->real_escape_string($subject_filter);
    $sql .= " AND mata_kuliah = '$safe_subject'";
}

// Secondary Sort
// Jika deadline sama, urutkan berdasarkan ID
$sql .= " ORDER BY tenggat_waktu ASC, id DESC";

$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // Konversi boolean
        $row['diarsipkan'] = ($row['diarsipkan'] == 1);
        $row['mendesak'] = ($row['mendesak'] == 1);
        $data[] = $row;
    }
}

echo json_encode($data);
?>