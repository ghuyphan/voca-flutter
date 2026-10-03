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

class _ExploreSpotlightBarState extends State<ExploreSpotlightBar> {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = widget.controller.text;
    final hasText = text.isNotEmpty;
    final isFocused = _focusNode.hasFocus;
    final directVideoId = hasText ? YouTubeUrlParser.extractVideoId(text.trim()) : null;
    final isHighlighted = isFocused || directVideoId != null;

    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted ? colors.accentPrimary : colors.borderColor,
          width: isHighlighted ? 1.5 : 1.0,
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
          // Left Icon: Link icon if video detected, otherwise Search
          Icon(
            directVideoId != null ? Icons.link_rounded : Icons.search_rounded,
            color: isHighlighted ? colors.accentPrimary : colors.textMuted,
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

          // Right Actions: Clear + Load/Search when non-empty, otherwise Paste
          if (hasText) ...[
            // Clear button with tooltip
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
            const SizedBox(width: 8),

            // Load / Search primary CTA button
            ElevatedButton(
              onPressed: () => _handleSubmit(text),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 30),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    directVideoId != null ? Icons.arrow_forward_rounded : Icons.search_rounded,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    directVideoId != null
                        ? context.t('player.load', null, 'Load')
                        : context.t('player.search', null, 'Search'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Paste from clipboard icon button (matches lingua-tube .spotlight__paste-btn & command-palette.component.html)
            Tooltip(
              message: context.t('commandPalette.paste', null, 'Paste from clipboard'),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handlePasteFromClipboard,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 16,
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
