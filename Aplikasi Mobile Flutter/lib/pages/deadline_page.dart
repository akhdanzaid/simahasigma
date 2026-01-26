import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

// --- KONSTANTA WARNA ---
const Color kCreamColor = Color(0xFFF9F4E8);
const Color kYellowAccent = Color(0xFFFDC25B);
const Color kRedUrgent = Color(0xFFFF8A80);
const Color kGreenDone = Color(0xFFA5D6A7);
const Color kBlueNormal = Color(0xFF90CAF9);
const Color kGreyExpired = Color(0xFFE0E0E0);
const Color kWhite = Colors.white;
const double kBorderWidth = 1.5;
const double kBorderRadius = 16.0;

class DeadlinePage extends StatefulWidget {
  final VoidCallback? onDataChanged;
  // Parameter untuk menerima state awal
  final bool initialShowArchived;

  const DeadlinePage({super.key, this.onDataChanged, this.initialShowArchived = false});

  @override
  State<DeadlinePage> createState() => _DeadlinePageState();
}

class _DeadlinePageState extends State<DeadlinePage> {
  // Hapus inisialisasi langsung
  late bool _showArchived;
  String _selectedSubjectFilter = 'Semua';
  bool _isLoading = true;
  List<String> _availableSubjects = [];

  final Dio _dio = Dio();
  final String _baseUrl = 'https://sim.ujangkedu.my.id';

  @override
  void initState() {
    super.initState();
    // Gunakan nilai dari widget
    _showArchived = widget.initialShowArchived;
    _refreshPageData();
  }

  Future<void> _refreshPageData() async {
    await _fetchSubjects();
    await _fetchTasks();
  }

  void _notifyParent() {
    if (widget.onDataChanged != null) widget.onDataChanged!();
  }

