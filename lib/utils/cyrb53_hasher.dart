// lib/utils/cyrb53_hasher.dart

/// Generates a deterministic, conflict-free record ID for offline records
/// across vocabulary items and history entries.
/// Matches the web implementation in `src/app/shared/utils/sync.utils.ts`.
String generateDeterministicRecordId(List<String> keys) {
  final raw = keys.map((k) => k.trim()).join('|');
  int h1 = 0xdeadbeef;
  int h2 = 0x41c64e6d;
  for (int i = 0; i < raw.length; i++) {
    final ch = raw.codeUnitAt(i);
    h1 = (h1 ^ ch) * 2654435761 & 0xFFFFFFFF;
    h2 = (h2 ^ ch) * 1597334677 & 0xFFFFFFFF;
  }
  h1 = ((h1 ^ (h1 >> 16)) * 2246822507) & 0xFFFFFFFF;
  h1 = (h1 ^ ((h2 ^ (h2 >> 13)) * 3266489909)) & 0xFFFFFFFF;
  h2 = ((h2 ^ (h2 >> 16)) * 2246822507) & 0xFFFFFFFF;
  h2 = (h2 ^ ((h1 ^ (h1 >> 13)) * 3266489909)) & 0xFFFFFFFF;
  final h3 = (h1 * h2 * 2166136261) & 0xFFFFFFFF;

  final p1 = h1.toRadixString(36).padLeft(7, '0');
  final p2 = h2.toRadixString(36).padLeft(7, '0');
  final p3 = h3.toRadixString(36).padLeft(7, '0');
  return (p1 + p2 + p3).substring(0, 15);
}
