// lib/utils/youtube_url_parser.dart

class YouTubeUrlParser {
  static final RegExp _videoIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  /// Validates whether [id] is an exact 11-character YouTube video ID
  /// consisting of alphanumeric characters, hyphens, and underscores.
  static bool isValidVideoId(String id) {
    return _videoIdRegex.hasMatch(id.trim());
  }

  /// Extracts the YouTube 11-character video ID from a URL or raw ID string.
  ///
  /// Supports:
  /// - `https://www.youtube.com/watch?v=VIDEO_ID`
  /// - `https://youtu.be/VIDEO_ID`
  /// - `https://www.youtube.com/shorts/VIDEO_ID`
  /// - `https://m.youtube.com/watch?v=VIDEO_ID`
  /// - `https://www.youtube.com/embed/VIDEO_ID`
  /// - `https://www.youtube.com/v/VIDEO_ID`
  /// - `https://www.youtube.com/live/VIDEO_ID`
  /// - Bare 11-char video ID (e.g. `dQw4w9WgXcQ`)
  ///
  /// Returns `null` if no valid 11-character video ID can be extracted.
  static String? extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. Bare 11-character video ID
    if (isValidVideoId(trimmed)) {
      return trimmed;
    }

    // 2. URI parsing
    try {
      String urlString = trimmed;
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }

      final uri = Uri.tryParse(urlString);
      if (uri != null && uri.host.isNotEmpty) {
        final host = uri.host.toLowerCase();

        // youtu.be/VIDEO_ID
        if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
          if (uri.pathSegments.isNotEmpty) {
            final candidate = uri.pathSegments.first;
            if (isValidVideoId(candidate)) {
              return candidate;
            }
          }
        }

        // youtube.com, www.youtube.com, m.youtube.com, music.youtube.com
        if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
          // ?v=VIDEO_ID parameter
          if (uri.queryParameters.containsKey('v')) {
            final v = uri.queryParameters['v']!;
            if (isValidVideoId(v)) {
              return v;
            }
          }

          // Path-based IDs: /shorts/VIDEO_ID, /embed/VIDEO_ID, /v/VIDEO_ID, /live/VIDEO_ID
          final segments = uri.pathSegments;
          if (segments.length >= 2) {
            final prefix = segments[0].toLowerCase();
            if (prefix == 'shorts' || prefix == 'embed' || prefix == 'v' || prefix == 'live') {
              final candidate = segments[1];
              if (isValidVideoId(candidate)) {
                return candidate;
              }
            }
          }
        }
      }
    } catch (_) {
      // In case of URI parsing exceptions, fallback to regex
    }

    // 3. Fallback regex for unconventional or complex URLs
    final RegExp fallbackRegex = RegExp(
      r'(?:(?:youtube\.com\/(?:shorts\/|embed\/|v\/|live\/|(?:.*[?&]v=)))|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );

    final match = fallbackRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final candidate = match.group(1);
      if (candidate != null && isValidVideoId(candidate)) {
        return candidate;
      }
    }

    return null;
  }
}
