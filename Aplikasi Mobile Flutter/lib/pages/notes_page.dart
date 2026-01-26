import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- KONSTANTA WARNA ---
const Color kCreamColor = Color(0xFFF9F4E8);
const Color kYellowAccent = Color(0xFFFDC25B);
const Color kGreenAccent = Color(0xFFA5D6A7);
const Color kRedUrgent = Color(0xFFFF8A80);
const Color kWhite = Colors.white;
const double kBorderWidth = 1.5;
const double kBorderRadius = 12.0;

final List<Color> kNoteColors = [
  const Color(0xFFFFF59D), const Color(0xFFA5D6A7), const Color(0xFF90CAF9),
  const Color(0xFFEF9A9A), const Color(0xFFCE93D8), const Color(0xFFFFCC80),
];

class NoteItem {
  final String id, title, content;
  final DateTime date;
  final Color color;
  bool isPinned;

  NoteItem({required this.id, required this.title, required this.content, required this.date, required this.color, this.isPinned = false});

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    Color parseColor(String? colorStr) {
      if (colorStr == null || colorStr.isEmpty) return kNoteColors[0];
      try {
        return Color(int.parse(colorStr));
      } catch (e) { return kNoteColors[0]; }
    }
    return NoteItem(
      id: json['id'].toString(),
      title: json['judul'] ?? '',
      content: json['isi'] ?? '',
      date: DateTime.parse(json['created_at']),
      color: parseColor(json['kode_warna']),
      isPinned: json['disematkan'] == true || json['disematkan'] == '1' || json['disematkan'] == 1,
    );
  }
}

