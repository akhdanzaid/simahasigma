import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- KONSTANTA STYLE ---
const Color kCreamColor = Color(0xFFF9F4E8);
const Color kYellowAccent = Color(0xFFFDC25B);
const Color kGreenAccent = Color(0xFFA5D6A7);
const Color kRedUrgent = Color(0xFFFF8A80);
const Color kBlueNormal = Color(0xFF90CAF9);

const double kBorderWidth = 1.5;
const double kBorderRadius = 16.0;

class AboutPage extends StatelessWidget {
  // [TAMBAHAN] Parameter untuk menentukan mode tampilan
  final bool isLandingMode;

  // Secara default isLandingMode false (untuk Profile Page)
  const AboutPage({super.key, this.isLandingMode = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      appBar: AppBar(
        backgroundColor: kCreamColor,
        elevation: 0,
        scrolledUnderElevation: 0,

        // [LOGIKA DINAMIS 1] Tombol Back (Leading)
        // Jika mode Landing (Swipe), hilangkan tombol back.
        // Jika mode Profile, tampilkan panah kiri untuk kembali.
        automaticallyImplyLeading: !isLandingMode,
        leading: isLandingMode
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        // [LOGIKA DINAMIS 2] Judul & Panah Atas
        title: isLandingMode
            ? Column(
          children: [
            const Icon(Icons.keyboard_arrow_up, color: Colors.black38),
            const SizedBox(height: 8),
            Text(
              "About SIMahasigma",
              style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        )
            : Text(
          "About SIMahasigma",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),

        centerTitle: true,

        // [LOGIKA DINAMIS 3] Tinggi Toolbar
        // Jika Landing Mode, toolbar lebih tinggi untuk muat icon panah atas
        toolbarHeight: isLandingMode ? 80 : kToolbarHeight,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO SECTION (Logo & Judul)
            Center(
              child: Column(
                children: [
                  // --- LOGO ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: kGreenAccent, shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                      Container(
                        width: 100, height: 100,
                        margin: const EdgeInsets.only(left: 8, top: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent, shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                      const Icon(Icons.school_rounded, size: 50, color: Colors.black),
                      Positioned(
                        top: 0, left: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: kRedUrgent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                          child: const Icon(Icons.notifications_active, size: 16, color: Colors.black),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: kYellowAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                          child: const Icon(Icons.check, size: 18, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "SIMahasigma",
                    style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1),
                  ),
                  Text(
                    "Sistem Informasi Mahasigma",
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(thickness: 1.5, color: Colors.black12),
            const SizedBox(height: 24),

            // 2. ARTIKEL
            Text("Apa itu SIMahasigma?", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "SIMahasigma bukan sekadar aplikasi pencatat biasa. Ini adalah senjata rahasia bagi para mahasiswa yang ingin tetap 'Sigma' di tengah gempuran tugas dan jadwal kuliah yang padat.\n\nDengan gaya Neo-Brutalism yang sederhana dan berani, aplikasi ini dirancang supaya fungsinya terasa jelas sejak pertama dipakai.",
              style: GoogleFonts.poppins(fontSize: 14, height: 1.8, color: Colors.black87),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 36),

            // 3. FITUR
            Text("Fitur & Cara Penggunaan", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _buildArticleSection(
              title: "Manajemen Jadwal Kuliah",
              icon: Icons.calendar_month_outlined, iconColor: kBlueNormal,
              content: "Jangan sampai salah masuk kelas atau telat absen. Di menu Jadwal (ikon Kalender), kamu bisa melihat agenda perkuliahanmu dalam tampilan kalender bulanan yang rapi.\n\nCara pakai: Tekan tombol 'Add New' di pojok kanan atas, isi nama mata kuliah, ruangan, jam, dan pilih apakah itu kelas Teori atau Praktek.\nCara: Tekan 'Add New' di pojok kanan atas untuk tambah matkul.",
            ),
            _buildDivider(),
            _buildArticleSection(
              title: "Catatan (Notes)",
              icon: Icons.edit_note_rounded, iconColor: kRedUrgent,
              content: "Otak mahasiswa penuh dengan ide brilian. Jangan biarkan hilang! Gunakan fitur Notes untuk mencatat ide skripsi, daftar belanja, atau rangkuman materi dosen.\n\nTips Pro: Kamu bisa menyematkan (Pin) catatan yang paling penting agar selalu muncul di urutan teratas. Tekan lama pada catatan untuk melihat opsi hapus.",
            ),
            _buildDivider(),
            _buildArticleSection(
              title: "Pelacak Tugas & Deadline",
              icon: Icons.assignment_outlined, iconColor: kGreenAccent,
              content: "Musuh utama mahasiswa adalah deadline yang terlupakan. Fitur ini membantumu melacak semua tugas yang masuk.\n\nFitur utama: Kamu bisa menandai tugas sebagai 'Mendesak' (Urgent) agar tampil dengan warna merah peringatan. Jika sudah selesai, bisa kamu checklist biar otomatis ditandai 'selesai' dan masuk ke arsip tugas",
            ),

            // [FIX] Tambahkan logika padding bawah
            // Jika Landing Mode, butuh ruang ekstra untuk tombol floating.
            // Jika Profile Mode, tidak butuh ruang ekstra.
            SizedBox(height: isLandingMode ? 120 : 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.grey[300], thickness: 1));

  Widget _buildArticleSection({required String title, required IconData icon, required Color iconColor, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 1.5), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)]),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
        ]),
        const SizedBox(height: 12),
        Text(content, style: GoogleFonts.poppins(fontSize: 13, height: 1.6, color: Colors.black87), textAlign: TextAlign.justify),
      ],
    );
  }
}