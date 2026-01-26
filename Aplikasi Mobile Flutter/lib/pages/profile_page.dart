import 'dart:io';
import 'dart:convert';
import 'dart:typed_data'; // Untuk Web
import 'package:flutter/foundation.dart' show kIsWeb; // Deteksi Web
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../main.dart';
import 'about_page.dart';
import 'login_page.dart';
import 'landing_page.dart';

// --- KONSTANTA WARNA ---
const Color kCreamColor = Color(0xFFF9F4E8);
const Color kYellowAccent = Color(0xFFFDC25B);
const Color kGreenAccent = Color(0xFFA5D6A7);
const Color kRedError = Color(0xFFFF8A80);
const Color kWhite = Colors.white;
const double kBorderWidth = 1.5;
const double kBorderRadius = 16.0;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State Data Profil
  String _name = "Loading...";
  String _major = "-";
  int _semester = 1;
  String? _profilePhotoUrl;

  // State Gambar (Web & Mobile)
  XFile? _pickedFile;
  Uint8List? _webImageBytes;

  final Dio _dio = Dio();
  final String _baseUrl = 'https://sim.ujangkedu.my.id';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // --- API: AMBIL DATA PROFIL ---
  Future<void> _fetchProfile() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      final response = await _dio.post(
        '$_baseUrl/get_profile.php',
        data: FormData.fromMap({'user_id': userId}),
      );

      if (response.data != null && response.data['success'] == true && mounted) {
        final data = response.data['data'];
        setState(() {
          _name = data['nama_lengkap'] ?? "Tanpa Nama";
          _major = data['jurusan'] ?? 'Belum Diisi';
          _semester = int.tryParse(data['semester_saat_ini'].toString()) ?? 1;
          _profilePhotoUrl = data['foto_url'];
        });
      }
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
    }
  }

  // --- API: UPDATE PROFIL ---
  Future<Map<String, dynamic>> _updateProfile({
    required String name,
    required String major,
    String? currentPassword,
    String? newPassword,
    XFile? imageFile
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      Map<String, dynamic> formMap = {
        'user_id': userId,
        'nama_lengkap': name,
        'jurusan': major,
        'current_password': (currentPassword != null && currentPassword.isNotEmpty)
            ? _hashPassword(currentPassword) : '',
        'new_password': (newPassword != null && newPassword.isNotEmpty)
            ? _hashPassword(newPassword) : '',
      };

      if (imageFile != null) {
        if (kIsWeb) {
          // WEB: Kirim Bytes
          final bytes = await imageFile.readAsBytes();
          formMap['foto_profil'] = MultipartFile.fromBytes(
              bytes,
              filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg'
          );
        } else {
          // MOBILE: Kirim Path
          formMap['foto_profil'] = await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last
          );
        }
      }

      final response = await _dio.post('$_baseUrl/update_profile.php', data: FormData.fromMap(formMap));

      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          _fetchProfile();
          setState(() {
            _pickedFile = null;
            _webImageBytes = null;
          });
        }
        return {'success': true, 'message': response.data['message']};
      } else {
        return {'success': false, 'message': response.data['message'] ?? "Gagal update"};
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      return {'success': false, 'message': "Koneksi gagal / Server Error"};
    }
  }

  void _showSnackBar(String m, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black, width: 1.5)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(children: [
            _buildProfileHeader(context),
            const SizedBox(height: 40),
            _buildMenuButton(icon: Icons.school_outlined, title: "Semester Saat Ini", subtitle: "Anda berada di Semester $_semester", color: const Color(0xFFE1BEE7), onTap: () { Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainPage()), (route) => false); }),
            const SizedBox(height: 16),
            _buildMenuButton(icon: Icons.article_outlined, title: "Tentang Aplikasi", subtitle: "Informasi seputar SIMahasigma", color: const Color(0xFFB3E5FC), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AboutPage()))),
            const SizedBox(height: 30),
            _buildLogoutButton(context),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    ImageProvider img;
    if (kIsWeb && _webImageBytes != null) {
      img = MemoryImage(_webImageBytes!);
    } else if (!kIsWeb && _pickedFile != null) {
      img = FileImage(File(_pickedFile!.path));
    } else if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
      img = NetworkImage("$_profilePhotoUrl?t=${DateTime.now().millisecondsSinceEpoch}");
    } else {
      img = const NetworkImage('https://i.pravatar.cc/150?img=12');
    }

    return Column(children: [
      Stack(children: [
        Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
                shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2),
                image: DecorationImage(image: img, fit: BoxFit.cover),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 4))]
            )
        ),
        Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
                onTap: () => _showEditProfileDialog(context),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kYellowAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                    child: const Icon(Icons.camera_alt, size: 20)
                )
            )
        ),
      ]),
      const SizedBox(height: 20),
      Text(_name, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      Text(_major, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(onPressed: () => _showEditProfileDialog(context), style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: Colors.black, side: const BorderSide(color: Colors.black, width: kBorderWidth), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), icon: const Icon(Icons.edit, size: 18),  label: Text("Edit Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12))),
    ]);
  }

  // --- DIALOG EDIT PROFIL ---
  void _showEditProfileDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _name);
    final majorCtrl = TextEditingController(text: _major);
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    XFile? tempPicked;
    Uint8List? tempWebBytes;
    bool isLoading = false, oOld = true, oNew = true, oConf = true;

    // State lokal untuk error text
    String? nameErr, majorErr, oldPErr, newPErr, confPErr;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setS) {

        ImageProvider dialogImg;
        if (kIsWeb && tempWebBytes != null) {
          dialogImg = MemoryImage(tempWebBytes!);
        } else if (!kIsWeb && tempPicked != null) {
          dialogImg = FileImage(File(tempPicked!.path));
        } else if (_profilePhotoUrl != null) {
          dialogImg = NetworkImage("$_profilePhotoUrl?t=${DateTime.now().millisecondsSinceEpoch}");
        } else {
          dialogImg = const NetworkImage('https://i.pravatar.cc/150?img=12');
        }

        return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(color: kCreamColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), border: Border(top: BorderSide(color: Colors.black, width: 2))),
            child: Column(children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 60, height: 5, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10))),
              Padding(padding: const EdgeInsets.all(24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Edit Profil", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))])),
              const Divider(height: 1, color: Colors.black12),
              Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [
                Center(child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      if (kIsWeb) {
                        final b = await picked.readAsBytes();
                        setS(() { tempPicked = picked; tempWebBytes = b; });
                      } else {
                        setS(() => tempPicked = picked);
                      }
                    }
                  },
                  child: Stack(children: [
                    Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5), image: DecorationImage(image: dialogImg, fit: BoxFit.cover))),
                    Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kYellowAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black)), child: const Icon(Icons.camera_alt, size: 16))),
                  ]),
                )),
                const SizedBox(height: 24),
                _buildFormLabel("Nama Lengkap"), _buildTextField(nameCtrl, "Nama", errorText: nameErr),
                const SizedBox(height: 16),
                _buildFormLabel("Jurusan"), _buildTextField(majorCtrl, "Jurusan", errorText: majorErr),
                const SizedBox(height: 24), const Divider(thickness: 1.5), const SizedBox(height: 16),
                Text("Ganti Password", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildFormLabel("Password Lama"), _buildPasswordField(oldPassCtrl, "Password Lama", oOld, () => setS(() => oOld = !oOld), errorText: oldPErr),
                const SizedBox(height: 12),
                _buildFormLabel("Password Baru"), _buildPasswordField(newPassCtrl, "Minimal 6 karakter", oNew, () => setS(() => oNew = !oNew), errorText: newPErr),
                const SizedBox(height: 12),
                _buildFormLabel("Konfirmasi Password"), _buildPasswordField(confirmPassCtrl, "Ulangi Password", oConf, () => setS(() => oConf = !oConf), errorText: confPErr),
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: Colors.black, side: const BorderSide(color: Colors.black, width: kBorderWidth), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: isLoading ? null : () {
                      // 1. VALIDASI LOKAL
                      setS(() { nameErr = null; majorErr = null; oldPErr = null; newPErr = null; confPErr = null; });
                      bool isValid = true;
                      if (nameCtrl.text.trim().isEmpty) { setS(() => nameErr = "Wajib diisi"); isValid = false; }
                      if (majorCtrl.text.trim().isEmpty) { setS(() => majorErr = "Wajib diisi"); isValid = false; }

                      bool isPass = oldPassCtrl.text.isNotEmpty || newPassCtrl.text.isNotEmpty || confirmPassCtrl.text.isNotEmpty;
                      if (isPass) {
                        if (oldPassCtrl.text.isEmpty) { setS(() => oldPErr = "Wajib diisi jika mengganti password"); isValid = false; }
                        if (newPassCtrl.text.length < 6) { setS(() => newPErr = "Minimal 6 karakter"); isValid = false; }
                        if (newPassCtrl.text != confirmPassCtrl.text) { setS(() => confPErr = "Konfirmasi tidak cocok"); isValid = false; }
                        if (newPassCtrl.text.isEmpty && oldPassCtrl.text.isNotEmpty) { setS(() => newPErr = "Password baru tidak boleh kosong"); isValid = false; }
                      }
                      if (!isValid) return;

                      _showSaveConfirmDialog(context, () async {
                        setS(() => isLoading = true);
                        final result = await _updateProfile(
                            name: nameCtrl.text,
                            major: majorCtrl.text,
                            currentPassword: isPass ? oldPassCtrl.text : null,
                            newPassword: isPass ? newPassCtrl.text : null,
                            imageFile: tempPicked
                        );
                        setS(() => isLoading = false);

                        if (result['success']) {
                          Navigator.pop(ctx);
                          _showSnackBar("Profil berhasil diperbarui!", kGreenAccent);
                        } else {
                          // 2. ERROR HANDLING DARI SERVER (INLINE ERROR)
                          String msg = result['message'].toString().toLowerCase();
                          setS(() {
                            if (msg.contains("password lama") && msg.contains("salah")) {
                              oldPErr = "Password lama salah!";
                            }
                            else if (msg.contains("password baru") && msg.contains("sama")) {
                              newPErr = "Password baru sama dengan yang lama!";
                            }
                            else {
                              // Error umum lainnya (Koneksi, DB, dll) tetap pakai SnackBar
                              _showSnackBar(result['message'], kRedError);
                            }
                          });
                        }
                      });
                    },
                    child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold))
                )),
                Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
              ]))
            ])
        );
      }),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildMenuButton({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(kBorderRadius), border: Border.all(color: Colors.black, width: kBorderWidth), boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(4, 4))]), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: Colors.black)), child: Icon(icon, size: 28)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54))])), const Icon(Icons.arrow_forward_ios_rounded, size: 16)])));
  }
  Widget _buildLogoutButton(BuildContext context) => SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showLogoutDialog(context), icon: const Icon(Icons.logout_rounded), label: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), side: const BorderSide(color: Colors.black, width: kBorderWidth), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)))));
  Widget _buildFormLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)));
  Widget _buildTextField(TextEditingController c, String h, {String? errorText}) => TextField(controller: c, decoration: InputDecoration(hintText: h, errorText: errorText, filled: true, fillColor: kWhite, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: kBorderWidth)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRedError, width: 2.0)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRedError, width: 2.0))));
  Widget _buildPasswordField(TextEditingController c, String h, bool o, VoidCallback t, {String? errorText}) => TextField(controller: c, obscureText: o, decoration: InputDecoration(hintText: h, errorText: errorText, filled: true, fillColor: kWhite, suffixIcon: IconButton(icon: Icon(o ? Icons.visibility_off : Icons.visibility), onPressed: t), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: kBorderWidth)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRedError, width: 2.0)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRedError, width: 2.0))));
  void _showLogoutDialog(BuildContext context) => showDialog(context: context, builder: (c) => const LogoutDialog());
  void _showSaveConfirmDialog(BuildContext context, VoidCallback onConfirm) => showDialog(context: context, builder: (c) => SaveConfirmationDialog(onConfirm: onConfirm));
}

