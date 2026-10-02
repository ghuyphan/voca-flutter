// lib/utils/video_format_utils.dart

/// Formats a duration in seconds into 'm:ss' or 'h:mm:ss' (or 'mm:ss' if padMinutes is true),
/// matching the exact format used in lingua-tube's formatTime utility.
String formatVideoTime(num? seconds, {bool padMinutes = false}) {
  if (seconds == null || seconds.isNaN || seconds <= 0) {
    return padMinutes ? '00:00' : '0:00';
  }
  final totalSecs = seconds.floor();
  final mins = totalSecs ~/ 60;
  final secs = totalSecs % 60;
  final formattedSecs = secs.toString().padLeft(2, '0');

  if (mins >= 60) {
    final hrs = mins ~/ 60;
    final remainingMins = mins % 60;
    return '$hrs:${remainingMins.toString().padLeft(2, '0')}:$formattedSecs';
  }

  final formattedMins = padMinutes ? mins.toString().padLeft(2, '0') : mins.toString();
  return '$formattedMins:$formattedSecs';
}
