import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'about_page.dart';

// --- KONSTANTA WARNA ---
const Color kCreamColor = Color(0xFFF9F4E8);
const Color kYellowAccent = Color(0xFFFDC25B);
const Color kGreenAccent = Color(0xFFA5D6A7);
const Color kRedUrgent = Color(0xFFFF8A80);
const Color kBlueNormal = Color(0xFF90CAF9);
const Color kWhite = Colors.white;
const double kBorderWidth = 1.5;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();

  // Variabel untuk Typing Effect
  final String _fullText = "SIMahasigma";
  String _displayedText = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTyping() {
    int index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (index < _fullText.length) {
        setState(() {
          _displayedText += _fullText[index];
          index++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  // Fungsi untuk scroll ke halaman About
  void _scrollToAbout() {
    _pageController.animateToPage(1, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. PAGE VIEW (Untuk Swipe Vertikal Landing <-> About)
          PageView(
            controller: _pageController,
            scrollDirection: Axis.vertical, // Swipe ke atas/bawah
            children: [
              // HALAMAN 1: KONTEN LANDING PAGE
              _buildLandingContent(),

              // HALAMAN 2: ABOUT PAGE
              // PANGGIL DENGAN TRUE
              const AboutPage(isLandingMode: true),
            ],
          ),

          // 2. FLOATING BUTTON
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: kWhite,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Mulai Sekarang",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: kYellowAccent),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget konten Landing Page
  Widget _buildLandingContent() {
    return SafeArea(
      child: Column(
        children: [
          // --- BAGIAN ATAS (Gambar & Judul) ---
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: kGreenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: kBorderWidth),
                        ),
                      ),
                      Container(
                        width: 180,
                        height: 180,
                        margin: const EdgeInsets.only(left: 10, top: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: kBorderWidth),
                        ),
                      ),
                      const Icon(Icons.school_rounded, size: 100, color: Colors.black),
                      Positioned(
                        right: 0, bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kYellowAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: kBorderWidth)),
                          child: const Icon(Icons.check, color: Colors.black, size: 30),
                        ),
                      ),
                      Positioned(
                        left: 0, top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kRedUrgent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: kBorderWidth)),
                          child: const Icon(Icons.notifications_active, color: Colors.black, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _displayedText,
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Kelola catatan, jadwal, dan tugas.\nBantu kuliahmu tetap berjalan sesuai rencana.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // --- BAGIAN FITUR ---
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureItem(Icons.calendar_month, "Jadwal", kBlueNormal),
                      _buildFeatureItem(Icons.assignment, "Tugas", kYellowAccent),
                      _buildFeatureItem(Icons.edit_note, "Catatan", kRedUrgent),
                    ],
                  ),
                  const Spacer(),
                  // Indikator Swipe Up
                  Icon(Icons.keyboard_double_arrow_down_rounded, color: Colors.black.withOpacity(0.3)),
                  Text("Scroll/Swipe down untuk melihat lebih lanjut", style: GoogleFonts.poppins(fontSize: 10, color: Colors.black38)),
                  const SizedBox(height: 100), // Ruang kosong agar tidak tertutup tombol
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: kBorderWidth),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: Icon(icon, color: Colors.black, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}