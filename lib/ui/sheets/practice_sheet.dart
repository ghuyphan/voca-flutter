// lib/ui/sheets/practice_sheet.dart

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';

import 'voca_bottom_sheet.dart';

class PracticeSheet extends StatefulWidget {
  final VideoPlayerController controller;
  final YoutubePlayerController ytController;

  const PracticeSheet({
    super.key,
    required this.controller,
    required this.ytController,
  });

  static Future<void> show(
    BuildContext context, {
    required VideoPlayerController controller,
    required YoutubePlayerController ytController,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('practice.title', null, 'Immersion Practice'),
      subtitle: context.t('practice.subtitle', null, 'Master pronunciation and active recall'),
      showCloseButton: true,
      maxHeightFactor: 0.90,
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      builder: (_) => PracticeSheet(
        controller: controller,
        ytController: ytController,
      ),
    );
  }

  @override
  State<PracticeSheet> createState() => _PracticeSheetState();
}

class _PracticeSheetState extends State<PracticeSheet> {
  int _selectedTabIndex = 0; // 0: Shadowing, 1: Cloze Quiz

  // Cloze Quiz state
  int? _selectedOptionIndex;
  bool? _isCorrect;
  Token? _hiddenToken;
  List<String> _quizOptions = [];

  @override
  void initState() {
    super.initState();
    _prepareClozeQuiz();
  }

  void _prepareClozeQuiz() {
    final activeCue = widget.controller.activeCue.value;
    if (activeCue == null || activeCue.tokens.isEmpty) {
      _hiddenToken = null;
      _quizOptions = [];
      return;
    }

    // Find a substantive token (not punctuation)
    final candidateTokens = activeCue.tokens
        .where((t) => !t.isPunctuation && t.surface.trim().length >= 2)
        .toList();

    if (candidateTokens.isEmpty) {
      _hiddenToken = activeCue.tokens.firstWhere(
        (t) => !t.isPunctuation,
        orElse: () => activeCue.tokens.first,
      );
    } else {
      _hiddenToken = candidateTokens.first;
    }

    // Create 4 multiple choice options
    final correctWord = _hiddenToken!.surface;
    final otherWords = <String>{};

    for (final cue in widget.controller.cues.value) {
      for (final t in cue.tokens) {
        if (!t.isPunctuation && t.surface != correctWord && t.surface.length >= 2) {
          otherWords.add(t.surface);
          if (otherWords.length >= 3) break;
        }
      }
      if (otherWords.length >= 3) break;
    }

    // Fallbacks if fewer than 3 other words
    final fallbacks = ['こと', 'する', 'から', 'ため', 'ある', 'いい'];
    for (final f in fallbacks) {
      if (otherWords.length >= 3) break;
      if (f != correctWord) otherWords.add(f);
    }

    final allOptions = [correctWord, ...otherWords.take(3)]..shuffle();
    setState(() {
      _quizOptions = allOptions;
      _selectedOptionIndex = null;
      _isCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final activeCue = widget.controller.activeCue.value;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Tabs: Shadowing vs Cloze Quiz
          Container(
            decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColor),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0 ? colors.accentPrimary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.record_voice_over_rounded,
                                size: 16,
                                color: _selectedTabIndex == 0 ? Colors.white : colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.t('practice.shadowing', null, 'Shadowing'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTabIndex == 0 ? Colors.white : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1 ? colors.accentPrimary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology_rounded,
                                size: 16,
                                color: _selectedTabIndex == 1 ? Colors.white : colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.t('practice.cloze', null, 'Cloze Quiz'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTabIndex == 1 ? Colors.white : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Sentence Display Card
              if (activeCue != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.accentPrimarySoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatTime(activeCue.start),
                              style: TextStyle(
                                color: colors.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.replay_rounded, size: 18, color: colors.textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: context.t('practice.replayCue', null, 'Replay cue'),
                            onPressed: () {
                              widget.ytController.seekTo(seconds: activeCue.start, allowSeekAhead: true);
                              widget.ytController.playVideo();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // In Quiz mode, mask the target word
                      if (_selectedTabIndex == 1 && _hiddenToken != null)
                        Text(
                          activeCue.text.replaceAll(_hiddenToken!.surface, '【 ? 】'),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        )
                      else
                        Text(
                          activeCue.text,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),

                      if (activeCue.translation != null && activeCue.translation!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          activeCue.translation!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    context.t('practice.noCueSelected', null, 'No active cue selected. Play the video to select a sentence.'),
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),

              // Tab 0: Shadowing Controls
              if (_selectedTabIndex == 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.controller.toggleLoopCurrentCue();
                          setState(() {});
                          if (activeCue != null) {
                            widget.ytController.seekTo(seconds: activeCue.start, allowSeekAhead: true);
                            widget.ytController.playVideo();
                          }
                        },
                        icon: Icon(
                          widget.controller.isLoopingCue.value
                              ? Icons.stop_rounded
                              : Icons.sync_rounded,
                          size: 18,
                        ),
                        label: Text(
                          widget.controller.isLoopingCue.value
                              ? context.t('practice.stopLoop', null, 'Stop Loop')
                              : context.t('practice.loopCue', null, 'Loop Sentence'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.controller.isLoopingCue.value
                              ? colors.error
                              : colors.accentPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        widget.ytController.setPlaybackRate(0.85);
                        widget.controller.playbackRate.value = 0.85;
                        ToastService.info(
                          context,
                          context.t('practice.rateSetNotice', null, 'Playback set to 0.85x for Shadowing'),
                          duration: const Duration(seconds: 1),
                        );
                      },
                      icon: const Icon(Icons.slow_motion_video_rounded, size: 16),
                      label: const Text('0.85x'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Tab 1: Cloze Quiz Options
              if (_selectedTabIndex == 1 && _hiddenToken != null) ...[
                Text(
                  context.t('practice.chooseMissingWord', null, 'Choose the missing word in the sentence above:'),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.8,
                  children: List.generate(_quizOptions.length, (idx) {
                    final opt = _quizOptions[idx];
                    final isSelected = _selectedOptionIndex == idx;
                    final isCorrectAnswer = opt == _hiddenToken!.surface;

                    Color bg = colors.bgSurface;
                    Color border = colors.borderColor;
                    Color textCol = colors.textPrimary;

                    if (_selectedOptionIndex != null) {
                      if (isCorrectAnswer) {
                        bg = colors.success.withOpacity(0.2);
                        border = colors.success;
                        textCol = colors.success;
                      } else if (isSelected) {
                        bg = colors.error.withOpacity(0.2);
                        border = colors.error;
                        textCol = colors.error;
                      }
                    }

                    return InkWell(
                      onTap: _selectedOptionIndex != null
                          ? null
                          : () {
                              setState(() {
                                _selectedOptionIndex = idx;
                                _isCorrect = isCorrectAnswer;
                              });
                              if (isCorrectAnswer) {
                                AppState.instance.gamificationService.addXp(15, reason: 'Sentence Cloze Quiz');
                              }
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border, width: isSelected ? 1.5 : 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          opt,
                          style: TextStyle(
                            color: textCol,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (_isCorrect != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _isCorrect! ? colors.success : colors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isCorrect!
                            ? context.t('practice.correct', null, 'Correct! +15 XP')
                            : context.t('practice.incorrect', null, 'Not quite, try the next sentence!'),
                        style: TextStyle(
                          color: _isCorrect! ? colors.success : colors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
    );
  }

  String _formatTime(double seconds) {
    final totalSecs = seconds.floor();
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