class NotesPage extends StatefulWidget {
  final VoidCallback? onDataChanged;
  const NotesPage({super.key, this.onDataChanged});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<NoteItem> _allNotes = [];
  List<NoteItem> _filteredNotes = [];
  bool _isLoading = true;
  final Dio _dio = Dio();
  final String _baseUrl = 'https://sim.ujangkedu.my.id';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  void _filterNotes(String query) {
    setState(() {
      _filteredNotes = _allNotes
          .where((note) =>
      note.title.toLowerCase().contains(query.toLowerCase()) ||
          note.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // --- AMBIL CATATAN BERDASARKAN USER_ID DINAMIS ---
  Future<void> _fetchNotes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      final response = await _dio.post('$_baseUrl/get_notes.php', data: FormData.fromMap({'user_id': userId}));
      if (response.statusCode == 200 && mounted) {
        List<dynamic> data = response.data;
        List<NoteItem> loaded = data.map((json) => NoteItem.fromJson(json)).toList();

        loaded.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.date.compareTo(a.date);
        });

        setState(() {
          _allNotes = loaded;
          _filteredNotes = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar("Gagal memuat catatan", Colors.red, Colors.white);
    }
  }

  // --- SIMPAN CATATAN BERDASARKAN USER_ID DINAMIS ---
  Future<void> _addOrUpdateNote({String? id, required String title, required String content, required Color color}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 1;

      final response = await _dio.post('$_baseUrl/add_note.php', data: FormData.fromMap({
        'user_id': userId,
        'id': id,
        'judul': title,
        'isi': content,
        'kode_warna': color.toARGB32().toString(),
      }));

      if (response.data['success'] == true && mounted) {
        _showSnackBar("Catatan disimpan!", kGreenAccent, Colors.black);
        _fetchNotes();
        widget.onDataChanged?.call();
      }
    } catch (e) { _showSnackBar("Error API", Colors.red, Colors.white); }
  }

  Future<void> _togglePin(NoteItem note) async {
    bool newStatus = !note.isPinned;
    try {
      final response = await _dio.post('$_baseUrl/pin_note.php', data: FormData.fromMap({
        'id': note.id, 'pin_status': newStatus ? 1 : 0,
      }));
      if (response.data['success'] == true && mounted) {
        _fetchNotes();
      }
    } catch (e) { _fetchNotes(); }
  }

  Future<void> _deleteNote(String id) async {
    try {
      final response = await _dio.post('$_baseUrl/delete_note.php', data: FormData.fromMap({'id': id}));
      if (response.data['success'] == true && mounted) {
        _showSnackBar("Catatan dihapus.", Colors.red, Colors.white);
        _fetchNotes();
        widget.onDataChanged?.call();
      }
    } catch (e) { _showSnackBar("Gagal menghapus", Colors.red, Colors.white); }
  }

  void _showSnackBar(String m, Color bg, Color txt) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: GoogleFonts.poppins(color: txt, fontWeight: FontWeight.bold)),
      backgroundColor: bg, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kYellowAccent))
                  : _filteredNotes.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
                ),
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) => _buildNoteCard(_filteredNotes[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Catatan", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Simpan idemu di sini", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ])),
          ElevatedButton.icon(
              onPressed: () => _showNoteFormDialog(context),
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: kWhite, border: Border.all(color: Colors.black, width: kBorderWidth), borderRadius: BorderRadius.circular(30)),
      child: TextField(
        controller: _searchController,
        onChanged: _filterNotes,
        decoration: const InputDecoration(hintText: "Cari catatan...", prefixIcon: Icon(Icons.search, color: Colors.black), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }

  Widget _buildNoteCard(NoteItem note) {
    return GestureDetector(
      onTap: () => _showNoteDetail(context, note),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: note.color, borderRadius: BorderRadius.circular(kBorderRadius), border: Border.all(color: Colors.black, width: kBorderWidth)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(DateFormat('dd MMM').format(note.date), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
              GestureDetector(onTap: () => _togglePin(note), child: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: note.isPinned ? Colors.black : Colors.black26)),
            ]),
            const SizedBox(height: 8),
            Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
            const Divider(color: Colors.black12, thickness: 1),
            Expanded(child: Text(note.content, maxLines: 4, overflow: TextOverflow.fade, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87, height: 1.4))),
          ],
        ),
      ),
    );
  }

  void _showNoteFormDialog(BuildContext context, {NoteItem? note}) {
    final bool isEdit = note != null;
    final titleController = TextEditingController(text: isEdit ? note.title : '');
    final contentController = TextEditingController(text: isEdit ? note.content : '');
    Color selectedColor = isEdit ? note.color : kNoteColors[0];

    String? titleErr;
    String? contentErr;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) {
      return Dialog(
        backgroundColor: kCreamColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.black, width: 2)),
        child: Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(isEdit ? "Edit Catatan" : "Tulis Catatan", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 16),
          _buildTextField(titleController, "Judul Catatan", isBold: true, errorText: titleErr),
          const SizedBox(height: 12),
          _buildTextField(contentController, "Tulis sesuatu...", maxLines: 5, errorText: contentErr),
          const SizedBox(height: 16),
          Wrap(spacing: 10, children: kNoteColors.map((color) => GestureDetector(
              onTap: () => setStateDialog(() => selectedColor = color),
              child: Container(width: 32, height: 32, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: selectedColor == color ? 2.5 : 1)),
                  child: selectedColor == color ? const Icon(Icons.check, size: 16) : null))).toList()),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kYellowAccent, foregroundColor: Colors.black, side: const BorderSide(color: Colors.black, width: kBorderWidth), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                setStateDialog(() {
                  titleErr = titleController.text.trim().isEmpty ? "Judul tidak boleh kosong" : null;
                  contentErr = contentController.text.trim().isEmpty ? "Isi catatan wajib diisi" : null;
                });

                if (titleErr == null && contentErr == null) {
                  _addOrUpdateNote(id: isEdit ? note.id : null, title: titleController.text, content: contentController.text, color: selectedColor);
                  Navigator.pop(context);
                }
              }, child: const Text("Simpan Catatan", style: TextStyle(fontWeight: FontWeight.bold)))),
        ]))),
      );
    }));
  }

  void _showNoteDetail(BuildContext context, NoteItem note) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(color: note.color, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), border: const Border(top: BorderSide(color: Colors.black, width: 2))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 60, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
        Expanded(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(note.title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold))),
            IconButton(onPressed: () { _togglePin(note); Navigator.pop(context); }, icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined)),
            IconButton(onPressed: () { Navigator.pop(context); _showNoteFormDialog(context, note: note); }, icon: const Icon(Icons.edit)),
          ]),
          Text(DateFormat('EEEE, dd MMMM yyyy').format(note.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          const Divider(height: 32, thickness: 1, color: Colors.black12),
          Expanded(child: SingleChildScrollView(child: Text(note.content, style: GoogleFonts.poppins(fontSize: 16, height: 1.6)))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red[900], side: BorderSide(color: Colors.red[900]!, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => _showDeleteConfirmDialog(context, note.id),
            icon: const Icon(Icons.delete_outline), label: const Text("Hapus Catatan"),
          )),
        ]))),
      ]),
    ));
  }

  // Dialog Konfirmasi
  void _showDeleteConfirmDialog(BuildContext context, String noteId) {
    showDialog(context: context, builder: (context) => DeleteConfirmationDialog(onConfirm: () {
      _deleteNote(noteId);
      // Jika dipanggil dari sheet detail, tutup sheet juga (handled by user experience flow)
      // Tapi karena deleteNote ada Navigator.pop(context) di dalam showDialog 'Lanjutkan',
      // Perlu menutup bottom sheet secara manual jika perlu.
      // Di sini cukup panggil _deleteNote yang sudah menghandle refresh.
    }));
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.note_alt_outlined, size: 80, color: Colors.black12),
      const SizedBox(height: 16),
      Text("Belum ada catatan", style: GoogleFonts.poppins(color: Colors.grey)),
    ]));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, bool isBold = false, String? errorText}) {
    return TextField(
      controller: controller, maxLines: maxLines,
      style: GoogleFonts.poppins(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
          filled: true,
          fillColor: kWhite,
          contentPadding: const EdgeInsets.all(16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius), borderSide: const BorderSide(color: Colors.black, width: kBorderWidth)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius), borderSide: const BorderSide(color: kRedUrgent, width: 2.0)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius), borderSide: const BorderSide(color: kRedUrgent, width: 2.0))
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
          Text("Hapus Catatan?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 12),
          Text("Data tidak bisa dikembalikan.", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)),
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
                    onPressed: () { Navigator.pop(context); Navigator.pop(context); widget.onConfirm(); }, // Pop dialog, lalu pop bottom sheet jika ada
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