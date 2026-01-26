import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../main.dart';
import 'landing_page.dart';

// --- KONSTANTA WARNA ---
const Color kCreamColor = Color(0xFFF9F4E8);
const Color kYellowAccent = Color(0xFFFDC25B);
const Color kGreenColor = Color(0xFFA5D6A7);
const Color kWhite = Colors.white;
const Color kBlack = Colors.black;
const double kBorderWidth = 1.5;
const double kBorderRadius = 16.0;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final Dio _dio = Dio();
  final String _baseUrl = 'https://sim.ujangkedu.my.id';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_login') == true && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainPage()));
    }
  }

  // HELPER: Hashing SHA-256
  String _hashPassword(String p) => sha256.convert(utf8.encode(p)).toString();

  void _showSnackBar(String m, Color bg, Color txt) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: GoogleFonts.poppins(color: txt, fontWeight: FontWeight.bold)),
      backgroundColor: bg, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: kBlack)),
    ));
  }

  // --- LOGIKA API: REGISTER ---
  Future<void> _handleRegister() async {
    try {
      final res = await _dio.post('$_baseUrl/register.php', data: FormData.fromMap({
        'nama_lengkap': nameController.text,
        'email': emailController.text,
        'password': _hashPassword(passController.text), // Kirim Hash
      }));

      if (!mounted) return;

      if (res.data['success'] == true) {
        _showSuccessDialog();
      } else {
        _showSnackBar(res.data['message'], Colors.red, kWhite);
      }
    } catch (e) {
      _showSnackBar("Gagal terhubung ke server", Colors.red, kWhite);
    }
  }

  // --- LOGIKA API: LOGIN ---
  Future<void> _handleLogin() async {
    try {
      final res = await _dio.post('$_baseUrl/login.php', data: FormData.fromMap({
        'email': emailController.text,
        'password': _hashPassword(passController.text), // Kirim Hash
      }));

      if (!mounted) return;

      if (res.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', res.data['user_id']);
        await prefs.setString('nama_user', res.data['nama']);
        await prefs.setBool('is_login', true);

        _showSnackBar("Selamat datang, ${res.data['nama']}!", kGreenColor, kBlack);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainPage()));
      } else {
        _showSnackBar(res.data['message'], Colors.red, kWhite);
      }
    } catch (e) {
      _showSnackBar("Gagal login", Colors.red, kWhite);
    }
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      isLogin ? _handleLogin() : _handleRegister();
    }
  }

  void _showSuccessDialog() {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: kCreamColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: kBlack, width: 2)),
      child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kGreenColor.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: kBlack, width: 1.5)), child: const Icon(Icons.check, size: 32)),
        const SizedBox(height: 16),
        const Text("Berhasil!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text("Akun Anda telah dibuat. Silahkan login.", textAlign: TextAlign.center),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); setState(() => isLogin = true); }, style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: kBlack, side: const BorderSide(color: kBlack)), child: const Text("Login Sekarang")))
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBlack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true, // Agar background menyatu ke atas
      backgroundColor: kCreamColor,
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isLogin ? "Welcome Back,\nMahasigma!" : "Buat Akun\nBaru.", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
        const SizedBox(height: 40),
        if (!isLogin) ...[
          _buildLabel("Nama Lengkap"),
          _buildTextField(controller: nameController, hint: "Nama Kamu", icon: Icons.person_outline, validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null),
          const SizedBox(height: 20),
        ],
        _buildLabel("Email"),
        _buildTextField(controller: emailController, hint: "Email", icon: Icons.email_outlined, validator: (v) => !v!.contains("@") ? "Email tidak valid" : null),
        const SizedBox(height: 20),
        _buildLabel("Password"),
        _buildTextField(controller: passController, hint: "Password", icon: Icons.lock_outline, isObscure: true, validator: (v) => v!.length < 6 ? "Min. 6 karakter" : null),
        if (!isLogin) ...[
          const SizedBox(height: 20),
          _buildLabel("Konfirmasi"),
          _buildTextField(controller: confirmPassController, hint: "Ulangi password", icon: Icons.lock_reset, isObscure: true, validator: (v) => v != passController.text ? "Tidak cocok" : null),
        ],
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _onSubmit, style: ElevatedButton.styleFrom(backgroundColor: kBlack, foregroundColor: kWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius))), child: Text(isLogin ? "Masuk Sekarang" : "Daftar Akun", style: const TextStyle(fontWeight: FontWeight.bold)))),
        const SizedBox(height: 24),

        // Menggunakan RichText agar warna bisa dibedakan
        Center(
          child: GestureDetector(
            onTap: () => setState(() => isLogin = !isLogin),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 14, color: kBlack),
                children: [
                  TextSpan(text: isLogin ? "Belum punya akun? " : "Sudah punya akun? "),
                  TextSpan(
                    text: isLogin ? "Daftar disini" : "Login disini",
                    style: const TextStyle(
                      color: Color(0xFFE6A000),
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFE6A000),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

      ]))))),
    );
  }

  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)));
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isObscure = false, String? Function(String?)? validator}) {
    return Container(decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(kBorderRadius), border: Border.all(color: kBlack, width: kBorderWidth), boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(3, 3))]),
        child: TextFormField(controller: controller, obscureText: isObscure, validator: validator, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: kBlack), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))));
  }
}