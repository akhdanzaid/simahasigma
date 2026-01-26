import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTS HALAMAN ---
import 'pages/schedule_page.dart' hide kCreamColor, kYellowAccent, kTealColor, kRedUrgent, kGreenAccent, kWhite, kBorderWidth, kBorderRadius;
import 'pages/deadline_page.dart' hide kCreamColor, kYellowAccent, kRedUrgent, kGreenDone, kBlueNormal, kGreyExpired, kWhite, kBorderWidth, kBorderRadius;
import 'pages/notes_page.dart' hide kCreamColor, kYellowAccent, kGreenAccent, kWhite, kBorderWidth, kBorderRadius;
import 'pages/profile_page.dart' hide kCreamColor, kYellowAccent, kGreenAccent, kWhite, kBorderWidth, kBorderRadius;
import 'pages/login_page.dart';
import 'pages/landing_page.dart';

// --- KONSTANTA WARNA ---
const Color kCreamColor = Color(0xFFF9F4E8);
const Color kYellowAccent = Color(0xFFFDC25B);
const Color kGreenAccent = Color(0xFFA5D6A7);
const Color kPurpleAccent = Color(0xFFCE93D8);
const Color kWhite = Colors.white;
const double kBorderWidth = 1.5;
const double kBorderRadius = 16.0;

// --- MODEL DATA ---
class TaskItem {
  final String id, title, subject, description;
  final DateTime deadline;
  final String? submissionLink;
  bool isArchived, isUrgent;
  String serverStatus;

  TaskItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.deadline,
    this.description = '',
    this.submissionLink,
    this.isArchived = false,
    this.isUrgent = false,
    required this.serverStatus
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'].toString(),
      title: json['judul_tugas'],
      subject: json['mata_kuliah'],
      deadline: DateTime.parse(json['tenggat_waktu']),
      description: json['deskripsi'] ?? '',
      submissionLink: json['link_pengumpulan'],
      isArchived: json['diarsipkan'] == true || json['diarsipkan'] == 1 || json['diarsipkan'] == '1',
      isUrgent: json['mendesak'] == true || json['mendesak'] == 1 || json['mendesak'] == '1',
      serverStatus: json['status_server'] ?? 'normal',
    );
  }
}

List<TaskItem> globalTasks = [];

void main() { runApp(const StudentTaskApp()); }

