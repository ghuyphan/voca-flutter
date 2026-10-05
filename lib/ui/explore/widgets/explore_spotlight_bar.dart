// lib/ui/explore/widgets/explore_spotlight_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../../utils/youtube_url_parser.dart';

/// Authentic Spotlight Search Bar matching lingua-tube's .spotlight-bar & AGENTS.md Section 4.1.
class ExploreSpotlightBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClear;
  final ValueChanged<String>? onDirectVideoDetected;

  const ExploreSpotlightBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onSearchSubmitted,
    required this.onClear,
    this.onDirectVideoDetected,
  });

  @override
  State<ExploreSpotlightBar> createState() => _ExploreSpotlightBarState();
}

class _ExploreSpotlightBarState extends State<ExploreSpotlightBar>
    with WidgetsBindingObserver {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  Timer? _debounceTimer;
  bool _hasClipboardText = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    widget.controller.addListener(_onTextChange);
    _checkClipboard();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final hasStrings = await Clipboard.hasStrings();
      if (mounted && hasStrings != _hasClipboardText) {
        setState(() {
          _hasClipboardText = hasStrings;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChange() {
    if (mounted) setState(() {});
  }

  void _handleSubmit(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final videoId = YouTubeUrlParser.extractVideoId(trimmed);
    if (videoId != null && widget.onDirectVideoDetected != null) {
      widget.onDirectVideoDetected!(videoId);
    } else {
      _focusNode.unfocus();
      widget.onSearchSubmitted(trimmed);
    }
  }

  Future<void> _handlePasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isNotEmpty) {
        widget.controller.text = text;
        _handleSubmit(text);
      }
      _checkClipboard();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = widget.controller.text;
    final hasText = text.isNotEmpty;
    final directVideoId = hasText ? YouTubeUrlParser.extractVideoId(text.trim()) : null;

    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.35 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Icon: Link icon if video detected, otherwise Search (subtle, no focus highlight)
          Icon(
            directVideoId != null ? Icons.link_rounded : Icons.search_rounded,
            color: directVideoId != null ? colors.accentPrimary : colors.textMuted,
            size: 19,
          ),
          const SizedBox(width: 10),

          // Input Text Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              cursorColor: colors.accentPrimary,
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSubmit,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: context.t('explore.searchHint', null, 'Paste YouTube URL or search...'),
                hintStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Right Actions: Clear when non-empty, otherwise Paste
          if (hasText) ...[
            // Clear button
            Tooltip(
              message: context.t('common.clear', null, 'Clear'),
              child: InkWell(
                onTap: widget.onClear,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 14, color: colors.textMuted),
                ),
              ),
            ),
          ] else if (_hasClipboardText) ...[
            // Contextual paste from clipboard button
            Tooltip(
              message: context.t('commandPalette.paste', null, 'Paste from clipboard'),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handlePasteFromClipboard,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.content_paste_rounded,
                      size: 15,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
