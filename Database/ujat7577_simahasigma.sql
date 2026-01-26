-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jan 22, 2026 at 10:02 PM
-- Server version: 11.4.9-MariaDB-cll-lve
-- PHP Version: 8.4.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `ujat7577_simahasigma`
--

-- --------------------------------------------------------

--
-- Table structure for table `notes`
--

CREATE TABLE `notes` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `judul` varchar(150) NOT NULL,
  `isi` text NOT NULL,
  `kode_warna` varchar(20) DEFAULT '0xFFFFF59D',
  `disematkan` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `notes`
--

INSERT INTO `notes` (`id`, `user_id`, `judul`, `isi`, `kode_warna`, `disematkan`, `created_at`, `updated_at`) VALUES
(1, 1, 'Tugas Project', 'Membuat aplikasi flutter android', '4289058471', 1, '2026-01-17 17:36:54', '2026-01-17 18:10:49'),
(2, 1, 'Traveling', 'Liburan jalan-jalan ke dieng', '4287679225', 0, '2026-01-17 18:11:20', '2026-01-22 19:31:51'),
(3, 2, 'TEST', 'testing aplikasi dan system ', '4294964637', 0, '2026-01-18 11:42:56', '2026-01-21 14:16:58'),
(4, 3, 'Rapat ', 'Day 1 Pajak naik jadi 15%', '4293892762', 1, '2026-01-20 14:11:51', '2026-01-22 03:06:12'),
(5, 3, 'isisqwqwq', 'jsst', '4287679225', 1, '2026-01-22 02:09:54', '2026-01-22 03:06:37'),
(6, 3, 'tesy', 'baha', '4294964637', 0, '2026-01-22 02:10:02', '2026-01-22 02:10:02'),
(7, 3, 'ahhha', 'nan', '4294964637', 0, '2026-01-22 02:10:51', '2026-01-22 02:10:51'),
(9, 1, 'Beli sensor Dan esp32', 'ESP32 Devkit Pack shoppe: 270k', '4294964637', 0, '2026-01-22 19:32:52', '2026-01-22 19:32:52');

-- --------------------------------------------------------

--
-- Table structure for table `schedules`
--

CREATE TABLE `schedules` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `mata_kuliah` varchar(100) NOT NULL,
  `dosen` varchar(100) DEFAULT NULL,
  `ruangan` varchar(50) DEFAULT NULL,
  `hari` enum('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu') NOT NULL,
  `jam_mulai` time NOT NULL,
  `jam_selesai` time NOT NULL,
  `jenis_kelas` enum('Teori','Praktek') DEFAULT 'Teori',
  `semester` int(11) DEFAULT 1,
  `tgl_mulai` date DEFAULT NULL,
  `diarsipkan` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `schedules`
--

INSERT INTO `schedules` (`id`, `user_id`, `mata_kuliah`, `dosen`, `ruangan`, `hari`, `jam_mulai`, `jam_selesai`, `jenis_kelas`, `semester`, `tgl_mulai`, `diarsipkan`) VALUES
(1, 1, 'Pemrograman Framework', 'Pak Aji', 'Lab 101', 'Senin', '08:00:00', '10:00:00', 'Teori', 5, '2026-01-18', 0),
(2, 1, 'Mobile Computing', 'Pak Afri', 'K-410', 'Kamis', '10:30:00', '12:30:00', 'Teori', 5, '2026-01-18', 0),
(3, 1, 'Mobile Computing', 'Pak Afri', '410', 'Kamis', '12:30:00', '13:30:00', 'Praktek', 4, '2026-01-18', 1),
(4, 3, 'Tanam Sawit', 'Pak owiiii', '1', 'Senin', '08:00:00', '10:00:00', 'Teori', 1, '2026-01-18', 1),
(5, 3, 'Nambang', 'Pak owi', '4', 'Selasa', '07:00:00', '10:30:00', 'Teori', 3, '2026-01-18', 0),
(6, 1, 'Internet of Things', 'Pak Andi', '406', 'Rabu', '10:00:00', '12:30:00', 'Teori', 5, '2026-01-21', 0),
(7, 3, 'Teknik Sawit Lanjutan', 'Pak wowo', '1', 'Rabu', '08:00:00', '10:30:00', 'Praktek', 3, '2026-01-21', 0),
(8, 3, 'Buzzer Attack', 'Termul', '3', 'Senin', '10:00:00', '10:30:00', 'Teori', 1, '2026-01-19', 0),
(9, 3, 'Oil Etanol ', 'Bahlil', '5', 'Kamis', '09:00:00', '11:00:00', 'Teori', 5, '2026-01-22', 0),
(10, 3, 'Inisialisasi Hutang', 'Sri', '2', 'Jumat', '09:00:00', '11:45:00', 'Teori', 3, '2026-01-23', 0),
(11, 4, 'agama budha', 'iqbal', '321', 'Kamis', '18:50:00', '21:50:00', 'Teori', 3, '2026-01-23', 0),
(12, 3, 'nna', 'nanaj', 'h', 'Kamis', '02:30:00', '03:13:00', 'Teori', 11, '2026-01-22', 0),
(13, 3, 'dadad', 'adada', 'ada', 'Kamis', '14:20:00', '16:23:00', 'Teori', 1, '2026-01-22', 0),
(14, 1, 'Organisasi Dan Manajemen', 'Bu LiNDA', '405', 'Rabu', '08:00:00', '09:40:00', 'Teori', 5, '2026-01-21', 0),
(15, 1, 'Cloud Computing', 'Pak Juki', '402', 'Selasa', '08:00:00', '10:30:00', 'Teori', 7, '2026-01-20', 0),
(16, 1, 'Cybersecurity', 'Pak Heri', '406', 'Senin', '12:30:00', '15:00:00', 'Teori', 5, '2026-01-19', 0),
(17, 8, 'Mobile', 'Yudha', '410', 'Sabtu', '21:26:00', '22:26:00', 'Praktek', 1, '2026-01-24', 0);

