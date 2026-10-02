// lib/ui/sheets/new_video_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/voca_theme.dart';
import '../../utils/youtube_url_parser.dart';
import '../../state/player_coordinator.dart';

/// Authentic New Video Bottom Sheet matching lingua-tube.
class NewVideoSheet extends StatefulWidget {
  final void Function(String videoId)? onVideoSelected;

  const NewVideoSheet({super.key, this.onVideoSelected});

  /// Displays the NewVideoSheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    void Function(String videoId)? onVideoSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: NewVideoSheet(onVideoSelected: onVideoSelected),
      ),
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
    return Container(
      decoration: const BoxDecoration(
        color: VocaTokens.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: VocaTokens.borderColor),
          left: BorderSide(color: VocaTokens.borderColor),
          right: BorderSide(color: VocaTokens.borderColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VocaTokens.borderColorHover,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with Coral Accent
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: VocaTokens.accentPrimarySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: VocaTokens.accentPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.smart_display_rounded,
                      color: VocaTokens.accentPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learn from Any Video',
                          style: TextStyle(
                            color: VocaTokens.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Paste YouTube link or 11-char ID',
                          style: TextStyle(
                            color: VocaTokens.textSecondary,
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
                  color: VocaTokens.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _errorMessage != null
                        ? VocaTokens.error
                        : VocaTokens.borderColor,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: const TextStyle(
                    color: VocaTokens.textPrimary,
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
                    hintStyle: const TextStyle(
                      color: VocaTokens.textMuted,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.link_rounded,
                      color: VocaTokens.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        color: VocaTokens.accentPrimary,
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
                    const Icon(
                      Icons.error_outline_rounded,
                      color: VocaTokens.error,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: VocaTokens.error,
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
                child: ElevatedButton.icon(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VocaTokens.accentPrimary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: VocaTokens.accentPrimary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