  // --- 1. FETCH MATA KULIAH ---
  Future<void> _fetchSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      final response = await _dio.post(
        '$_baseUrl/get_subjects.php',
        data: FormData.fromMap({'user_id': userId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        setState(() {
          // Trim spasi agar filter akurat
          _availableSubjects = data.map((e) => e.toString().trim()).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
    }
  }

  // --- 2. FETCH TASKS ---
  Future<void> _fetchTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      final response = await _dio.post(
        '$_baseUrl/get_tasks.php',
        data: FormData.fromMap({
          'user_id': userId,
          'subject': _selectedSubjectFilter,
        }),
        options: Options(responseType: ResponseType.plain),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> data = [];
        var rawData = response.data;

        try {
          if (rawData is List) {
            data = rawData;
          } else if (rawData is String) {
            var decoded = jsonDecode(rawData);
            if (decoded is List) data = decoded;
          }
        } catch (e) {
          debugPrint("Error Decode: $e");
        }

        globalTasks.clear();
        for (var json in data) {
          globalTasks.add(TaskItem.fromJson(json));
        }

        setState(() => _isLoading = false);
        _notifyParent();
      }
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- [LOGIKA SORTING & FILTERING GANDA] ---
  List<TaskItem> get _visibleTasks {
    // 1. Ambil data mentah
    Iterable<TaskItem> filteredList = globalTasks;

    // 2. Filter Lokal (Case Insensitive & Trimmed)
    if (_selectedSubjectFilter != 'Semua') {
      filteredList = filteredList.where((t) =>
      t.subject.trim().toLowerCase() == _selectedSubjectFilter.trim().toLowerCase()
      );
    }

    // 3. Filter Status & Sorting
    if (_showArchived) {
      // TAB RIWAYAT: Selesai atau Gagal
      var history = filteredList.where((t) =>
      t.serverStatus == 'done' || t.serverStatus == 'expired'
      ).toList();

      // Sort DESCENDING:
      history.sort((a, b) => b.deadline.compareTo(a.deadline));

      return history;
    } else {
      // TAB AKTIF: Normal atau Mendesak
      var active = filteredList.where((t) =>
      t.serverStatus == 'normal' || t.serverStatus == 'urgent'
      ).toList();

      // Sort ASCENDING: Tugas deadline terdekat (besok/lusa) di atas
      active.sort((a, b) => a.deadline.compareTo(b.deadline));

      return active;
    }
  }

  List<String> get _filterSubjects {
    // Gabungkan matkul dari tugas yang ada dengan matkul dari jadwal
    final subjectsInTasks = globalTasks.map((e) => e.subject.trim()).toSet();
    final combined = {...subjectsInTasks, ..._availableSubjects}.toList();
    // Hapus duplikat dan urutkan abjad jika perlu
    combined.sort();
    return ['Semua', ...combined];
  }

  Future<void> _saveTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/add_task.php',
        data: FormData.fromMap(taskData),
      );

      if (!mounted) return;

      if (response.data['success'] == true || response.data['success'] == 'true') {
        _showSnackBar("Tugas berhasil disimpan!", kGreenDone, Colors.black);
        _fetchTasks();
      } else {
        _showSnackBar("Gagal menyimpan tugas", Colors.red, Colors.white);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", Colors.red, Colors.white);
    }
  }

  Future<void> _markAsDone(String id) async {
    setState(() {
      final index = globalTasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        globalTasks[index].serverStatus = 'done';
        globalTasks[index].isArchived = true;
      }
    });

    _notifyParent();
    _showSnackBar("Tugas Selesai!", kGreenDone, Colors.black);

    try {
      await _dio.post(
          '$_baseUrl/archive_task.php',
          data: FormData.fromMap({'id': id, 'status': 1})
      );
      if (!mounted) return;
      await _fetchTasks();
    } catch (e) {
      if (mounted) {
        _fetchTasks();
        _showSnackBar("Gagal update status server.", Colors.red, Colors.white);
      }
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      final response = await _dio.post(
          '$_baseUrl/delete_task.php',
          data: FormData.fromMap({'id': id})
      );

      if (!mounted) return;

      if (response.data['success'] == true || response.data['success'] == 'true') {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showSnackBar("Tugas dihapus", Colors.red, Colors.white);
        _fetchTasks();
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", Colors.red, Colors.white);
    }
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    final tasksToShow = _visibleTasks;

    return Scaffold(
      backgroundColor: kCreamColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER STICKY
            _buildHeader(),

            // 2. KONTEN SCROLLABLE
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                // [PERBAIKAN 1] Padding top di-set 0 agar list langsung mulai tepat di bawah header
                padding: const EdgeInsets.only(top: 0),
                children: [

                  // [PERBAIKAN 2] HAPUS SizedBox(height: 16) yang ada di sini sebelumnya.
                  // Langsung render Tab Toggle agar posisinya rapat ke header.
                  _buildArchiveToggle(),

                  const SizedBox(height: 16),

                  _buildSubjectFilter(),

                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: kYellowAccent)
                        )
                    )
                  else if (tasksToShow.isEmpty)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      alignment: Alignment.center,
                      child: _buildEmptyState(),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      itemCount: tasksToShow.length,
                      separatorBuilder: (ctx, index) => const SizedBox(height: 16),
                      itemBuilder: (ctx, index) => _buildTaskCard(tasksToShow[index]),
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

  Widget _buildHeader() {
    return Container(
      color: kCreamColor,
      // [PERBAIKAN 3] Ubah padding bawah menjadi 20 (sebelumnya 24) agar sama persis dengan SchedulePage
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Tugas Kuliah", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Kelola deadline tugasmu", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ])),
          ElevatedButton.icon(
              onPressed: () => _showTaskFormDialog(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kYellowAccent,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: kBorderWidth),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              icon: const Icon(Icons.add, size: 20),
              label: Text("Tambah", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12))
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.black, width: kBorderWidth)),
      child: Row(children: [
        _buildToggleBtn("Tugas Aktif", !_showArchived, () => setState(() => _showArchived = false)),
        _buildToggleBtn("Riwayat", _showArchived, () => setState(() => _showArchived = true))
      ]),
    );
  }

  Widget _buildToggleBtn(String text, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: isActive ? kYellowAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              border: isActive ? Border.all(color: Colors.black, width: kBorderWidth) : null),
          child: Center(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ),
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
          children: _filterSubjects.map((subject) {
            final isSelected = _selectedSubjectFilter == subject;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedSubjectFilter = subject);
                _fetchTasks();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                    color: isSelected ? Colors.black : kWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: kBorderWidth)),
                child: Text(subject,
                    style: TextStyle(color: isSelected ? kWhite : Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_showArchived ? Icons.history_edu_rounded : Icons.task_alt_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(_showArchived ? "Belum ada riwayat." : "Semua tugas beres!", style: GoogleFonts.poppins(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    Color barColor;
    String statusLabel;
    TextDecoration? textDecoration;
    Color titleColor = Colors.black;

    switch (task.serverStatus) {
      case 'done':
        barColor = kGreenDone;
        statusLabel = "SELESAI";
        textDecoration = TextDecoration.lineThrough;
        titleColor = Colors.grey;
        break;
      case 'expired':
        barColor = Colors.grey;
        statusLabel = "GAGAL";
        textDecoration = TextDecoration.lineThrough;
        titleColor = Colors.grey;
        break;
      case 'urgent':
        barColor = kRedUrgent;
        statusLabel = "MENDESAK";
        break;
      default:
        barColor = kBlueNormal;
        statusLabel = "AKTIF";
    }

    bool isReadOnly = (task.serverStatus == 'done' || task.serverStatus == 'expired');

    return GestureDetector(
      onTap: () => _showTaskDetail(context, task),
      child: Container(
        decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: Colors.black, width: kBorderWidth),
            boxShadow: const [BoxShadow(color: Color(0xFFE0E0E0), offset: Offset(4, 4))]),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 12, decoration: BoxDecoration(color: barColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(kBorderRadius - 1), bottomLeft: Radius.circular(kBorderRadius - 1)), border: const Border(right: BorderSide(color: Colors.black, width: kBorderWidth)))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(task.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, decoration: textDecoration, color: titleColor)),
                              const SizedBox(height: 4),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)), child: Text(task.subject, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
                            ])),
                        if (isReadOnly)
                          _buildDetailChip(statusLabel, barColor.withValues(alpha: 0.1), barColor)
                        else
                          Transform.scale(scale: 1.2, child: Checkbox(value: false, activeColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), side: const BorderSide(width: 1.5), onChanged: (_) => _markAsDone(task.id))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.timer_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(DateFormat('EEE, dd MMM • HH:mm').format(task.deadline), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (task.serverStatus == 'urgent') ? kRedUrgent : Colors.black54))
                    ])
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetail(BuildContext context, TaskItem task) {
    bool isReadOnly = (task.serverStatus == 'done' || task.serverStatus == 'expired');
    // Logika UI untuk Toggle Mendesak
    bool isUrgentToggle = task.isUrgent;
    bool isDeadlineClose = task.deadline.difference(DateTime.now()).inHours < 48 && task.deadline.isAfter(DateTime.now());

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setDetailState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                    color: kCreamColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    border: Border(top: BorderSide(color: Colors.black, width: 2))
                ),
                child: Column(children: [
                  // Drag Handle
                  Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10))
                  ),

                  Expanded(
                    child: ListView(padding: const EdgeInsets.all(24), children: [

                      // --- HEADER ROW (JUDUL + ICON EDIT & CLOSE) ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Sejajar di atas
                        children: [
                          Expanded(
                              child: Text(task.title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold))
                          ),

                          // [REVISI UI] Tombol Edit Polos
                          if (!isReadOnly) ...[
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showTaskFormDialog(context, editTask: task);
                              },
                              // Icon edit outlined agar terlihat bersih
                              icon: const Icon(Icons.edit_outlined, size: 24, color: Colors.black),
                              tooltip: "Edit Tugas",
                              // Sedikit visual density agar rapi sejajar text
                              visualDensity: VisualDensity.compact,
                            ),

                            // Jarak agar tidak terlalu dekat dengan X
                            const SizedBox(width: 4),
                          ],

                          // Tombol Close
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 28),
                            visualDensity: VisualDensity.compact,
                          )
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Chips Status (Subject, Status)
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _buildDetailChip(task.subject, Colors.white, Colors.black),
                        if (task.serverStatus == 'done') _buildDetailChip("SELESAI", kGreenDone, Colors.black),
                        if (task.serverStatus == 'expired') _buildDetailChip("GAGAL", Colors.grey, Colors.white),
                        if (task.serverStatus == 'urgent') _buildDetailChip("MENDESAK", kRedUrgent, Colors.black),
                      ]),

                      const SizedBox(height: 24),

                      // Toggle Mendesak
                      if (!isReadOnly)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 1.5)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text("Tandai Mendesak", style: TextStyle(fontWeight: FontWeight.bold)),
                              if(isDeadlineClose) const Text("Otomatis (Tenggat < 2 hari)", style: TextStyle(fontSize: 10, color: kRedUrgent, fontWeight: FontWeight.bold)),
                            ]),
                            Switch(
                              value: isDeadlineClose ? true : isUrgentToggle,
                              activeThumbColor: kRedUrgent,
                              onChanged: isDeadlineClose ? null : (val) async {
                                final prefs = await SharedPreferences.getInstance();
                                final int userId = prefs.getInt('user_id') ?? 1;
                                setDetailState(() => isUrgentToggle = val);
                                _saveTask({
                                  'id': task.id,
                                  'user_id': userId,
                                  'judul_tugas': task.title,
                                  'mata_kuliah': task.subject,
                                  'tenggat_waktu': DateFormat('yyyy-MM-dd HH:mm:ss').format(task.deadline),
                                  'mendesak': val ? 1 : 0
                                });
                              },
                            )
                          ]),
                        ),

                      const SizedBox(height: 24),

                      // Deskripsi
                      _buildDetailSectionLabel("Deskripsi"),
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(task.description.isEmpty ? "-" : task.description)
                      ),

                      const SizedBox(height: 20),

                      // Link Pengumpulan
                      _buildDetailSectionLabel("Link Pengumpulan"),
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.blue[50],
                              border: Border.all(color: Colors.blue, width: 1.5),
                              borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(
                              task.submissionLink?.isEmpty ?? true ? "-" : task.submissionLink!,
                              style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)
                          )
                      ),

                      const SizedBox(height: 30),

                      // Tombol Aksi
                      if (!isReadOnly)
                        SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: kGreenDone, foregroundColor: Colors.black, side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                onPressed: () { Navigator.pop(context); _markAsDone(task.id); },
                                icon: const Icon(Icons.check),
                                label: const Text("Tandai Selesai")
                            )
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, side: const BorderSide(color: Colors.red, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () => _showDeleteConfirmDialog(context, task.id),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text("Hapus Tugas")
                          )
                      )
                    ]),
                  ),
                ]),
              );
            }
        ));
  }

  void _showTaskFormDialog(BuildContext context, {TaskItem? editTask}) {
    final titleController = TextEditingController(text: editTask?.title ?? '');
    final descController = TextEditingController(text: editTask?.description ?? '');
    final linkController = TextEditingController(text: editTask?.submissionLink ?? '');

    String? selectedSubject = editTask?.subject ?? (_availableSubjects.isNotEmpty ? _availableSubjects.first : null);
    DateTime selectedDate = editTask?.deadline ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = editTask != null ? TimeOfDay(hour: editTask.deadline.hour, minute: editTask.deadline.minute) : const TimeOfDay(hour: 23, minute: 59);

    // [TAMBAHAN] State untuk pesan error
    String? titleErr, subjErr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(color: kCreamColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), border: Border(top: BorderSide(color: Colors.black, width: 2))),
            child: Column(children: [
              // 1. Drag Handle
              Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10))
              ),

              // 2. Header Row (Judul & Close)
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(editTask == null ? "Tambah Tugas" : "Edit Tugas", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))
                      ]
                  )
              ),

              const Divider(height: 1, color: Colors.black12),

              Expanded(
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  _buildFormLabel("Judul Tugas"),
                  // [FIX] Tambahkan errorText
                  _buildTextField(titleController, "Masukkan nama tugas", errorText: titleErr),
                  const SizedBox(height: 16),
                  _buildFormLabel("Mata Kuliah"),
                  _availableSubjects.isEmpty
                      ? const Text("Tambahkan Jadwal Terlebih Dahulu", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(12),
                                // [FIX] Border merah jika error
                                border: Border.all(color: subjErr != null ? kRedUrgent : Colors.black, width: kBorderWidth)
                            ),
                            child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                    value: selectedSubject,
                                    isExpanded: true,
                                    items: _availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                    onChanged: (val) => setModalState(() => selectedSubject = val)
                                )
                            )
                        ),
                        if (subjErr != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(subjErr!, style: const TextStyle(color: kRedUrgent, fontSize: 12)),
                          )
                      ]
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- KOLOM TANGGAL ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel("Tenggat Waktu"),
                            GestureDetector(
                              onTap: () async {
                                final p = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100));
                                if (p != null) setModalState(() => selectedDate = p);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                    color: kWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: kBorderWidth)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.black54),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd MMM yyyy').format(selectedDate),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(width: 16), // Spasi antar kolom

                      // --- KOLOM JAM ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel("Jam"),
                            GestureDetector(
                              onTap: () async {
                                final p = await showTimePicker(
                                    context: context, initialTime: selectedTime);
                                if (p != null) setModalState(() => selectedTime = p);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                    color: kWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: kBorderWidth)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 20, color: Colors.black54),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedTime.format(context),
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _buildFormLabel("Deskripsi"),
                  _buildTextField(descController, "Detail tugasnya", maxLines: 3),
                  const SizedBox(height: 16),
                  _buildFormLabel("Link Pengumpulan"),
                  _buildTextField(linkController, "LInk Pengumpulannya"),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black, width: kBorderWidth))), onPressed: () async {
                    // [TAMBAHAN] Validasi Input
                    setModalState(() { titleErr = null; subjErr = null; });
                    bool isValid = true;
                    if (titleController.text.isEmpty) { setModalState(() => titleErr = "Wajib diisi"); isValid = false; }
                    if (selectedSubject == null) { setModalState(() => subjErr = "Pilih mata kuliah"); isValid = false; }

                    if (!isValid) return; // Stop jika error

                    final prefs = await SharedPreferences.getInstance();

                    if (!mounted) return;

                    final int userId = prefs.getInt('user_id') ?? 1;
                    DateTime finalDeadline = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);

                    _showSaveConfirmDialog(context, () {
                      _saveTask({
                        'user_id': userId,
                        'judul_tugas': titleController.text,
                        'mata_kuliah': selectedSubject,
                        'deskripsi': descController.text,
                        'tenggat_waktu': DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDeadline),
                        'link_pengumpulan': linkController.text,
                        'mendesak': editTask?.isUrgent ?? false ? 1 : 0,
                        if(editTask != null) 'id': editTask.id,
                      });
                      Navigator.pop(context);
                    });
                  }, child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),

                  Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
                ]),
              )
            ]),
          );
        },
      ),
    );
  }

  Widget _buildDetailChip(String label, Color bg, Color text) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 1.5)), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)));
  Widget _buildDetailSectionLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)));
  Widget _buildFormLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)));

  // Update TextField untuk support Error Text & Styling Merah
  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, String? errorText}) =>
      TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
              hintText: hint,
              errorText: errorText, // Tampilkan error
              filled: true,
              fillColor: kWhite,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: kBorderWidth)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
              // Styling Border Merah
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRedUrgent, width: 2.0)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRedUrgent, width: 2.0))
          )
      );

  void _showSnackBar(String m, Color bg, Color t) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: TextStyle(color: t, fontWeight: FontWeight.bold)), backgroundColor: bg, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black)))); }
  void _showSaveConfirmDialog(BuildContext context, VoidCallback onConfirm) { showDialog(context: context, builder: (context) => SaveConfirmationDialog(onConfirm: onConfirm)); }
  void _showDeleteConfirmDialog(BuildContext context, String id) { showDialog(context: context, builder: (context) => DeleteConfirmationDialog(onConfirm: () => _deleteTask(id))); }
}