class LogoutDialog extends StatefulWidget {
  const LogoutDialog({super.key});
  @override State<LogoutDialog> createState() => _LogoutDialogState();
}
class _LogoutDialogState extends State<LogoutDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); _s = CurvedAnimation(parent: _c, curve: Curves.elasticOut); _c.forward(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Dialog(backgroundColor: kCreamColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2)), child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, children: [ScaleTransition(scale: _s, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 1.5)), child: const Icon(Icons.logout, size: 32, color: Colors.red))), const SizedBox(height: 16), Text("Keluar Akun?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(color: Colors.black, thickness: 1.5), const Text("Yakin ingin keluar?", textAlign: TextAlign.center), const SizedBox(height: 24), Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Batal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: () async { final p = await SharedPreferences.getInstance(); p.clear(); if(!mounted) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LandingPage()), (r) => false); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold))))])])));
  }
}

class SaveConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const SaveConfirmationDialog({super.key, required this.onConfirm});
  @override State<SaveConfirmationDialog> createState() => _SaveConfirmationDialogState();
}
class _SaveConfirmationDialogState extends State<SaveConfirmationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); _s = CurvedAnimation(parent: _c, curve: Curves.elasticOut); _c.forward(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Dialog(backgroundColor: kCreamColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2)), child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, children: [ScaleTransition(scale: _s, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kGreenAccent.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)), child: const Icon(Icons.check_circle_outline, size: 32, color: Colors.black))), const SizedBox(height: 16), Text("Simpan Data?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(color: Colors.black, thickness: 1.5), const Text("Pastikan data sudah benar.", textAlign: TextAlign.center), const SizedBox(height: 24), Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Batal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); widget.onConfirm(); }, style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: Colors.black, side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold))))])])));
  }
}