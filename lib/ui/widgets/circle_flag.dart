// lib/ui/widgets/circle_flag.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/voca_theme.dart';

/// Reusable circular country flag widget rendering crisp SVG flags from `assets/flags/`.
///
/// Features:
/// - **Zero-allocation O(1) resolution**: Direct compile-time map + static memoization cache.
/// - **Zero-jank pre-warming**: [precacheAll] preloads all 17 flag SVGs into memory.
/// - **Reusable const styling**: Pre-allocated M3 elevation box shadows.
/// - **Lossless vector rendering**: Renders natively scaled SVGs from `assets/flags/*.svg`.
///
/// Accepts:
/// - 2-letter language codes: 'ja', 'ko', 'zh', 'vi', 'en', 'es', 'fr', 'de', 'id', 'ru', 'th', 'it', 'pt', etc.
/// - 2-letter country codes: 'jp', 'kr', 'cn', 'vn', 'us', 'gb', 'ca', 'au', 'br', etc.
/// - Unicode flag emojis: '🇯🇵', '🇺🇸', '🇬🇧', '🇻🇳', '🇨🇳', '🇰🇷', etc.
/// - Direct SVG asset paths: 'assets/flags/jp.svg'.
///
/// If unresolvable or 'auto', gracefully renders a sleek global fallback icon.
class CircleFlag extends StatelessWidget {
  final String? code;
  final double size;
  final bool hasShadow;
  final bool hasBorder;
  final Color? borderColor;

  const CircleFlag({
    super.key,
    required this.code,
    this.size = 20,
    this.hasShadow = true,
    this.hasBorder = false,
    this.borderColor,
  });

  /// 17 supported country codes with bundled SVGs in `assets/flags/`
  static const Set<String> supportedCountries = {
    'au', 'br', 'ca', 'cn', 'de', 'es', 'fr', 'gb',
    'id', 'it', 'jp', 'kr', 'pt', 'ru', 'th', 'us', 'vn',
  };

  /// Pre-allocated constant shadow to avoid per-frame heap allocations during scrolling.
  static const List<BoxShadow> _defaultShadow = [
    BoxShadow(
      color: Color(0x1F000000), // Colors.black with alpha 0.12 (approx 31/255 = 0x1F)
      blurRadius: 2,
      offset: Offset(0, 0.5),
    ),
  ];

  /// Direct O(1) compile-time lookup table for all canonical codes, emojis, and paths.
  static const Map<String, String> _directMap = {
    // Language & ISO country codes
    'ja': 'assets/flags/jp.svg',
    'jp': 'assets/flags/jp.svg',
    'ko': 'assets/flags/kr.svg',
    'kr': 'assets/flags/kr.svg',
    'zh': 'assets/flags/cn.svg',
    'cn': 'assets/flags/cn.svg',
    'vi': 'assets/flags/vn.svg',
    'vn': 'assets/flags/vn.svg',
    'en': 'assets/flags/us.svg',
    'us': 'assets/flags/us.svg',
    'gb': 'assets/flags/gb.svg',
    'uk': 'assets/flags/gb.svg',
    'es': 'assets/flags/es.svg',
    'fr': 'assets/flags/fr.svg',
    'de': 'assets/flags/de.svg',
    'id': 'assets/flags/id.svg',
    'ru': 'assets/flags/ru.svg',
    'th': 'assets/flags/th.svg',
    'it': 'assets/flags/it.svg',
    'pt': 'assets/flags/pt.svg',
    'br': 'assets/flags/br.svg',
    'ca': 'assets/flags/ca.svg',
    'au': 'assets/flags/au.svg',

    // Uppercase variants
    'JA': 'assets/flags/jp.svg',
    'JP': 'assets/flags/jp.svg',
    'KO': 'assets/flags/kr.svg',
    'KR': 'assets/flags/kr.svg',
    'ZH': 'assets/flags/cn.svg',
    'CN': 'assets/flags/cn.svg',
    'VI': 'assets/flags/vn.svg',
    'VN': 'assets/flags/vn.svg',
    'EN': 'assets/flags/us.svg',
    'US': 'assets/flags/us.svg',
    'GB': 'assets/flags/gb.svg',
    'UK': 'assets/flags/gb.svg',
    'ES': 'assets/flags/es.svg',
    'FR': 'assets/flags/fr.svg',
    'DE': 'assets/flags/de.svg',
    'ID': 'assets/flags/id.svg',
    'RU': 'assets/flags/ru.svg',
    'TH': 'assets/flags/th.svg',
    'IT': 'assets/flags/it.svg',
    'PT': 'assets/flags/pt.svg',
    'BR': 'assets/flags/br.svg',
    'CA': 'assets/flags/ca.svg',
    'AU': 'assets/flags/au.svg',

    // Unicode Flag Emojis
    '🇯🇵': 'assets/flags/jp.svg',
    '🇰🇷': 'assets/flags/kr.svg',
    '🇨🇳': 'assets/flags/cn.svg',
    '🇻🇳': 'assets/flags/vn.svg',
    '🇺🇸': 'assets/flags/us.svg',
    '🇬🇧': 'assets/flags/gb.svg',
    '🇪🇸': 'assets/flags/es.svg',
    '🇫🇷': 'assets/flags/fr.svg',
    '🇩🇪': 'assets/flags/de.svg',
    '🇮🇩': 'assets/flags/id.svg',
    '🇷🇺': 'assets/flags/ru.svg',
    '🇹🇭': 'assets/flags/th.svg',
    '🇮🇹': 'assets/flags/it.svg',
    '🇵🇹': 'assets/flags/pt.svg',
    '🇧🇷': 'assets/flags/br.svg',
    '🇨🇦': 'assets/flags/ca.svg',
    '🇦🇺': 'assets/flags/au.svg',
  };

