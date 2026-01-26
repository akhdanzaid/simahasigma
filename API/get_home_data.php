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
$hari_ini = date('N'); 
$nama_hari = ["", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"][$hari_ini];
$now_time = date('H:i:s');

// 1. Ambil Nama, Semester, dan Foto Profil (DIPERBAIKI)
// Tambahkan nama_lengkap di SELECT
$userQuery = "SELECT nama_lengkap, semester_saat_ini, foto_profil FROM users WHERE id = '$user_id'";
$userResult = $conn->query($userQuery);
$userData = $userResult->fetch_assoc();

// Isi variabel nama_user dari hasil query (DIPERBAIKI)
$nama_user = $userData['nama_lengkap'] ?? "User";

// Konstruksi URL foto profil
$foto_url = null;
if (!empty($userData['foto_profil'])) {
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
    $host = $_SERVER['HTTP_HOST'];
    $path = str_replace(basename($_SERVER['SCRIPT_NAME']), "", $_SERVER['SCRIPT_NAME']);
    $base_url = $protocol . "://" . $host . $path;
    $foto_url = $base_url . "uploads/" . $userData['foto_profil'];
}

$subjectQuery = "SELECT COUNT(*) as total FROM schedules WHERE user_id = '$user_id' AND diarsipkan = 0";
$totalMatkul = $conn->query($subjectQuery)->fetch_assoc()['total'];

// 2. LOGIKA KELAS (TETAP SAMA)
$sqlToday = "SELECT * FROM schedules WHERE user_id = '$user_id' AND hari = '$nama_hari' AND diarsipkan = 0 ORDER BY jam_mulai ASC";
$resToday = $conn->query($sqlToday);
$all_today = [];
while($row = $resToday->fetch_assoc()) { $all_today[] = $row; }

$current_class = null;
$next_class = null;
$prev_class = null;
$countdown = 0;

foreach ($all_today as $index => $class) {
    if ($now_time >= $class['jam_mulai'] && $now_time <= $class['jam_selesai']) {
        $current_class = $class;
    }
    if ($now_time < $class['jam_mulai']) {
        $next_class = $class;
        $prev_class = ($index > 0) ? $all_today[$index - 1] : null;
        break;
    }
}

// 3. LOGIKA COUNTDOWN (TETAP SAMA)
if ($next_class) {
    $start_time = strtotime($next_class['jam_mulai']);
    $now_timestamp = strtotime($now_time);
    if ($prev_class) {
        $prev_end_time = strtotime($prev_class['jam_selesai']);
        if ($now_timestamp >= $prev_end_time) { $countdown = $start_time - $now_timestamp; }
    } else {
        if (($start_time - $now_timestamp) <= 1800) { $countdown = $start_time - $now_timestamp; }
    }
}

// 4. AMBIL TUGAS (TETAP SAMA)
$sqlTasks = "SELECT *, (CASE WHEN diarsipkan = 1 THEN 'done' WHEN tenggat_waktu < NOW() THEN 'expired' WHEN mendesak = 1 OR (tenggat_waktu > NOW() AND tenggat_waktu <= DATE_ADD(NOW(), INTERVAL 48 HOUR)) THEN 'urgent' ELSE 'normal' END) as status_server FROM tasks WHERE user_id = '$user_id' ORDER BY tenggat_waktu ASC";
$tasks = [];
$resTasks = $conn->query($sqlTasks);
while($row = $resTasks->fetch_assoc()) {
    $row['diarsipkan'] = ($row['diarsipkan'] == 1);
    $row['mendesak'] = ($row['mendesak'] == 1);
    $tasks[] = $row;
}

// Output JSON 
echo json_encode([
    "success" => true,
    "nama" => $nama_user, // Sekarang variabel ini sudah ada isinya
    "semester" => (int)$userData['semester_saat_ini'],
    "total_matkul" => (int)$totalMatkul,
    "foto_url" => $foto_url,
    "current_class" => $current_class,
    "next_class" => $next_class,
    "countdown_sec" => ($countdown > 0) ? $countdown : 0,
    "tasks" => $tasks
]);