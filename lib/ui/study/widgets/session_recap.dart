// lib/ui/study/widgets/session_recap.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/study_session_models.dart';
import '../../../services/i18n_service.dart';
import '../../../state/app_state.dart';

class SessionRecap extends StatelessWidget {
  final SessionStats stats;
  final VoidCallback onFinish;
  final VoidCallback? onReviewAgain;

  const SessionRecap({
    super.key,
    required this.stats,
    required this.onFinish,
    this.onReviewAgain,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final streak = AppState.instance.currentStreak.value;
    final accuracy = stats.totalReviewed > 0
        ? stats.accuracyRate.round()
        : 100;
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;

    // Rank tier based on accuracy
    final isGold = accuracy >= 90;
    final isSilver = accuracy >= 75 && accuracy < 90;
    final crestColor = isGold
        ? colors.accentTertiary
        : (isSilver ? const Color(0xFF94A3B8) : const Color(0xFFD97706));
    final rankTitle = isGold
        ? context.t('gamification.gold', null, 'Gold Champion')
        : (isSilver
            ? context.t('gamification.silver', null, 'Silver Knight')
            : context.t('gamification.bronze', null, 'Bronze Warrior'));

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // RPG Shield Crest
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: crestColor.withValues(alpha: 0.15),
                  border: Border.all(color: crestColor, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: crestColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isGold ? Icons.emoji_events_rounded : Icons.shield_rounded,
                  size: 48,
                  color: crestColor,
                ),
              ),

              const SizedBox(height: 12),

              // Rank Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: crestColor.withValues(alpha: 0.12),
                  borderRadius: VocaRadius.roundedPill,
                  border: Border.all(color: crestColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  rankTitle,
                  style: TextStyle(
                    color: crestColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                context.t('flashcards.sessionComplete', null, 'Session Complete!'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t('flashcards.sessionCompleteDesc', null, 'All spaced repetition reviews for this queue are finished.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),

              const SizedBox(height: 20),

              // Streak & Diamonds Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: VocaRadius.roundedLg,
                        border: Border.all(color: colors.colorFire.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.local_fire_department_rounded, color: colors.colorFire, size: 26),
                          const SizedBox(height: 4),
                          Text(
                            '$streak ${context.t('gamification.dayStreak', null, 'Day Streak')}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            context.t('flashcards.keepItUp', null, 'Keep it up!'),
                            style: TextStyle(color: colors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: VocaRadius.roundedLg,
                        border: Border.all(color: colors.colorDiamond.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.diamond_rounded, color: colors.colorDiamond, size: 26),
                          const SizedBox(height: 4),
                          Text(
                            '+1 ${context.t('gamification.diamond', null, 'Diamond')}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            context.t('flashcards.dailyBonus', null, 'Daily bonus'),
                            style: TextStyle(color: colors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Detailed Session Metrics Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: VocaRadius.roundedLg,
                  border: Border.all(color: colors.borderColorLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('flashcards.sessionRecap', null, 'PERFORMANCE BREAKDOWN'),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildRecapItem(
                          context.t('flashcards.recapReviewed', null, 'Reviewed'),
                          '${stats.totalReviewed}',
                          colors.accentPrimary,
                          colors,
                        ),
                        _buildRecapItem(
                          context.t('flashcards.recapAccuracy', null, 'Accuracy'),
                          '$accuracy%',
                          accuracy >= 80 ? colors.colorGrammar : colors.warning,
                          colors,
                        ),
                        _buildRecapItem(
                          context.t('flashcards.good', null, 'Good / Easy'),
                          '${stats.goodOrEasyCount}',
                          colors.colorGrammar,
                          colors,
                        ),
                        _buildRecapItem(
                          context.t('flashcards.again', null, 'To Review'),
                          '${stats.againOrHardCount}',
                          stats.againOrHardCount > 0 ? colors.error : colors.textMuted,
                          colors,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (onReviewAgain != null && stats.againOrHardCount > 0) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onReviewAgain,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(context.t(
                      'flashcards.reviewAgainCount',
                      {'count': stats.againOrHardCount.toString()},
                      'Review Missed Cards (${stats.againOrHardCount})',
                    )),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accentPrimary,
                      side: BorderSide(color: colors.accentPrimary, width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: VocaRadius.roundedPill),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: onFinish,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    context.t('study.done', null, 'Done'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: VocaRadius.roundedPill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecapItem(
    String label,
    String value,
    Color color,
    VocaColorPalette colors,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
