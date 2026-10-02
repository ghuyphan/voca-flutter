// lib/ui/widgets/voca_search_input.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';

/// Reusable search input matching lingua-tube's SearchInputComponent.
class VocaSearchInput extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final Duration debounceDuration;

  const VocaSearchInput({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<VocaSearchInput> createState() => _VocaSearchInputState();
}

class _VocaSearchInputState extends State<VocaSearchInput> {
  late TextEditingController _effectiveController;
  Timer? _debounceTimer;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _showClear = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _effectiveController.text.isNotEmpty;
    if (_showClear != hasText) {
      setState(() => _showClear = hasText);
    }

    if (widget.onChanged != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.debounceDuration, () {
        widget.onChanged!(_effectiveController.text);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _effectiveController.dispose();
    } else {
      _effectiveController.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _handleClear() {
    _effectiveController.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      child: TextField(
        controller: _effectiveController,
        autofocus: widget.autofocus,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        cursorColor: colors.accentPrimary,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
          suffixIcon: _showClear
              ? IconButton(
                  icon: Icon(Icons.cancel_rounded, color: colors.textMuted, size: 18),
                  splashRadius: 16,
                  onPressed: _handleClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}
