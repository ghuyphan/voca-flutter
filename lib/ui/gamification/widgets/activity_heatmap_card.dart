// lib/ui/gamification/widgets/activity_heatmap_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../config/voca_theme.dart';
import '../../../services/gamification_service.dart';
import '../../../services/i18n_service.dart';

/// Reusable 30-Day Activity Heatmap Card.
/// Provides a unified, GitHub-style 2x15 activity grid with M3 interactive tap tooltips.
class ActivityHeatmapCard extends StatelessWidget {
  final VocaColorPalette colors;
  final GamificationService gamification;
  final bool showOuterContainer;
  final String? customTitle;

  const ActivityHeatmapCard({
    super.key,
    required this.colors,
    required this.gamification,
    this.showOuterContainer = true,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activeDates = gamification.activeDates;
      final df = DateFormat('yyyy-MM-dd');
      final streak = gamification.currentStreak.value;

      final days = List.generate(30, (i) {
        final d = DateTime(today.year, today.month, today.day - (29 - i));
        final dStr = df.format(d);
        final isActive = activeDates.contains(dStr);
        final isToday = (i == 29);
        return (date: d, isActive: isActive, isToday: isToday, index: i);
      });

      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Icon + Title + Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 16, color: colors.colorFire),
                  const SizedBox(width: 8),
                  Text(
                    customTitle ?? context.t('study.last30Days', null, 'Last 30 days'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    context.t('study.less', null, 'Less'),
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colors.isDark ? colors.bgSurface : colors.bgSecondary,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: colors.borderColor, width: 0.6),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colors.colorGrammar.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colors.colorGrammar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.t('study.more', null, 'More'),
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2 Rows of 15 tiles (Zero layout-shift, interactive tap tooltips)
          Column(
            children: [
              _buildRow(context, colors, days.sublist(0, 15)),
              const SizedBox(height: 4),
              _buildRow(context, colors, days.sublist(15, 30)),
            ],
          ),

          const SizedBox(height: 10),

          // Footer: Streak + Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 14, color: colors.colorFire),
                  const SizedBox(width: 4),
                  Text(
                    '$streak ${context.t('streak.dayStreak', null, 'days streak')}',
                    style: TextStyle(
                      color: colors.colorFire,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                context.t('study.tapDayToView', null, 'Tap a day to view'),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );

      if (!showOuterContainer) {
        return content;
      }

      return Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: content,
      );
    });
  }

  Widget _buildRow(
    BuildContext context,
    VocaColorPalette colors,
    List<({DateTime date, bool isActive, bool isToday, int index})> rowDays,
  ) {
    return Row(
      children: List.generate(rowDays.length, (col) {
        final dayInfo = rowDays[col];

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: false,
                verticalOffset: 10,
                showDuration: const Duration(milliseconds: 2500),
                waitDuration: Duration.zero,
                enableFeedback: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFFE8EAF0) : const Color(0xFF1E2128),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: dayInfo.isActive
                        ? (colors.isDark ? const Color(0xFF10B981) : const Color(0xFF10B981))
                        : (colors.isDark ? Colors.transparent : Colors.black26),
                    width: 1.0,
                  ),
                ),
                richMessage: TextSpan(
                  children: [
                    TextSpan(
                      text: '${DateFormat('EEEE, MMM d').format(dayInfo.date)}${dayInfo.isToday ? ' (Today)' : ''}\n',
                      style: TextStyle(
                        color: colors.isDark ? const Color(0xFF0D0F14) : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    TextSpan(
                      text: dayInfo.isActive
                          ? '✓ ${context.t('study.heatmapReviewed', null, 'Reviewed & Active')}'
                          : '· ${context.t('study.heatmapRestDay', null, 'Rest day')}',
                      style: TextStyle(
                        color: dayInfo.isActive
                            ? (colors.isDark ? const Color(0xFF059669) : const Color(0xFF34D399))
                            : (colors.isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: dayInfo.isActive
                        ? colors.colorGrammar
                        : (colors.isDark ? colors.bgSurface : colors.bgSecondary),
                    borderRadius: BorderRadius.circular(3.5),
                    border: dayInfo.isToday
                        ? Border.all(color: colors.accentPrimary, width: 1.5)
                        : Border.all(color: colors.borderColor, width: 0.8),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
