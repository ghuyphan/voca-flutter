// lib/ui/sheets/new_video_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/voca_theme.dart';
import '../../utils/youtube_url_parser.dart';
import '../../state/player_coordinator.dart';
import 'voca_bottom_sheet.dart';

/// Authentic New Video Bottom Sheet matching VOCA theme & design tokens.
class NewVideoSheet extends StatefulWidget {
  final void Function(String videoId)? onVideoSelected;

  const NewVideoSheet({super.key, this.onVideoSelected});

  /// Displays the NewVideoSheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    void Function(String videoId)? onVideoSelected,
  }) {
    return showVocaBottomSheet(
      context: context,
      showDragHandle: true,
      showCloseButton: true,
      maxHeightFactor: 0.85,
      contentPadding: EdgeInsets.zero,
      builder: (ctx) => NewVideoSheet(onVideoSelected: onVideoSelected),
    );
  }

  @override
  State<NewVideoSheet> createState() => _NewVideoSheetState();
}

class _NewVideoSheetState extends State<NewVideoSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _controller.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  void _startLearning() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a YouTube link or video ID';
      });
      return;
    }

    final videoId = YouTubeUrlParser.extractVideoId(input);
    if (videoId == null) {
      setState(() {
        _errorMessage = 'Please enter a valid YouTube URL or 11-character video ID';
      });
      return;
    }

    Navigator.of(context).pop();
    if (widget.onVideoSelected != null) {
      widget.onVideoSelected!(videoId);
    } else {
      PlayerCoordinator.instance.openVideo(
        context,
        videoId: videoId,
        title: 'YouTube Video',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Coral Accent
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accentPrimarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.accentPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.smart_display_rounded,
                    color: colors.accentPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learn from Any Video',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paste YouTube link or 11-char ID',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Input field container
            Container(
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorMessage != null
                      ? colors.error
                      : colors.borderColor,
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                onSubmitted: (_) => _startLearning(),
                decoration: InputDecoration(
                  hintText: 'https://youtu.be/... or video ID',
                  hintStyle: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13.5,
                  ),
                  prefixIcon: Icon(
                    Icons.link_rounded,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.content_paste_rounded,
                      color: colors.accentPrimary,
                      size: 20,
                    ),
                    tooltip: 'Paste from clipboard',
                    onPressed: _pasteFromClipboard,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colors.error,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            // "Start Learning" Coral Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _startLearning,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text(
                  'Start Learning',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
