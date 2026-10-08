// lib/ui/explore/widgets/explore_spotlight_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../../utils/youtube_url_parser.dart';

/// Modern Spotlight Search Bar using Flutter's official Material 3 SearchBar & IconButton.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SearchBar(
        controller: widget.controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: _handleSubmit,
        constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(colors.bgCard),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          StadiumBorder(
            side: BorderSide(
              color: colors.borderColor,
              width: 1.0,
            ),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.only(left: 14, right: 8)),
        hintText: context.t('explore.searchHint', null, 'Paste YouTube URL or search...'),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(
            color: colors.textMuted,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            directVideoId != null ? Icons.link_rounded : Icons.search_rounded,
            key: ValueKey(directVideoId != null),
            color: directVideoId != null ? colors.accentPrimary : colors.textMuted,
            size: 19,
          ),
        ),
        trailing: [
          if (hasText)
            IconButton(
              onPressed: widget.onClear,
              tooltip: context.t('common.clear', null, 'Clear'),
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: colors.bgSurface,
                foregroundColor: colors.textMuted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
              ),
              icon: const Icon(Icons.close_rounded),
            )
          else if (_hasClipboardText)
            IconButton(
              onPressed: _handlePasteFromClipboard,
              tooltip: context.t('commandPalette.paste', null, 'Paste from clipboard'),
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: colors.bgSurface,
                foregroundColor: colors.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
              ),
              icon: const Icon(Icons.content_paste_rounded),
            ),
        ],
      ),
    );
  }
}