  /// Thread-safe memoization cache for any dynamic or untrimmed string queries.
  static final Map<String, String?> _dynamicCache = <String, String?>{};

  /// Pre-warms all 17 bundled SVG flags into Flutter's SVG cache.
  /// Typically called once during app launch in [I18nService.init].
  static Future<void> precacheAll([AssetBundle? bundle]) async {
    final assetBundle = bundle ?? rootBundle;
    await Future.wait(
      supportedCountries.map((code) async {
        final path = 'assets/flags/$code.svg';
        final loader = SvgAssetLoader(path, assetBundle: assetBundle);
        try {
          await svg.cache.putIfAbsent(
            loader.cacheKey(null),
            () => loader.loadBytes(null),
          );
        } catch (_) {
          // Gracefully continue if an asset isn't ready
        }
      }),
    );
  }

  /// Converts any language/country code, flag emoji, or asset string to bundled asset path.
  /// Fully memoized: O(1) on all repeated calls with 0 allocations.
  static String? resolveAsset(String? rawCode) {
    if (rawCode == null) return null;

    // Fast-path: direct compile-time hit
    final direct = _directMap[rawCode];
    if (direct != null) return direct;

    // Fast-path: memoized dynamic cache hit
    if (_dynamicCache.containsKey(rawCode)) {
      return _dynamicCache[rawCode];
    }

    // Dynamic resolution
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'auto') {
      _dynamicCache[rawCode] = null;
      return null;
    }

    if (trimmed.startsWith('assets/flags/') && trimmed.endsWith('.svg')) {
      _dynamicCache[rawCode] = trimmed;
      return trimmed;
    }

    // Direct hit after trim
    final trimmedHit = _directMap[trimmed];
    if (trimmedHit != null) {
      _dynamicCache[rawCode] = trimmedHit;
      return trimmedHit;
    }

    // Check for Unicode Regional Indicator flag emoji (U+1F1E6 to U+1F1FF)
    final runes = trimmed.runes.toList();
    if (runes.length >= 2 &&
        runes[0] >= 0x1F1E6 && runes[0] <= 0x1F1FF &&
        runes[1] >= 0x1F1E6 && runes[1] <= 0x1F1FF) {
      final c1 = String.fromCharCode(runes[0] - 0x1F1E6 + 97); // 97 = 'a'
      final c2 = String.fromCharCode(runes[1] - 0x1F1E6 + 97);
      final derivedCode = '$c1$c2';
      if (supportedCountries.contains(derivedCode)) {
        final res = 'assets/flags/$derivedCode.svg';
        _dynamicCache[rawCode] = res;
        return res;
      }
    }

    var clean = trimmed.toLowerCase();
    if (clean.endsWith('.svg')) {
      clean = clean.substring(0, clean.length - 4);
    }
    if (clean.startsWith('assets/flags/')) {
      clean = clean.substring('assets/flags/'.length);
    }

    final mapped = _directMap[clean];
    if (mapped != null) {
      _dynamicCache[rawCode] = mapped;
      return mapped;
    }

    if (supportedCountries.contains(clean)) {
      final res = 'assets/flags/$clean.svg';
      _dynamicCache[rawCode] = res;
      return res;
    }

    _dynamicCache[rawCode] = null;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final asset = resolveAsset(code);

    if (asset == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.bgSurface,
          border: hasBorder ? Border.all(color: borderColor ?? colors.borderColorLight, width: 0.5) : null,
        ),
        child: Icon(Icons.public_rounded, size: size * 0.7, color: colors.accentPrimary),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: hasShadow ? _defaultShadow : null,
        border: hasBorder
            ? Border.all(
                color: borderColor ?? colors.borderColorLight.withValues(alpha: 0.6),
                width: 0.5,
              )
            : null,
      ),
      child: RepaintBoundary(
        child: ClipOval(
          child: SvgPicture.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: colors.bgSurface,
              child: Icon(Icons.language_rounded, size: size * 0.55, color: colors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backwards compatibility alias for `VocaFlagWidget`
class VocaFlagWidget extends StatelessWidget {
  final String? countryCode;
  final double size;
  final bool hasShadow;

  const VocaFlagWidget({
    super.key,
    required this.countryCode,
    this.size = 20,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return CircleFlag(
      code: countryCode,
      size: size,
      hasShadow: hasShadow,
    );
  }
}
