// string_utils.dart

String shortId(String? id) {
  if (id == null || id.trim().isEmpty) return '-';
  final trimmed = id.trim();
  return trimmed.length <= 6 ? trimmed : trimmed.substring(0, 6);
}
