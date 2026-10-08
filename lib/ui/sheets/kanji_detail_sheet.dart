// lib/ui/sheets/kanji_detail_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/kanji_service.dart';
import 'voca_bottom_sheet.dart';

enum KanjiViewMode {
  strokeOrder,
  frames,
}

/// Modal bottom sheet for viewing Kanji character breakdown and stroke order.
class KanjiDetailSheet extends StatefulWidget {
  final String kanji;
  final KanjiData? initialData;

  const KanjiDetailSheet({
    super.key,
    required this.kanji,
    this.initialData,
  });

  static Future<void> show(
    BuildContext context, {
    required String kanji,
    KanjiData? initialData,
  }) {
    return showVocaBottomSheet(
      context: context,
      showCloseButton: true,
      maxHeightFactor: 0.90,
      contentPadding: EdgeInsets.zero,
      builder: (ctx) => KanjiDetailSheet(
        kanji: kanji,
        initialData: initialData,
      ),
    );
  }

  @override
  State<KanjiDetailSheet> createState() => _KanjiDetailSheetState();
}

class _KanjiDetailSheetState extends State<KanjiDetailSheet> {
  KanjiData? _data;
  bool _isLoading = false;
  String? _error;
  KanjiViewMode _viewMode = KanjiViewMode.strokeOrder;

  Timer? _playbackTimer;
  int _currentStroke = 0;
  bool _isPlaying = true;
  bool _showNumbers = false;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? KanjiService.instance.getCached(widget.kanji);
    if (_data == null) {
      _loadData();
    } else if (_data!.strokeCount > 0) {
      _startPlayback();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    if (!mounted) return;
    setState(() => _isPlaying = true);
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 750), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final total = _data?.strokeCount ?? 0;
      if (total <= 0) return;

      setState(() {
        if (_currentStroke < total - 1) {
          _currentStroke++;
        } else {
          _currentStroke = 0;
        }
      });
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _replay() {
    setState(() => _currentStroke = 0);
    _startPlayback();
  }

  void _stepPrevious() {
    _pausePlayback();
    final total = _data?.strokeCount ?? 0;
    if (total <= 0) return;
    setState(() {
      _currentStroke = (_currentStroke - 1).clamp(0, total - 1);
    });
  }