class StudentTaskApp extends StatelessWidget {
  const StudentTaskApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIMahasigma',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.black, displayColor: Colors.black),
        scaffoldBackgroundColor: kCreamColor,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.containsKey('user_id');
    if (!mounted) return;
    if (isLoggedIn) {
      // Jika sudah login, langsung ke Dashboard (MainPage)
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainPage()));
    } else {
      // Jika belum login, ke Landing Page
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LandingPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kCreamColor,
      body: Center(child: CircularProgressIndicator(color: Colors.black)),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 2; // Default ke Dashboard
  int _currentSemester = 1;
  int _totalMatkul = 0;
  String? _profilePhotoUrl;
  String _userName = "Mahasigma";

  // Variable untuk kontrol tab awal deadline
  bool _startInHistory = false;

  Map<String, dynamic>? _currentClassData, _nextClassData;
  int _countdownSec = 0;
  Timer? _countdownTimer;

  final Dio _dio = Dio();
  final String _baseUrl = 'https://sim.ujangkedu.my.id';

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchHomeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 0;

      if (userId == 0) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginPage()));
        return;
      }

      final response = await _dio.post(
          '$_baseUrl/get_home_data.php',
          data: FormData.fromMap({'user_id': userId})
      );

      if (response.statusCode == 200 && mounted) {
        var data = response.data;
        setState(() {
          _userName = data['nama'] ?? "Mahasigma";
          _currentSemester = int.tryParse(data['semester'].toString()) ?? 1;
          _totalMatkul = data['total_matkul'] ?? 0;
          _profilePhotoUrl = data['foto_url'];
          _currentClassData = data['current_class'];
          _nextClassData = data['next_class'];
          _countdownSec = data['countdown_sec'] ?? 0;

          globalTasks.clear();
          if (data['tasks'] != null) {
            for (var json in data['tasks']) {
              globalTasks.add(TaskItem.fromJson(json));
            }
          }
        });
        _startLocalCountdown();
      }
    } catch (e) {
      debugPrint("Error fetching home data: $e");
    }
  }

  void _startLocalCountdown() {
    _countdownTimer?.cancel();
    if (_countdownSec > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdownSec > 0 && mounted) {
          setState(() => _countdownSec--);
        } else {
          timer.cancel();
          _fetchHomeData();
        }
      });
    }
  }

  Future<void> _processSemesterUpdate(String semester) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;
      final res = await _dio.post('$_baseUrl/update_current_semester.php', data: FormData.fromMap({
        'user_id': userId, 'semester_saat_ini': semester
      }));
      if (!mounted) return;
      if (res.data['success'] == true) {
        _fetchHomeData();
        _showSnackBar("Semester diperbarui!", kGreenAccent);
      }
    } catch (e) {
      _showSnackBar("Gagal memperbarui data.", Colors.redAccent);
    }
  }

  void _showUpdateSemesterDialog() {
    final semesterController = TextEditingController(text: _currentSemester.toString());
    showDialog(
      context: context,
      builder: (ctx) => ScheduleActionDialog(
        title: "Update Semester",
        content: "Masukkan semester Anda saat ini.",
        icon: Icons.school_rounded,
        iconColor: Colors.black,
        iconBg: kYellowAccent.withValues(alpha: 0.2),
        btnColor: kYellowAccent,
        customInput: TextField(
          controller: semesterController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          decoration: InputDecoration(
            hintText: "6", filled: true, fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
          ),
        ),
        onConfirm: () {
          if (semesterController.text.isEmpty) return;
          Navigator.pop(ctx);
          _showFinalConfirmation(semesterController.text);
        },
      ),
    );
  }

  void _showFinalConfirmation(String semesterBaru) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleActionDialog(
        title: "Konfirmasi Perubahan",
        content: "Semester $semesterBaru akan diaktifkan. Jadwal di bawah semester ini akan diarsipkan otomatis. Lanjutkan?",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.red,
        iconBg: Colors.red.withValues(alpha: 0.1),
        btnColor: kYellowAccent,
        onConfirm: () async {
          Navigator.pop(ctx);
          await _processSemesterUpdate(semesterBaru);
        },
      ),
    );
  }

  // function snackbar
  void _showSnackBar(String m, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
      backgroundColor: bg, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black)),
    ));
  }

  // --- FUNGSI NAVIGASI ---
  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
      // Jika navigasi manual lewat navbar, reset agar masuk ke tab default
      _startInHistory = false;
    });

    if (index == 2 || index == 4) {
      _fetchHomeData();
    }
  }

  // Fungsi khusus untuk navigasi ke riwayat deadline
  void _goToHistory() {
    setState(() {
      _startInHistory = true; // Set flag agar DeadlinePage buka tab Riwayat
      _selectedIndex = 3; // Pindah ke index DeadlinePage
    });
    _fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const NotesPage(),
      SchedulePage(onDataChanged: _fetchHomeData),
      DashboardContent(
        userName: _userName,
        semester: _currentSemester,
        totalMatkul: _totalMatkul,
        profilePhotoUrl: _profilePhotoUrl,
        currentClass: _currentClassData,
        nextClass: _nextClassData,
        countdown: _countdownSec,
        onProfileTap: () => _changePage(4),
        onNavigate: _changePage,
        // Pass fungsi ke dashboard
        onHistoryTap: _goToHistory,
        onRefresh: _fetchHomeData,
        onSemesterTap: _showUpdateSemesterDialog,
      ),
      // Pass parameter initialShowArchived
      DeadlinePage(
          onDataChanged: _fetchHomeData,
          initialShowArchived: _startInHistory
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _changePage,
        showDeadlineBadge: globalTasks.any((t) => t.serverStatus == 'urgent'),
      ),
    );
  }
}

// --- DASHBOARD UI ---

class DashboardContent extends StatelessWidget {
  final String userName;
  final int semester, totalMatkul, countdown;
  final String? profilePhotoUrl;
  final Map<String, dynamic>? currentClass, nextClass;
  final VoidCallback onProfileTap, onSemesterTap;
  final Function(int) onNavigate;
  final VoidCallback onHistoryTap;
  final Future<void> Function() onRefresh;

