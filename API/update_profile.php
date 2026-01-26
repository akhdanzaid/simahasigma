<?php
ob_start(); // Buffer output untuk mencegah whitespace liar
include 'db.php';
error_reporting(0); // Matikan error warning agar tidak merusak JSON
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}
header("Content-Type: application/json");

// --- 1. TERIMA INPUT DARI FLUTTER ---
$user_id          = $_POST['user_id'] ?? '';
$nama             = $_POST['nama_lengkap'] ?? '';
$jurusan          = $_POST['jurusan'] ?? '';
// Pastikan key ini sama dengan yang dikirim Flutter ('current_password' & 'new_password')
$current_password = $_POST['current_password'] ?? ''; 
$new_password     = $_POST['new_password'] ?? '';     

// Validasi dasar
if (empty($user_id)) {
    ob_clean();
    echo json_encode(["success" => false, "message" => "User ID tidak ditemukan"]);
    exit;
}

// --- 2. AMBIL DATA USER SAAT INI DARI DB ---
// Kita butuh password lama yang tersimpan di DB untuk verifikasi
$sql_check = "SELECT password FROM users WHERE id = '$user_id'";
$result = $conn->query($sql_check);

if ($result->num_rows == 0) {
    ob_clean();
    echo json_encode(["success" => false, "message" => "User tidak ditemukan"]);
    exit;
}

$user_data = $result->fetch_assoc();
$db_password = $user_data['password']; // Hash password yang tersimpan di database

// --- 3. LOGIKA VALIDASI PASSWORD (INTI PERBAIKAN) ---
$update_pass_sql = ""; // String tambahan query jika password berubah

// Jika user mengirimkan password baru...
if (!empty($new_password)) {
    
    // VALIDASI A: Apakah password lama dikirim?
    if (empty($current_password)) {
        ob_clean();
        echo json_encode(["success" => false, "message" => "Password lama wajib diisi!"]);
        exit;
    }

    // VALIDASI B: Apakah password lama SESUAI dengan database?
    // Karena Flutter mengirim hash SHA256, dan DB menyimpan hash, kita bisa bandingkan langsung string-nya
    if ($current_password !== $db_password) {
        ob_clean();
        echo json_encode(["success" => false, "message" => "Password lama Anda salah!"]);
        exit;
    }

    // VALIDASI C: Apakah password baru SAMA dengan password lama?
    if ($new_password === $db_password) {
        ob_clean();
        echo json_encode(["success" => false, "message" => "Password baru tidak boleh sama dengan password lama!"]);
        exit;
    }

    // Jika lolos semua validasi, siapkan query update password
    $update_pass_sql = ", password = '$new_password'";
}

// --- 4. EKSEKUSI UPDATE DATA TEKS ---
// Kita gabungkan update nama, jurusan, dan password (jika ada)
$sql = "UPDATE users SET nama_lengkap = '$nama', jurusan = '$jurusan' $update_pass_sql WHERE id = '$user_id'";

if ($conn->query($sql) === TRUE) {
    // Lanjut ke upload foto (jika ada)
} else {
    ob_clean();
    echo json_encode(["success" => false, "message" => "Gagal update database: " . $conn->error]);
    exit;
}

// --- 5. HANDLE UPLOAD FOTO ---
if (isset($_FILES['foto_profil']) && $_FILES['foto_profil']['error'] == 0) {
    $target_dir = "uploads/";
    if (!file_exists($target_dir)) {
        mkdir($target_dir, 0777, true);
    }

    $file_extension = pathinfo($_FILES["foto_profil"]["name"], PATHINFO_EXTENSION);
    $new_filename = "profile_" . $user_id . "_" . time() . "." . $file_extension;
    $target_file = $target_dir . $new_filename;

    if (move_uploaded_file($_FILES["foto_profil"]["tmp_name"], $target_file)) {
        $sql_foto = "UPDATE users SET foto_profil = '$new_filename' WHERE id = '$user_id'";
        $conn->query($sql_foto);
    }
}

ob_clean();
echo json_encode(["success" => true, "message" => "Profil berhasil diperbarui"]);
?>