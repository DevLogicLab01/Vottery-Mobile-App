import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sizer/sizer.dart';

import 'security_audit_file_io_io.dart'
    if (dart.library.html) 'security_audit_file_io_stub.dart' as file_io;
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

/// Flutter parity with Web Security & Compliance Audit screen.
/// Uses Supabase table [security_audit_checklist]; supports filter, edit status/notes, export CSV/PDF, pre-launch sign-off.
class SecurityComplianceAuditScreen extends StatefulWidget {
  const SecurityComplianceAuditScreen({super.key});

  @override
  State<SecurityComplianceAuditScreen> createState() =>
      _SecurityComplianceAuditScreenState();
}

class _SecurityComplianceAuditScreenState
    extends State<SecurityComplianceAuditScreen> {
  static const Map<String, String> _categoryLabels = {
    'encryption': 'Encryption',
    'authentication': 'Authentication',
    'gdpr_ccpa': 'GDPR / CCPA',
    'penetration_testing': 'Penetration Testing',
    'data_residency': 'Data Residency',
    'pre_launch': 'Pre-Launch Sign-Off',
  };

  static const Map<String, ({String label, Color color})> _statusConfig = {
    'pass': (label: 'Pass', color: Color(0xFF22C55E)),
    'fail': (label: 'Fail', color: Color(0xFFEF4444)),
    'na': (label: 'N/A', color: Color(0xFF6B7280)),
    'pending': (label: 'Pending', color: Color(0xFFEAB308)),
  };

  final SupabaseService _supabase = SupabaseService.instance;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _editingId;
  String _editStatus = 'pending';
  String _editNotes = '';
  bool _saving = false;
  String? _toastMsg;
  bool _toastError = false;
  String _activeCategory = 'all';
  bool _isAdmin = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _loadItems();
  }

  Future<void> _checkAdmin() async {
    final uid = _supabase.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _isAdmin = false);
      return;
    }
    try {
      final res = await _supabase.client
          .from('user_profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      final role = res?['role'] as String?;
      if (mounted) {
        setState(() =>
            _isAdmin = role == 'admin' || role == 'super_admin');
      }
    } catch (_) {
      if (mounted) setState(() => _isAdmin = false);
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase.client
          .from('security_audit_checklist')
          .select('*')
          .order('category');
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(res ?? []);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _showToast(e.toString(), error: true);
        });
      }
    }
  }

  void _showToast(String msg, {bool error = false}) {
    setState(() {
      _toastMsg = msg;
      _toastError = error;
    });
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _toastMsg = null);
    });
  }

  void _startEdit(Map<String, dynamic> item) {
    _editingId = item['id'] as String?;
    _editStatus = (item['status'] as String?) ?? 'pending';
    _editNotes = (item['notes'] as String?) ?? '';
    _notesController.text = _editNotes;
    setState(() {});
  }

  Future<void> _saveEdit(String id) async {
    final notes = _notesController.text;
    setState(() => _saving = true);
    try {
      await _supabase.client.from('security_audit_checklist').update({
        'status': _editStatus,
        'notes': notes,
        'last_checked_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      if (mounted) {
        _showToast('Saved');
        setState(() {
          _editingId = null;
          _saving = false;
        });
        _loadItems();
      }
    } catch (e) {
      if (mounted) {
        _showToast(e.toString(), error: true);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _completePreLaunchSignOff() async {
    final signOff = _items
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (e) => e?['item_key'] == 'security_signoff',
          orElse: () => null,
        );
    if (signOff == null) {
      _showToast('Pre-launch sign-off item not found', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final existingNotes = (signOff['notes'] as String?) ?? '';
      final extra =
          'Pre-launch sign-off completed ${DateTime.now().toUtc().toIso8601String().split('T').first}';
      await _supabase.client.from('security_audit_checklist').update({
        'status': 'pass',
        'notes': existingNotes.isEmpty ? extra : '$existingNotes; $extra',
        'last_checked_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', signOff['id']);
      if (mounted) {
        _showToast('Pre-launch security sign-off recorded');
        setState(() => _saving = false);
        _loadItems();
      }
    } catch (e) {
      if (mounted) {
        _showToast(e.toString(), error: true);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      final rows = <List<dynamic>>[
        ['Category', 'Title', 'Status', 'Notes', 'Last Checked'],
        ..._items.map((item) {
          final lastChecked = item['last_checked_at'];
          return [
            _categoryLabels[item['category']] ?? item['category'],
            item['title'] ?? '',
            item['status'] ?? '',
            (item['notes'] as String? ?? '').length > 40
                ? '${(item['notes'] as String).substring(0, 40)}...'
                : (item['notes'] ?? ''),
            lastChecked != null
                ? DateTime.tryParse(lastChecked.toString())?.toIso8601String().split('T').first ?? ''
                : '',
          ];
        }),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/security-audit-${DateTime.now().toIso8601String().split('T').first}.csv';
      final written = await file_io.writeSecurityAuditFile(path, utf8.encode(csv));
      if (mounted) {
        _showToast(written ? 'CSV saved to $path' : 'CSV ready (use desktop app to save file)');
      }
    } catch (e) {
      if (mounted) _showToast(e.toString(), error: true);
    }
  }

  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Security & Compliance Audit',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              'Generated: ${DateTime.now().toIso8601String()}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Category'),
                    _cell('Title'),
                    _cell('Status'),
                    _cell('Notes'),
                    _cell('Last Checked'),
                  ],
                ),
                ..._items.map((item) {
                  final lastChecked = item['last_checked_at'];
                  final notes = (item['notes'] as String?) ?? '';
                  return pw.TableRow(
                    children: [
                      _cell(_categoryLabels[item['category']] ?? '${item['category']}'),
                      _cell(item['title'] ?? ''),
                      _cell(item['status'] ?? ''),
                      _cell(notes.length > 40 ? '${notes.substring(0, 40)}...' : notes),
                      _cell(
                        lastChecked != null
                            ? (DateTime.tryParse(lastChecked.toString())?.toIso8601String().split('T').first ?? '')
                            : '',
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );
      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/security-audit-${DateTime.now().toIso8601String().split('T').first}.pdf';
      final written = await file_io.writeSecurityAuditFile(path, bytes);
      if (mounted) {
        _showToast(written ? 'PDF saved to $path' : 'PDF ready (use desktop app to save file)');
      }
    } catch (e) {
      if (mounted) _showToast(e.toString(), error: true);
    }
  }

  pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _activeCategory == 'all'
        ? _items
        : _items.where((i) => i['category'] == _activeCategory).toList();
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in filtered) {
      final cat = (item['category'] as String?) ?? 'other';
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    final passCount = _items.where((i) => i['status'] == 'pass').length;
    final failCount = _items.where((i) => i['status'] == 'fail').length;
    final pendingCount = _items.where((i) => i['status'] == 'pending').length;
    final categories = ['all', ..._categoryLabels.keys];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: CustomAppBar(
        title: 'Security & Compliance Audit',
        variant: CustomAppBarVariant.withBack,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_toastMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _toastError
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : const Color(0xFF22C55E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _toastError
                              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                              : const Color(0xFF22C55E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _toastMsg!,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: _toastError
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                        ),
                      ),
                    ),
                  Text(
                    'Encryption, GDPR/CCPA, penetration testing, and pre-launch security checklist',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!_isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Read-only',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      if (_isAdmin) ...[
                        TextButton.icon(
                          onPressed: _saving ? null : _completePreLaunchSignOff,
                          icon: const Icon(Icons.check_circle,
                              size: 16, color: Color(0xFF22C55E)),
                          label: Text(
                            _saving ? 'Saving...' : 'Complete Pre-Launch Sign-Off',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF22C55E),
                            ),
                          ),
                        ),
                      ],
                      TextButton.icon(
                        onPressed: _exportCsv,
                        icon: const Icon(Icons.download, size: 16,
                            color: Color(0xFF94A3B8)),
                        label: Text(
                          'Export CSV',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf, size: 16,
                            color: Color(0xFF94A3B8)),
                        label: Text(
                          'Export PDF',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryCard('Passing', passCount, const Color(0xFF22C55E)),
                      _summaryCard('Failing', failCount, const Color(0xFFEF4444)),
                      _summaryCard('Pending', pendingCount, const Color(0xFFEAB308)),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final selected = _activeCategory == cat;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _activeCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: Text(
                            cat == 'all' ? 'All' : (_categoryLabels[cat] ?? cat),
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: selected ? Colors.white : Colors.grey,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 2.h),
                  ...grouped.entries.map((e) => _categorySection(e.key, e.value)),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection(String category, List<Map<String, dynamic>> catItems) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              _categoryLabels[category] ?? category,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          ...catItems.map((item) => _checklistItem(item)),
        ],
      ),
    );
  }

  Widget _checklistItem(Map<String, dynamic> item) {
    final id = item['id'] as String?;
    final isEditing = _editingId == id;
    final status = (item['status'] as String?) ?? 'pending';
    final config = _statusConfig[status] ?? _statusConfig['pending']!;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF334155),
            width: 0.5,
          ),
        ),
      ),
      child: isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _statusConfig.entries.map((e) {
                    final selected = _editStatus == e.key;
                    return GestureDetector(
                      onTap: () => setState(() => _editStatus = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? e.value.color.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? e.value.color
                                : const Color(0xFF334155),
                          ),
                        ),
                        child: Text(
                          e.value.label,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: e.value.color,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  onChanged: (v) => _editNotes = v,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add notes...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 11.sp),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => _saveEdit(id!),
                      child: Text(_saving ? 'Saving...' : 'Save',
                          style: const TextStyle(color: Color(0xFF6366F1))),
                    ),
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          setState(() => _editingId = null),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey[400])),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String? ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: config.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: config.color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              config.label,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: config.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item['description'] != null &&
                          (item['description'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      if (item['notes'] != null &&
                          (item['notes'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Note: ${item['notes']}',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (item['last_checked_at'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Last checked: ${_formatDate(item['last_checked_at'])}',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () => _startEdit(item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
    );
  }

  String _formatDate(dynamic v) {
    if (v == null) return '';
    final d = DateTime.tryParse(v.toString());
    return d != null ? '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' : '';
  }
}