  const DashboardContent({
    super.key,
    required this.userName,
    required this.semester,
    required this.totalMatkul,
    this.profilePhotoUrl,
    required this.onProfileTap,
    required this.onNavigate,
    required this.onRefresh,
    required this.onSemesterTap,
    this.currentClass,
    this.nextClass,
    required this.countdown,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: HeaderGreetingSection(
              userName: userName,
              onProfileTap: onProfileTap,
              profilePhotoUrl: profilePhotoUrl,
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: kYellowAccent,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                children: [
                  const CalendarSection(),
                  const SizedBox(height: 24),
                  CurrentTaskCard(current: currentClass, next: nextClass, countdown: countdown),
                  const SizedBox(height: 24),
                  const InsightCard(),
                  const SizedBox(height: 20),
                  DashboardGrid(
                    semester: semester,
                    totalMatkul: totalMatkul,
                    onNavigate: onNavigate,
                    onSemesterTap: onSemesterTap,
                    onHistoryTap: onHistoryTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET BAGIAN HEADER ===
class HeaderGreetingSection extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;
  final String? profilePhotoUrl;

  const HeaderGreetingSection({
    super.key,
    required this.userName,
    required this.onProfileTap,
    this.profilePhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider avatarImage;

    if (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty) {
      avatarImage = NetworkImage(profilePhotoUrl!);
    } else {
      avatarImage = const NetworkImage('https://i.pravatar.cc/150?img=12');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Halo, $userName!",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 4),
              Text("Tetap produktif hari ini?", style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
            child: CircleAvatar(radius: 22, backgroundImage: avatarImage, backgroundColor: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime mon = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        DateTime d = mon.add(Duration(days: i));
        bool isT = d.day == now.day && d.month == now.month;
        return Column(
          children: [
            Text(
              ["SEN", "SEL", "RAB", "KAM", "JUM", "SAB", "MIN"][i],
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45),
            ),
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 50,
              decoration: isT
                  ? BoxDecoration(
                color: kYellowAccent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
              )
                  : null,
              child: Center(
                child: Text(
                  d.day.toString(),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class CurrentTaskCard extends StatelessWidget {
  final Map<String, dynamic>? current, next;
  final int countdown;
  const CurrentTaskCard({super.key, this.current, this.next, required this.countdown});

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Default State: Waktu Istirahat (Jika tidak ada kelas atau kelas masih lama)
    String statusText = "WAKTU ISTIRAHAT";
    String title = "Tidak Ada Kelas";
    String info = "Santai sejenak Mahasigma";
    Color statusColor = Colors.grey;
    IconData icon = Icons.bedtime_outlined;

    // KONDISI 1: Kelas Sedang Berlangsung (Prioritas Utama)
    if (current != null) {
      statusText = "SEDANG BERLANGSUNG";
      title = current!['mata_kuliah'];
      info = "Ruangan ${current!['ruangan']} • Selesai ${current!['jam_selesai']}";
      statusColor = Colors.green;
      icon = Icons.menu_book_rounded;
    }
    // KONDISI 2: Countdown (Hanya jika kurang dari 1 jam / 3600 detik)
    else if (countdown > 0 && countdown <= 3600 && next != null) {
      statusText = "KELAS BERIKUTNYA";
      title = next!['mata_kuliah'];
      info = "Mulai dalam ${_formatDuration(countdown)}";
      statusColor = Colors.orange;
      icon = Icons.timer_outlined;
    }
    // KONDISI 3: Kelas Berikutnya Ada, TAPI Masih Lama (> 1 jam)
    else if (next != null) {
      statusText = "AKAN DATANG";
      title = next!['mata_kuliah'];
      // Jika backend mengirim 'jam_mulai', tampilkan. Jika tidak, tampilkan estimasi jam.
      // fallback string.
      String jamMulai = next!['jam_mulai'] ?? "Nanti";
      info = "Mulai pukul $jamMulai";

      statusColor = kYellowAccent;
      icon = Icons.calendar_today_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0xFFE0E0E0), offset: Offset(4, 4), blurRadius: 0)]
      ),
      child: Row(children: [
        Container(
            height: 50, width: 50,
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 1.5)
            ),
            child: Icon(icon, color: Colors.black)
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(statusText, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor == kYellowAccent ? Colors.black54 : statusColor)),
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(info, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ]),
    );
  }
}

class DashboardGrid extends StatelessWidget {
  final int semester, totalMatkul;
  final Function(int) onNavigate;
  final VoidCallback onSemesterTap;
  final VoidCallback onHistoryTap;

  const DashboardGrid({super.key, required this.semester, required this.totalMatkul, required this.onNavigate, required this.onSemesterTap, required this.onHistoryTap});
  @override
  Widget build(BuildContext context) {
    int pending = globalTasks.where((t) => t.serverStatus != 'done' && t.serverStatus != 'expired').length;
    int done = globalTasks.where((t) => t.serverStatus == 'done').length;
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5,
      children: [
        GestureDetector(onTap: () => onNavigate(3), child: _buildStatCard(pending.toString(), "Tugas Belum Dikerjakan", const Color(0xFFFFCCBC), Icons.access_time_filled)),
        GestureDetector(onTap: onHistoryTap, child: _buildStatCard(done.toString(), "Tugas Selesai", const Color(0xFFC8E6C9), Icons.check_circle)),
        GestureDetector(onTap: onSemesterTap, child: _buildStatCard(semester.toString(), "Semester Saat Ini", const Color(0xFFE1BEE7), Icons.school)),
        GestureDetector(onTap: () => onNavigate(1), child: _buildStatCard(totalMatkul.toString(), "Matkul Aktif", const Color(0xFFFFF9C4), Icons.class_rounded)),
      ],
    );
  }
  Widget _buildStatCard(String v, String l, Color c, IconData i) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 1.5), boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(3, 3), blurRadius: 0)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(v, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)), Icon(i, size: 22, color: Colors.black54) ]),
          Text(l, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
        ]));
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({super.key});
  @override
  Widget build(BuildContext context) {
    TaskItem? urgent;
    try { urgent = globalTasks.firstWhere((t) => t.serverStatus == 'urgent'); } catch (_) {}
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("INSIGHTS", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.black54)),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 1.5), boxShadow: const [BoxShadow(color: Color(0xFFE0E0E0), offset: Offset(4, 4), blurRadius: 0)]),
          child: Row(children: [
            Icon(urgent != null ? Icons.warning_rounded : Icons.tips_and_updates_rounded, color: urgent != null ? Colors.red : Colors.orange, size: 26),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(urgent != null ? "Deadline Mendesak!" : "Insight Harian", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(urgent != null ? "Tugas '${urgent.title}' perlu dikerjakan!" : "Tetap semangat belajarnya Mahasigma!", style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
            ]))
          ])),
    ]);
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex; final Function(int) onTap; final bool showDeadlineBadge;
  const CustomBottomNavBar({super.key, required this.selectedIndex, required this.onTap, this.showDeadlineBadge = false});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(left: 30, right: 30, bottom: 30), height: 65, decoration: BoxDecoration(color: kYellowAccent, borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.black, width: 1.5), boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 8)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) {
          IconData icon = [Icons.edit_note, Icons.calendar_month, Icons.home_filled, Icons.assignment, Icons.person][i];
          bool active = selectedIndex == i;
          return GestureDetector(onTap: () => onTap(i), child: Stack(clipBehavior: Clip.none, children: [ Icon(icon, size: active ? 30 : 24), if (i == 3 && showDeadlineBadge) Positioned(top: -2, right: -2, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))) ]));
        })));
  }
}