-- --------------------------------------------------------

--
-- Table structure for table `tasks`
--

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `judul_tugas` varchar(150) NOT NULL,
  `mata_kuliah` varchar(100) NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `tenggat_waktu` datetime NOT NULL,
  `link_pengumpulan` varchar(255) DEFAULT NULL,
  `diarsipkan` tinyint(1) DEFAULT 0,
  `mendesak` tinyint(1) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tasks`
--

INSERT INTO `tasks` (`id`, `user_id`, `judul_tugas`, `mata_kuliah`, `deskripsi`, `tenggat_waktu`, `link_pengumpulan`, `diarsipkan`, `mendesak`, `created_at`) VALUES
(5, 1, 'Laporan Akhir Project', 'Internet of Things', '', '2026-01-27 23:59:00', '', 0, 0, '2026-01-18 12:58:45'),
(6, 3, 'Gusur Lahan Sumatra', 'Teknik Sawit Lanjutan', 'Minimal 10 hektar lah kira kira', '2026-01-20 12:30:00', '', 1, 0, '2026-01-18 17:20:18'),
(7, 3, 'Pengalihan Isu', 'Buzzer Attack', '', '2026-01-20 01:00:00', '', 0, 0, '2026-01-19 14:44:27'),
(8, 3, 'Tata cara perbudak rakyat dengan pungutan hutang ', 'Inisialisasi Hutang', '', '2026-01-24 23:59:00', '', 1, 0, '2026-01-19 14:45:07'),
(9, 1, 'Aplikasi Flutter', 'Mobile Computing', '', '2026-01-22 23:59:00', '', 1, 1, '2026-01-20 09:08:13'),
(10, 3, 'Kandidat DPRD', 'Inisialisasi Hutang', '', '2026-01-27 23:59:00', '', 0, 0, '2026-01-21 17:56:36'),
(17, 3, 'sjsjak', 'Buzzer Attack', '', '2026-01-23 23:59:00', '', 0, 0, '2026-01-21 21:02:27'),
(18, 3, 'asaddadad', 'Buzzer Attack', '', '2026-01-23 23:59:00', '', 0, 0, '2026-01-22 04:26:18'),
(19, 1, 'Project based Perusahaan', 'Organisasi Dan Manajemen', '', '2026-01-26 23:59:00', '', 0, 0, '2026-01-22 12:29:28'),
(20, 1, 'Presentasi Prototype', 'Internet of Things', '', '2026-01-27 23:59:00', '', 0, 0, '2026-01-22 12:30:05'),
(21, 1, 'Video Lab VM Union', 'Cybersecurity', '', '2026-01-25 23:59:00', '', 0, 0, '2026-01-22 12:42:07'),
(22, 8, 'coba', 'Mobile', 'aqq', '2026-01-23 23:59:00', '2222', 1, 0, '2026-01-22 14:28:20'),
(23, 8, 'sss', 'Mobile', 'sss', '2026-01-23 23:59:00', 'sss', 1, 0, '2026-01-22 14:28:38');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `jurusan` varchar(100) DEFAULT NULL,
  `foto_profil` varchar(255) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `semester_saat_ini` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `nama_lengkap`, `email`, `password`, `jurusan`, `foto_profil`, `token`, `created_at`, `semester_saat_ini`) VALUES
(1, 'Ryuu Min', 'ryuumin@test.com', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Teknologi Informasi', 'profile_1_1768679419.jpg', NULL, '2026-01-17 09:47:52', 5),
(2, 'Baskerville ONLINEEE', 'van@test.com', '15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225', 'Teknik Kedokteran', 'profile_2_1768756505.jpg', NULL, '2026-01-17 20:20:48', 6),
(3, 'Aldebaran', 'alde@info.com', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Teknik Persawitan', 'profile_3_1769052605.jpg', NULL, '2026-01-18 06:28:41', 1),
(4, 'riszki fadhillah', 'riszki@gmail.com', '0f59c4d4984389f92fdf827452c2d15968a7f6d1e36a42be22c80bc728bc37e5', 'Belum Diisi', 'profile_4_1768909923.jpg', NULL, '2026-01-20 11:50:10', 1),
(6, 'test', 'test@gmail.com', '9bba5c53a0545e0c80184b946153c9f58387e3bd1d4ee35740f29ac2e718b019', NULL, NULL, NULL, '2026-01-21 15:08:17', 1),
(8, 'test', 'test1@gmail.com', '15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225', NULL, NULL, NULL, '2026-01-22 14:26:22', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `notes`
--
ALTER TABLE `notes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `schedules`
--
ALTER TABLE `schedules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `tasks`
--
ALTER TABLE `tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `notes`
--
ALTER TABLE `notes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `schedules`
--
ALTER TABLE `schedules`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `notes`
--
ALTER TABLE `notes`
  ADD CONSTRAINT `notes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `schedules`
--
ALTER TABLE `schedules`
  ADD CONSTRAINT `schedules_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `tasks`
--
ALTER TABLE `tasks`
  ADD CONSTRAINT `tasks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