  void _stepNext() {
    _pausePlayback();
    final total = _data?.strokeCount ?? 0;
    if (total <= 0) return;
    setState(() {
      _currentStroke = (_currentStroke + 1).clamp(0, total - 1);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await KanjiService.instance.lookupKanji(widget.kanji);
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
          _currentStroke = 0;
          if (res == null) {
            _error = context.t('kanji.errorLoading', null, 'Could not load kanji details.');
          }
        });
        if (res != null && res.strokeCount > 0) {
          _startPlayback();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = context.t('kanji.errorLoading', null, 'Could not load kanji details.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Big Kanji Glyph
                Text(
                  widget.kanji,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Kosugi Maru',
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Badges Row (JLPT, Stroke Count, Grade, Radical)
                _buildBadgesRow(context),
                const SizedBox(height: 16),

                // 3. View Mode Segmented Switcher
                _buildModeSelector(context),
                const SizedBox(height: 16),

                // 4. Stroke Viewer Canvas
                _buildStrokeCanvas(context),
                const SizedBox(height: 20),

                // 5. Readings & Meanings (When Loaded)
                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ] else if (_data != null) ...[
                  _buildReadingsSection(context, _data!),
                  const SizedBox(height: 16),
                  _buildMeaningsSection(context, _data!),
                  if (_data!.parts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPartsSection(context, _data!),
                  ],
                ] else if (_error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          _error ?? context.t('kanji.errorLoading', null, 'Could not load kanji details.'),
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(context.t('common.retry', null, 'Retry')),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesRow(BuildContext context) {
    final colors = context.vocaColors;
    final data = _data;

    if (data == null && _isLoading) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Container(
            width: 68,
            height: 26,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
            ),
          ),
          Container(
            width: 80,
            height: 26,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
            ),
          ),
          Container(
            width: 64,
            height: 26,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
            ),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (data?.jlpt != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'JLPT N${data!.jlpt}',
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (data != null && data.strokeCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Text(
              '${data.strokeCount} ${context.t('kanji.strokes', null, 'strokes')}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (data?.grade != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Text(
              'Grade ${data!.grade}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (data?.radical != null && data!.radical!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Text(
              '${context.t('kanji.radical', null, 'Radical')}: ${data.radical}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    final colors = context.vocaColors;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeTab(
            context,
            mode: KanjiViewMode.strokeOrder,
            label: context.t('kanji.animation', null, 'Animation'),
            icon: Icons.play_circle_outline_rounded,
          ),
          const SizedBox(width: 4),
          _buildModeTab(
            context,
            mode: KanjiViewMode.frames,
            label: context.t('kanji.stepByStep', null, 'Step-by-Step'),
            icon: Icons.view_column_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(
    BuildContext context, {
    required KanjiViewMode mode,
    required String label,
    required IconData icon,
  }) {
    final colors = context.vocaColors;
    final isSelected = _viewMode == mode;

    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrokeCanvas(BuildContext context) {
    final colors = context.vocaColors;
    final animationUrl = 'https://jotoba.de/resource/kanji/animation/${Uri.encodeComponent(widget.kanji)}';
    final framesUrl = 'https://jotoba.de/resource/kanji/frames/${Uri.encodeComponent(widget.kanji)}';
    final strokeCount = _data?.strokeCount ?? 0;
    const double canvasSize = 180.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Authentic calligraphy paper card background ensuring crisp black stroke visibility
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.isDark ? const Color(0xFF333842) : colors.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: _viewMode == KanjiViewMode.strokeOrder
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stroke Canvas Area
                SizedBox(
                  width: canvasSize,
                  height: canvasSize,
                  child: _isLoading && _data == null
                      ? Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                          ),
                        )
                      : _showNumbers || strokeCount <= 0
                          ? SvgPicture.network(
                              animationUrl,
                              fit: BoxFit.contain,
                              placeholderBuilder: (context) => Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                                ),
                              ),
                              errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(colors),
                            )
                          : ClipRect(
                              child: SizedBox(
                                width: canvasSize,
                                height: canvasSize,
                                child: OverflowBox(
                                  alignment: Alignment.topLeft,
                                  minWidth: 0,
                                  maxWidth: double.infinity,
                                  minHeight: canvasSize,
                                  maxHeight: canvasSize,
                                  child: Transform.translate(
                                    offset: Offset(-_currentStroke * canvasSize, 0),
                                    child: SizedBox(
                                      width: canvasSize * strokeCount,
                                      height: canvasSize,
                                      child: SvgPicture.network(
                                        framesUrl,
                                        fit: BoxFit.fill,
                                        placeholderBuilder: (context) => Center(
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                                          ),
                                        ),
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildErrorPlaceholder(colors),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                ),

                // Controls & Stroke Counter
                if (strokeCount > 0 && !_isLoading) ...[
                  const SizedBox(height: 10),
                  // Progress Text
                  Text(
                    _showNumbers
                        ? context.t('kanji.showNumbers', null, 'Stroke Numbers')
                        : context.t('kanji.strokeOf', {
                            'current': '${_currentStroke + 1}',
                            'total': '$strokeCount',
                          }, 'Stroke ${_currentStroke + 1} of $strokeCount'),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Mini interactive stroke scrubber dots
                  if (!_showNumbers) ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(strokeCount, (index) {
                        final isActive = index == _currentStroke;
                        final isDone = index < _currentStroke;
                        return GestureDetector(
                          onTap: () {
                            _pausePlayback();
                            setState(() => _currentStroke = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isActive ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colors.accentPrimary
                                  : isDone
                                      ? colors.accentPrimary.withValues(alpha: 0.4)
                                      : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Playback control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous stroke
                      IconButton(
                        onPressed: _currentStroke > 0 && !_showNumbers ? _stepPrevious : null,
                        icon: const Icon(Icons.skip_previous_rounded, size: 22),
                        tooltip: 'Previous stroke',
                        color: const Color(0xFF475569),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),

                      // Play / Pause
                      FilledButton.tonal(
                        onPressed: _showNumbers ? null : _togglePlayback,
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                          backgroundColor: colors.accentPrimary.withValues(alpha: 0.15),
                          foregroundColor: colors.accentPrimary,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Next stroke
                      IconButton(
                        onPressed: _currentStroke < strokeCount - 1 && !_showNumbers ? _stepNext : null,
                        icon: const Icon(Icons.skip_next_rounded, size: 22),
                        tooltip: 'Next stroke',
                        color: const Color(0xFF475569),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),

                      // Replay
                      IconButton(
                        onPressed: _showNumbers ? null : _replay,
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        tooltip: context.t('common.retry', null, 'Replay'),
                        color: const Color(0xFF64748B),
                        visualDensity: VisualDensity.compact,
                      ),

                      // Toggle Numbers
                      IconButton(
                        onPressed: () {
                          _pausePlayback();
                          setState(() => _showNumbers = !_showNumbers);
                        },
                        icon: Icon(
                          _showNumbers ? Icons.format_list_numbered_rounded : Icons.pin_outlined,
                          size: 20,
                          color: _showNumbers ? colors.accentPrimary : const Color(0xFF64748B),
                        ),
                        tooltip: context.t('kanji.showNumbers', null, 'Stroke Numbers'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ],
            )
          : SizedBox(
              height: 120,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SvgPicture.network(
                  framesUrl,
                  height: 120,
                  fit: BoxFit.fitHeight,
                  placeholderBuilder: (context) => Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                    ),
                  ),
                  errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(colors),
                ),
              ),
            ),
    );
  }

  Widget _buildErrorPlaceholder(VocaColorPalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 32, color: colors.textMuted),
            const SizedBox(height: 6),
            Text(
              context.t('kanji.strokeUnavailable', null, 'Stroke diagram unavailable'),
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsSection(BuildContext context, KanjiData data) {
    final colors = context.vocaColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On'yomi
          if (data.onyomi.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.record_voice_over_outlined, size: 15, color: colors.accentPrimary),
                const SizedBox(width: 6),
                Text(
                  context.t('kanji.onyomi', null, "On'yomi (音読み)"),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.onyomi.map((r) => _buildReadingChip(context, r, isOnyomi: true)).toList(),
            ),
          ],

          if (data.onyomi.isNotEmpty && data.kunyomi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: colors.borderColor, height: 1),
            ),

          // Kun'yomi
          if (data.kunyomi.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.translate_rounded, size: 15, color: colors.colorGrammar),
                const SizedBox(width: 6),
                Text(
                  context.t('kanji.kunyomi', null, "Kun'yomi (訓読み)"),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.kunyomi.map((r) => _buildReadingChip(context, r, isOnyomi: false)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingChip(BuildContext context, String reading, {required bool isOnyomi}) {
    final colors = context.vocaColors;
    final color = isOnyomi ? colors.accentPrimary : colors.colorGrammar;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        reading,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMeaningsSection(BuildContext context, KanjiData data) {
    final colors = context.vocaColors;
    if (data.meanings.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('kanji.meanings', null, 'Meanings'),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.meanings.join(', '),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsSection(BuildContext context, KanjiData data) {
    final colors = context.vocaColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.extension_outlined, size: 15, color: colors.accentPrimary),
              const SizedBox(width: 6),
              Text(
                context.t('kanji.parts', null, 'Components & Radicals'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: data.parts.map((p) {
              final isInspectable = KanjiService.instance.hasKanji(p);
              final canTap = isInspectable && p != widget.kanji;
              return Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: canTap
                      ? context.t('kanji.tapToInspect', null, 'Tap to inspect')
                      : '',
                  child: InkWell(
                    onTap: canTap
                        ? () => KanjiDetailSheet.show(context, kanji: p)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canTap
                              ? colors.accentPrimary.withValues(alpha: 0.35)
                              : colors.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Kosugi Maru',
                            ),
                          ),
                          if (canTap) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: colors.accentPrimary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