class ScheduleActionDialog extends StatefulWidget {
  final String title, content; final IconData icon; final Color iconColor, iconBg, btnColor; final VoidCallback onConfirm; final Widget? customInput;
  const ScheduleActionDialog({super.key, required this.title, required this.content, required this.icon, required this.iconColor, required this.iconBg, required this.btnColor, required this.onConfirm, this.customInput});
  @override State<ScheduleActionDialog> createState() => _ScheduleActionDialogState();
}
class _ScheduleActionDialogState extends State<ScheduleActionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); _s = CurvedAnimation(parent: _c, curve: Curves.elasticOut); _c.forward(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Dialog(backgroundColor: kCreamColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2)),
      child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
        ScaleTransition(scale: _s, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: widget.iconBg, shape: BoxShape.circle, border: Border.all(color: widget.iconColor.withValues(alpha: 0.5), width: 1.5)), child: Icon(widget.icon, size: 32, color: widget.iconColor))),
        const SizedBox(height: 16), Text(widget.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), const Divider(color: Colors.black, thickness: 1.5),
        const SizedBox(height: 12), Text(widget.content, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
        if(widget.customInput != null) ...[ const SizedBox(height: 20), widget.customInput! ],
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text("Batal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: widget.onConfirm, style: ElevatedButton.styleFrom(backgroundColor: widget.btnColor, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black, width: 1.5)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text("Lanjutkan", style: TextStyle(fontWeight: FontWeight.bold)))),
        ])
      ])),
    );
  }
}