// --- DIALOG REUSABLE ---

class SaveConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const SaveConfirmationDialog({super.key, required this.onConfirm});

  @override
  State<SaveConfirmationDialog> createState() => _SaveConfirmationDialogState();
}

class _SaveConfirmationDialogState extends State<SaveConfirmationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCreamColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kGreenDone.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                  child: const Icon(Icons.check_circle_outline_rounded, size: 32, color: Colors.black)
              )
          ),
          const SizedBox(height: 16),
          Text("Simpan Tugas?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 12),
          Text("Pastikan data sudah benar", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text("Batal", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold))
                )
            ),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); widget.onConfirm(); },
                    style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black, width: 1.5)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text("Simpan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold))
                )
            )
          ])
        ]),
      ),
    );
  }
}

class DeleteConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const DeleteConfirmationDialog({super.key, required this.onConfirm});
  @override State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300)); _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut); _controller.forward(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCreamColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 1.5)),
                  child: const Icon(Icons.delete_forever_rounded, size: 32, color: Colors.red)
              )
          ),
          const SizedBox(height: 16),
          Text("Hapus Tugas?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 12),
          Text("Data tugas ini akan dihapus permanen", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text("Batal", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold))
                )
            ),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); widget.onConfirm(); },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black, width: 1.5)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text("Hapus", style: GoogleFonts.poppins(fontWeight: FontWeight.bold))
                )
            )
          ])
        ]),
      ),
    );
  }
}