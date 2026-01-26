import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- KONSTANTA WARNA ---
const Color kCreamColor = Color(0xFFF9F4E8);
const Color kYellowAccent = Color(0xFFFDC25B);
const Color kTealColor = Color(0xFF539E94);
const Color kRedUrgent = Color(0xFFFF8A80);
const Color kGreenAccent = Color(0xFFA5D6A7);
const Color kWhite = Colors.white;
const double kBorderWidth = 1.5;
const double kBorderRadius = 16.0;

// --- HELPERS ---
TimeOfDay stringToTime(String timeStr) {
  try {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  } catch (e) { return const TimeOfDay(hour: 0, minute: 0); }
}

String timeToString(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String getIndonesianDayName(int weekday) {
  switch (weekday) {
    case 1: return 'Senin';
    case 2: return 'Selasa';
    case 3: return 'Rabu';
    case 4: return 'Kamis';
    case 5: return 'Jumat';
    case 6: return 'Sabtu';
    case 7: return 'Minggu';
    default: return 'Senin';
  }
}

// --- MODEL ---
class ClassSchedule {
  final String id, subject, lecturer, room, day, type;
  final TimeOfDay startTime, endTime;
  final int semester;
  final DateTime? startDate;
  final bool isArchived;

  ClassSchedule({
    required this.id, required this.subject, required this.lecturer, required this.room,
    required this.day, required this.startTime, required this.endTime, required this.type,
    required this.semester, this.startDate, this.isArchived = false,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'].toString(),
      subject: json['mata_kuliah'] ?? '-',
      lecturer: json['dosen'] ?? '-',
      room: json['ruangan'] ?? '-',
      day: json['hari'] ?? 'Senin',
      startTime: stringToTime(json['jam_mulai'] ?? '00:00'),
      endTime: stringToTime(json['jam_selesai'] ?? '00:00'),
      type: json['jenis_kelas'] ?? 'Teori',
      semester: int.tryParse(json['semester'].toString()) ?? 1,
      startDate: json['tgl_mulai'] != null ? DateTime.parse(json['tgl_mulai']) : null,
      isArchived: json['diarsipkan'] == '1' || json['diarsipkan'] == 1,
    );
  }
}

class SchedulePage extends StatefulWidget {
  final VoidCallback? onDataChanged;
  const SchedulePage({super.key, this.onDataChanged});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showArchived = false;
  bool _isLoading = true;
  List<ClassSchedule> _allSchedules = [];
  String _selectedSemesterFilter = 'Semua';
  List<String> _availableSemesters = ['Semua'];
  int _semesterSaatIni = 1;

  final Dio _dio = Dio();
  final String _baseUrl = 'https://sim.ujangkedu.my.id';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await _fetchUserSemester();
    await _fetchSchedules();
  }

  // --- API LOGIC ---
  Future<void> _fetchUserSemester() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      final res = await _dio.post('$_baseUrl/get_profile.php', data: FormData.fromMap({'user_id': userId}));
      if (!mounted) return;
      if (res.data['success']) {
        setState(() {
          _semesterSaatIni = int.tryParse(res.data['data']['semester_saat_ini'].toString()) ?? 1;
        });
      }
    } catch (e) { debugPrint("Error Semester: $e"); }
  }

  Future<void> _fetchSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      final response = await _dio.post('$_baseUrl/get_schedules.php', data: FormData.fromMap({
        'user_id': userId,
        'is_archived': _showArchived ? 1 : 0,
        'semester': _selectedSemesterFilter
      }));

      if (!mounted) return;
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        List<ClassSchedule> loaded = data.map((j) => ClassSchedule.fromJson(j)).toList();
        setState(() {
          _allSchedules = loaded;
          _isLoading = false;
          if (_showArchived && _selectedSemesterFilter == 'Semua') {
            _updateAvailableSemesters(loaded);
          }
        });
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  void _updateAvailableSemesters(List<ClassSchedule> data) {
    Set<String> sems = {'Semua'};
    for (var i in data) {
      sems.add(i.semester.toString());
    }
    var sorted = sems.toList()..sort((a, b) => a == 'Semua' ? -1 : b == 'Semua' ? 1 : int.parse(a).compareTo(int.parse(b)));
    setState(() => _availableSemesters = sorted);
  }

  Future<void> _addOrUpdateSchedule(ClassSchedule s, {bool isUpdate = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      Map<String, dynamic> body = {
        'user_id': userId,
        'mata_kuliah': s.subject, 'dosen': s.lecturer, 'ruangan': s.room,
        'hari': s.day, 'jam_mulai': timeToString(s.startTime), 'jam_selesai': timeToString(s.endTime),
        'jenis_kelas': s.type, 'semester': s.semester, 'tgl_mulai': s.startDate != null ? DateFormat('yyyy-MM-dd').format(s.startDate!) : null,
      };
      if (isUpdate) body['id'] = s.id;

      final res = await _dio.post('$_baseUrl/add_schedules.php', data: FormData.fromMap(body));
      if (!mounted) return;
      if (res.data['success'] == true) {
        _showSnackBar("Jadwal disimpan!", kGreenAccent);
        _fetchSchedules();
        widget.onDataChanged?.call();
      }
    } catch (e) { _showSnackBar("Gagal memproses data.", Colors.red); }
  }

  Future<void> _archiveSchedule(String id, {bool isRestore = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _dio.post('$_baseUrl/archive_schedule.php', data: FormData.fromMap({
        'id': id,
        'status': isRestore ? '0' : '1'
      }));
      if (!mounted) return;
      if (res.data['success'] == true) {
        _showSnackBar(isRestore ? "Jadwal dipulihkan ke Aktif!" : "Jadwal diarsipkan!", kGreenAccent);
        await _fetchSchedules();
        widget.onDataChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Gagal memproses pengarsipan.", Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSchedule(String id) async {
    try {
      final res = await _dio.post('$_baseUrl/delete_schedules.php', data: FormData.fromMap({'id': id}));
      if (!mounted) return;
      if (res.data['success'] == true) {
        _showSnackBar("Jadwal dihapus.", kRedUrgent);
        _fetchSchedules();
        widget.onDataChanged?.call();
      }
    } catch (e) { if (mounted) _showSnackBar("Error menghapus.", Colors.red); }
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 0),
                children: [
                  _buildTabToggle(),
                  const SizedBox(height: 16),

                  if (!_showArchived) ...[
                    _buildStylishCalendar(),
                    const SizedBox(height: 24)
                  ] else ...[
                    _buildSemesterFilter(),
                    const SizedBox(height: 16)
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            _showArchived
                                ? "Arsip Semester $_selectedSemesterFilter"
                                : "Jadwal Hari Ini",
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 12),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator(color: kTealColor))
                            : _showArchived ? _buildArchivedList() : _buildScheduleList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 140),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Jadwal Kuliah", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Atur kegiatan akademikmu", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ]),
        ElevatedButton.icon(onPressed: () => _showFormDialog(context),
            style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: Colors.black, side: const BorderSide(color: Colors.black, width: kBorderWidth), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
            icon: const Icon(Icons.add, size: 20), label: Text("Tambah", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12))),
      ]),
    );
  }

  Widget _buildTabToggle() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.black, width: kBorderWidth)),
      child: Row(children: [
        _buildToggleBtn("Jadwal Aktif", !_showArchived, () { setState(() { _showArchived = false; _selectedDay = DateTime.now(); }); _fetchSchedules(); }),
        _buildToggleBtn("Arsip Kelas", _showArchived, () { setState(() { _showArchived = true; _selectedSemesterFilter = 'Semua'; }); _fetchSchedules(); }),
      ]),
    );
  }

  Widget _buildToggleBtn(String t, bool isActive, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: isActive ? kYellowAccent : Colors.transparent, borderRadius: BorderRadius.circular(50), border: isActive ? Border.all(color: Colors.black, width: kBorderWidth) : null),
        child: Center(child: Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))))));
  }

  Widget _buildStylishCalendar() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: kBorderWidth), boxShadow: const [BoxShadow(color: Color(0xFFE0E0E0), offset: Offset(4, 4), blurRadius: 0)]),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), decoration: const BoxDecoration(color: kTealColor, borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1))),
              Text(DateFormat('MMMM yyyy').format(_focusedDay), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))),
            ])),
        TableCalendar(firstDay: DateTime.utc(2020), lastDay: DateTime.utc(2030), focusedDay: _focusedDay, calendarFormat: _calendarFormat, selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              String dayName = getIndonesianDayName(day.weekday);
              return _allSchedules.where((s) {
                if (s.isArchived) return false;
                if (s.day != dayName) return false;
                if (s.startDate != null) {
                  DateTime startCheck = DateTime(s.startDate!.year, s.startDate!.month, s.startDate!.day);
                  DateTime dayCheck = DateTime(day.year, day.month, day.day);
                  DateTime endCheck = startCheck.add(const Duration(days: 18 * 7));
                  return (dayCheck.isAtSameMomentAs(startCheck) || dayCheck.isAfter(startCheck)) && dayCheck.isBefore(endCheck);
                }
                return true;
              }).toList();
            },
            headerVisible: false, daysOfWeekVisible: false,
            calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: kTealColor.withValues(alpha: 0.3), shape: BoxShape.circle),
                selectedDecoration: const BoxDecoration(color: kTealColor, shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: kYellowAccent, shape: BoxShape.circle)
            ),
            onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; })),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildScheduleList() {
    final evs = _allSchedules.where((s) => s.day == getIndonesianDayName(_selectedDay!.weekday)).toList();
    if (evs.isEmpty) return _buildEmptyState("Tidak ada jadwal hari ini");

    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: evs.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
        itemBuilder: (ctx, i) => _buildScheduleCard(evs[i])
    );
  }

  Widget _buildArchivedList() {
    if (_allSchedules.isEmpty) return _buildEmptyState("Belum ada arsip");

    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _allSchedules.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
        itemBuilder: (ctx, i) => _buildScheduleCard(_allSchedules[i])
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ const Icon(Icons.event_note_rounded, size: 50, color: Colors.black12), const SizedBox(height: 10), Text(msg, style: GoogleFonts.poppins(color: Colors.black45)) ]));
  }

  Widget _buildScheduleCard(ClassSchedule s) {
    return InkWell(onTap: () => _showFormDialog(context, schedule: s), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12, width: 1)),
        child: Row(children: [
          Container(height: 50, width: 50, decoration: BoxDecoration(color: s.type == 'Teori' ? const Color(0xFFE1BEE7) : const Color(0xFFC8E6C9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 1)), child: Icon(s.type == 'Teori' ? Icons.menu_book : Icons.computer, color: Colors.black, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.subject, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(s.lecturer, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [ _buildMiniTag(s.type, Colors.black, Colors.white), _buildMiniTag("Smt ${s.semester}", Colors.grey[200]!, Colors.black) ])
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("${s.startTime.format(context)} - ${s.endTime.format(context)}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: kTealColor)),
            Text(s.room, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
            if (_showArchived) Text(s.day, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
          ])
        ])),
    );
  }

  Widget _buildMiniTag(String t, Color bg, Color fg) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)), child: Text(t, style: GoogleFonts.poppins(fontSize: 9, color: fg)));

  Widget _buildSemesterFilter() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 24), height: 35,
      child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _availableSemesters.length, separatorBuilder: (ctx, i) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final sem = _availableSemesters[i];
            bool isS = _selectedSemesterFilter == sem;
            return GestureDetector(onTap: () { setState(() => _selectedSemesterFilter = sem); _fetchSchedules(); },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: isS ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 1)),
                    child: Center(child: Text(sem == 'Semua' ? "Semua" : "Smt $sem", style: GoogleFonts.poppins(color: isS ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.bold)))));
          }),
    );
  }

  void _showFormDialog(BuildContext context, {ClassSchedule? schedule}) {
    final subCtrl = TextEditingController(text: schedule?.subject ?? '');
    final lecCtrl = TextEditingController(text: schedule?.lecturer ?? '');
    final romCtrl = TextEditingController(text: schedule?.room ?? '');

    // [MODIFIKASI] Hapus controller text, ganti dengan variabel state untuk dropdown
    int? selectedSem = schedule?.semester;
    final List<int> semesterOptions = [1, 2, 3, 4, 5, 6, 7, 8];

    TimeOfDay sT = schedule?.startTime ?? TimeOfDay.now();
    TimeOfDay eT = schedule?.endTime ?? TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
    DateTime sD = schedule?.startDate ?? DateTime.now();
    String sType = schedule?.type ?? 'Teori';
    String sDay = schedule?.day ?? getIndonesianDayName(_selectedDay!.weekday);
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    bool isEdit = schedule != null;
    bool canRestore = isEdit && _showArchived && (schedule.semester >= _semesterSaatIni);

    String? subErr, semErr, lecErr, romErr;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => StatefulBuilder(builder: (context, setS) {
      return Container(height: MediaQuery.of(context).size.height * 0.9, decoration: const BoxDecoration(color: kCreamColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), border: Border(top: BorderSide(color: Colors.black, width: 2))), padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(width: 60, height: 5, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(isEdit ? "Edit Matkul" : "Tambah Matkul", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)) ]),
            const Divider(thickness: 1.5, color: Colors.black12),
            Expanded(child: ListView(physics: const BouncingScrollPhysics(), children: [
              Row(children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _buildLabel("Mata Kuliah"), _buildTextField(subCtrl, "Nama Matkul", errorText: subErr) ])),
                const SizedBox(width: 12),
                // [MODIFIKASI] Bagian Dropdown Semester
                Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel("Smt"),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          // Ubah warna border jadi merah jika ada error (semErr)
                          border: Border.all(color: semErr != null ? kRedUrgent : Colors.black, width: semErr != null ? 2.0 : kBorderWidth),
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                              value: selectedSem,
                              isExpanded: true,
                              hint: Text("-", style: GoogleFonts.poppins()),
                              items: semesterOptions.map((e) => DropdownMenuItem(value: e, child: Center(child: Text(e.toString(), style: GoogleFonts.poppins())))).toList(),
                              onChanged: (v) => setS(() => selectedSem = v)
                          )
                      )
                  )
                ]))
              ]),
              const SizedBox(height: 16),
              _buildLabel("Dosen Pengampu"), _buildTextField(lecCtrl, "Nama Dosen", errorText: lecErr),
              const SizedBox(height: 16),
              _buildLabel("Jenis Kelas"), Row(children: [ _buildRadioButton("Teori", sType, (v) => setS(() => sType = v)), const SizedBox(width: 12), _buildRadioButton("Praktek", sType, (v) => setS(() => sType = v)) ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _buildLabel("Hari"), Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: kBorderWidth), borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: sDay, isExpanded: true, items: days.map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.poppins()))).toList(), onChanged: (v) => setS(() => sDay = v!)))) ])),
                const SizedBox(width: 12), Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _buildLabel("Ruangan"), _buildTextField(romCtrl, "Ex: 410", errorText: romErr) ]))
              ]),
              const SizedBox(height: 16),
              _buildLabel("Tanggal Mulai (Start)"), GestureDetector(onTap: () async { final p = await showDatePicker(context: context, initialDate: sD, firstDate: DateTime(2020), lastDate: DateTime(2030)); if(p != null) setS(() => sD = p); }, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: kBorderWidth), borderRadius: BorderRadius.circular(12)), child: Row(children: [ const Icon(Icons.calendar_today, size: 18), const SizedBox(width: 12), Text(DateFormat('dd MMMM yyyy').format(sD), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)) ]))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _buildLabel("Jam Mulai"), GestureDetector(onTap: () async { final p = await showTimePicker(context: context, initialTime: sT); if(p != null) setS(() => sT = p); }, child: _buildTimeContainer(sT.format(context))) ])),
                const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _buildLabel("Jam Selesai"), GestureDetector(onTap: () async { final p = await showTimePicker(context: context, initialTime: eT); if(p != null) setS(() => eT = p); }, child: _buildTimeContainer(eT.format(context))) ]))
              ]),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black, width: kBorderWidth))),
                  onPressed: () {
                    setS(() { subErr = null; semErr = null; lecErr = null; romErr = null; });
                    bool isValid = true;
                    if (subCtrl.text.isEmpty) { setS(() => subErr = "Wajib diisi"); isValid = false; }

                    // [MODIFIKASI] Validasi variabel selectedSem, bukan controller text
                    if (selectedSem == null) { setS(() => semErr = "!"); isValid = false; }

                    if (lecCtrl.text.isEmpty) { setS(() => lecErr = "Wajib diisi"); isValid = false; }
                    if (romCtrl.text.isEmpty) { setS(() => romErr = "Wajib diisi"); isValid = false; }

                    if (!isValid) return;

                    _showSaveConfirmDialog(context, () {
                      // [MODIFIKASI] Menggunakan selectedSem ?? 1 saat save
                      final n = ClassSchedule(id: schedule?.id ?? '', subject: subCtrl.text, lecturer: lecCtrl.text, room: romCtrl.text, day: sDay, startTime: sT, endTime: eT, type: sType, semester: selectedSem ?? 1, startDate: sD);
                      _addOrUpdateSchedule(n, isUpdate: schedule != null); Navigator.pop(ctx); }); }, child: Text("Simpan Jadwal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)))),
              if (isEdit && _showArchived) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
                  onPressed: canRestore ? () async {
                    Navigator.pop(ctx);
                    await _archiveSchedule(schedule.id, isRestore: true);
                  } : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: canRestore ? kGreenAccent : Colors.grey[300],
                      foregroundColor: canRestore ? Colors.black : Colors.grey[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: canRestore ? Colors.black : Colors.grey[400]!, width: kBorderWidth))
                  ),
                  icon: const Icon(Icons.unarchive_outlined),
                  label: Text(canRestore ? "Pulihkan ke Jadwal Aktif" : "Masa Lalu (Gak Bisa Pulih)",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                )),
              ],
              if (schedule != null && !_showArchived) ...[
                const SizedBox(height: 16), const Divider(thickness: 1.5, color: Colors.black12), const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => _showArchiveConfirmDialog(context, schedule.id), style: ElevatedButton.styleFrom(backgroundColor: kTealColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black, width: kBorderWidth))), icon: const Icon(Icons.archive_outlined), label: Text("Arsipkan Kelas (Selesai)", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)))),
              ],
              if (schedule != null) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => _showDeleteConfirmDialog(context, schedule.id), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.red, width: kBorderWidth))), icon: const Icon(Icons.delete), label: Text("Hapus Kelas", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)))),
              ],
              const SizedBox(height: 20),
            ]))
          ]));
    }));
  }
  // --- HELPERS UI ---
  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)));

  // parameter errorText dan styling untuk errorBorder
  Widget _buildTextField(TextEditingController c, String h, {bool isNumber = false, String? errorText}) =>
      TextField(
          controller: c,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
              hintText: h,
              errorText: errorText, // Menampilkan teks error jika ada
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: kBorderWidth)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
              // Styling tambahan untuk status Error
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRedUrgent, width: 2.0)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRedUrgent, width: 2.0))
          ));

  Widget _buildTimeContainer(String t) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: kBorderWidth), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.bold))));
  Widget _buildRadioButton(String v, String gv, Function(String) onC) { bool isS = v == gv; return GestureDetector(onTap: () => onC(v), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: isS ? Colors.black : Colors.white, border: Border.all(color: Colors.black, width: kBorderWidth), borderRadius: BorderRadius.circular(20)), child: Text(v, style: GoogleFonts.poppins(color: isS ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w600)))); }

  void _showSnackBar(String m, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: bg, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black))
    ));
  }

  void _showSaveConfirmDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(context: context, builder: (context) => ScheduleActionDialog(title: "Simpan Data?", content: "Pastikan data jadwal sudah benar sebelum menyimpan.", icon: Icons.check_circle_outline_rounded, iconColor: Colors.black, iconBg: kGreenAccent.withValues(alpha: 0.2), btnColor: kYellowAccent, onConfirm: onConfirm));
  }
  void _showArchiveConfirmDialog(BuildContext context, String id) {
    showDialog(context: context, builder: (context) => ScheduleActionDialog(title: "Arsipkan Kelas?", content: "Jadwal ini akan dipindahkan ke tab arsip.", icon: Icons.archive_outlined, iconColor: Colors.black, iconBg: kTealColor.withValues(alpha: 0.2), btnColor: kTealColor, onConfirm: () { Navigator.pop(context); _archiveSchedule(id); }));
  }
  void _showDeleteConfirmDialog(BuildContext context, String id) {
    showDialog(context: context, builder: (context) => ScheduleActionDialog(title: "Hapus Kelas?", content: "Data akan dihapus permanen.", icon: Icons.delete_forever_rounded, iconColor: Colors.red, iconBg: Colors.red[50]!.withValues(alpha: 0.5), btnColor: Colors.red, onConfirm: () { Navigator.pop(context); _deleteSchedule(id); }));
  }
}

