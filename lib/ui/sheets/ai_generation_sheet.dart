// lib/ui/sheets/ai_generation_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import 'voca_bottom_sheet.dart';

/// Modal bottom sheet to confirm AI Whisper subtitle generation.
/// Matches lingua-tube's ai-confirm-modal:
/// - Diamond cost display
/// - Current balance
/// - Generate AI action button
class AiGenerationSheet extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String language;
  final VoidCallback onGenerated;

  const AiGenerationSheet({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.language,
    required this.onGenerated,
  });

  static Future<void> show(
    BuildContext context, {
    required String videoId,
    required String videoTitle,
    required String language,
    required VoidCallback onGenerated,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('subtitle.generateAi', null, 'Generate AI Subtitles'),
      showCloseButton: true,
      maxHeightFactor: 0.75,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      builder: (ctx) => AiGenerationSheet(
        videoId: videoId,
        videoTitle: videoTitle,
        language: language,
        onGenerated: onGenerated,
      ),
    );
  }

  @override
  State<AiGenerationSheet> createState() => _AiGenerationSheetState();
}

class _AiGenerationSheetState extends State<AiGenerationSheet> {
  bool _isGenerating = false;
  String? _error;

  String _getLanguageLabel(String code) {
    switch (code.toLowerCase()) {
      case 'ja':
        return 'Japanese (日本語)';
      case 'zh':
        return 'Chinese (中文)';
      case 'ko':
        return 'Korean (한국어)';
      case 'en':
        return 'English';
      default:
        return code.toUpperCase();
    }
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final res = await AppState.instance.apiClient.getTranscript(
        videoId: widget.videoId,
        lang: widget.language,
        preferAI: true,
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        if (res.success && res.segments.isNotEmpty) {
          Navigator.pop(context);
          widget.onGenerated();
        } else if (res.isProcessing) {
          // Asynchronous job queued
          Navigator.pop(context);
          widget.onGenerated();
        } else {
          setState(() {
            _error = res.error ?? 'AI transcript is still processing. Please check back in a moment.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = 'Failed to generate subtitles: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final diamonds = AppState.instance.diamonds.value;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header icon + title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.colorDiamond.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: colors.colorDiamond, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLanguageLabel(widget.language),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      context.t('subtitle.whisperAi', null, 'Powered by Whisper AI'),
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Details Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Column(
              children: [
                // Video title row
                Row(
                  children: [
                    Text(
                      context.t('subtitle.video', null, 'Video'),
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.videoTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: colors.borderColor),
                const SizedBox(height: 10),

                // Cost row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.t('subtitle.cost', null, 'Cost'),
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.diamond_rounded, size: 14, color: colors.colorDiamond),
                        const SizedBox(width: 4),
                        Text(
                          '1 Diamond',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.colorDiamond,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: colors.borderColor),
                const SizedBox(height: 10),

                // Balance row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.t('subtitle.yourBalance', null, 'Your Balance'),
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.diamond_rounded, size: 14, color: colors.colorDiamond),
                        const SizedBox(width: 4),
                        Text(
                          '$diamonds / 10',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isGenerating ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(context.t('vocab.cancel', null, 'Cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _handleConfirm,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(
                    _isGenerating
                        ? context.t('common.loading', null, 'Generating...')
                        : context.t('subtitle.generate', null, 'Generate'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
