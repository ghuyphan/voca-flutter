// lib/ui/sheets/create_playlist_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import 'voca_bottom_sheet.dart';

/// Bottom sheet dialog for creating or editing playlists.
/// Ported from lingua-tube's CreatePlaylistDialogComponent.
class CreatePlaylistSheet extends StatefulWidget {
  final PlaylistItem? playlist;
  final VoidCallback? onSaved;

  const CreatePlaylistSheet({
    super.key,
    this.playlist,
    this.onSaved,
  });

  static Future<bool?> show(
    BuildContext context, {
    PlaylistItem? playlist,
    VoidCallback? onSaved,
  }) {
    return showVocaBottomSheet<bool>(
      context: context,
      title: playlist != null
          ? context.t('playlist.edit', null, 'Edit Playlist')
          : context.t('playlist.create', null, 'New Playlist'),
      showCloseButton: true,
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      builder: (ctx) => CreatePlaylistSheet(
        playlist: playlist,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<CreatePlaylistSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _selectedLang;
  late String _selectedLevel;
  late String _visibility;
  bool _isSubmitting = false;

  bool get isEditing => widget.playlist != null;

  @override
  void initState() {
    super.initState();
    final p = widget.playlist;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _selectedLang = p?.language ?? AppState.instance.activeLanguage.value;
    _selectedLevel = p?.level ?? '';
    _visibility = p?.visibility ?? 'private';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getLevelOptions() {
    switch (_selectedLang) {
      case 'ja':
        return [
          {'value': '', 'label': 'Auto Level'},
          {'value': 'JLPT N5', 'label': 'N5 (Beginner)'},
          {'value': 'JLPT N4', 'label': 'N4 (Elementary)'},
          {'value': 'JLPT N3', 'label': 'N3 (Intermediate)'},
          {'value': 'JLPT N2', 'label': 'N2 (Upper Intermediate)'},
          {'value': 'JLPT N1', 'label': 'N1 (Advanced)'},
        ];
      case 'zh':
        return [
          {'value': '', 'label': 'Auto Level'},
          {'value': 'HSK 1', 'label': 'HSK 1 (Beginner)'},
          {'value': 'HSK 2', 'label': 'HSK 2 (Elementary)'},
          {'value': 'HSK 3', 'label': 'HSK 3 (Intermediate)'},
          {'value': 'HSK 4', 'label': 'HSK 4 (Upper Intermediate)'},
          {'value': 'HSK 5', 'label': 'HSK 5 (Advanced)'},
          {'value': 'HSK 6', 'label': 'HSK 6 (Mastery)'},
        ];
      case 'ko':
        return [
          {'value': '', 'label': 'Auto Level'},
          {'value': 'TOPIK 1', 'label': 'TOPIK 1 (Beginner)'},
          {'value': 'TOPIK 2', 'label': 'TOPIK 2 (Elementary)'},
          {'value': 'TOPIK 3', 'label': 'TOPIK 3 (Intermediate)'},
          {'value': 'TOPIK 4', 'label': 'TOPIK 4 (Upper Intermediate)'},
          {'value': 'TOPIK 5', 'label': 'TOPIK 5 (Advanced)'},
          {'value': 'TOPIK 6', 'label': 'TOPIK 6 (Mastery)'},
        ];
      default:
        return [
          {'value': '', 'label': 'Auto Level'},
          {'value': 'CEFR A1', 'label': 'A1 (Beginner)'},
          {'value': 'CEFR A2', 'label': 'A2 (Elementary)'},
          {'value': 'CEFR B1', 'label': 'B1 (Intermediate)'},
          {'value': 'CEFR B2', 'label': 'B2 (Upper Intermediate)'},
          {'value': 'CEFR C1', 'label': 'C1 (Advanced)'},
          {'value': 'CEFR C2', 'label': 'C2 (Mastery)'},
        ];
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ToastService.warning(context, context.t('playlist.titleRequired', null, 'Please enter a title for the playlist'));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final supabase = AppState.instance.supabaseService;
      if (isEditing) {
        // Updating existing
        await supabase.updatePlaylist(
          id: widget.playlist!.id,
          title: title,
          description: _descController.text.trim(),
          language: _selectedLang,
          visibility: _visibility,
          level: _selectedLevel,
        );
      } else {
        await supabase.createPlaylist(
          title: title,
          description: _descController.text.trim(),
          language: _selectedLang,
          visibility: _visibility,
          level: _selectedLevel,
        );
      }

      if (mounted) {
        ToastService.success(
          context,
          isEditing
              ? context.t('playlist.updatedSuccess', null, 'Playlist updated successfully')
              : context.t('playlist.createdSuccess', null, 'Playlist created successfully'),
        );
        widget.onSaved?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(
          context,
          context.t('playlist.saveFailed', {'error': e.toString()}, 'Failed to save playlist: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final levelOptions = _getLevelOptions();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist Title Field
          Text(
            context.t('playlist.title', null, 'Playlist Title').toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: context.t('playlist.titlePlaceholder', null, 'e.g. Japanese City Pop & Lyrics'),
              hintStyle: TextStyle(color: colors.textMuted),
              filled: true,
              fillColor: colors.bgSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Field
          Text(
            context.t('playlist.description', null, 'Description (Optional)').toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 2,
            style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: context.t('playlist.descPlaceholder', null, 'Short notes about this collection'),
              hintStyle: TextStyle(color: colors.textMuted),
              filled: true,
              fillColor: colors.bgSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target Language Row
          Text(
            context.t('common.language', null, 'Language').toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLang,
                dropdownColor: colors.bgCard,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, color: colors.textSecondary),
                items: [
                  DropdownMenuItem(value: 'ja', child: Text('🇯🇵 ${context.t('settings.japanese', null, 'Japanese')}')),
                  DropdownMenuItem(value: 'zh', child: Text('🇨🇳 ${context.t('settings.chinese', null, 'Chinese')}')),
                  DropdownMenuItem(value: 'ko', child: Text('🇰🇷 ${context.t('settings.korean', null, 'Korean')}')),
                  DropdownMenuItem(value: 'en', child: Text('🇺🇸 ${context.t('settings.english', null, 'English')}')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedLang = val;
                      _selectedLevel = ''; // reset level for new language
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target Level Row
          Text(
            context.t('level.targetLevel', null, 'Target Difficulty Level').toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLevel,
                dropdownColor: colors.bgCard,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, color: colors.textSecondary),
                items: levelOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value']!,
                    child: Text(opt['label']!, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLevel = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(context.t('common.cancel', null, 'Cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEditing
                              ? context.t('common.save', null, 'Save')
                              : context.t('playlist.create', null, 'Create Playlist'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