// --- REUSABLE DIALOG ---
class ScheduleActionDialog extends StatefulWidget {
  final String title, content; final IconData icon; final Color iconColor, iconBg, btnColor; final VoidCallback onConfirm;
  final Widget? customInput;
  const ScheduleActionDialog({super.key, required this.title, required this.content, required this.icon, required this.iconColor, required this.iconBg, required this.btnColor, required this.onConfirm, this.customInput});
  @override State<ScheduleActionDialog> createState() => _ScheduleActionDialogState();
}
class _ScheduleActionDialogState extends State<ScheduleActionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); _s = CurvedAnimation(parent: _c, curve: Curves.elasticOut); _c.forward(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override build(BuildContext context) {
    return Dialog(backgroundColor: kCreamColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2)),
      child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
        ScaleTransition(scale: _s, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: widget.iconBg, shape: BoxShape.circle, border: Border.all(color: widget.iconColor.withValues(alpha: 0.5), width: 1.5)), child: Icon(widget.icon, size: 32, color: widget.iconColor))),
        const SizedBox(height: 16), Text(widget.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), const Divider(color: Colors.black, thickness: 1.5), const SizedBox(height: 12),
        Text(widget.content, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
        if(widget.customInput != null) ...[ const SizedBox(height: 16), widget.customInput! ],
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)), child: Text("Batal", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); widget.onConfirm(); }, style: ElevatedButton.styleFrom(backgroundColor: widget.btnColor, foregroundColor: widget.btnColor == kYellowAccent ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black, width: 1.5)), padding: const EdgeInsets.symmetric(vertical: 12)), child: Text("Lanjutkan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold))))
        ])
      ])),
    );
  }
}