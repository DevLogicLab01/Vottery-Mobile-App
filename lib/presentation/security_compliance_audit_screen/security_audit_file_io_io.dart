import 'dart:io';

/// Writes [bytes] to [path]. Used for CSV/PDF export on mobile/desktop.
Future<bool> writeSecurityAuditFile(String path, List<int> bytes) async {
  final file = File(path);
  await file.writeAsBytes(bytes);
  return true;
}
