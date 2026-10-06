// lib/ui/gamification/ai_credits_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../widgets/voca_back_button.dart';
import 'widgets/rpg_shield_crest.dart';

/// Dedicated Full-Screen Experience for AI Credits, Usage, Pro & Founder Upgrades, and VietQR Checkout.
class AiCreditsScreen extends StatefulWidget {
  final bool initialShowCheckout;

  const AiCreditsScreen({
    super.key,
    this.initialShowCheckout = false,
  });

  @override
  State<AiCreditsScreen> createState() => _AiCreditsScreenState();
}

class _AiCreditsScreenState extends State<AiCreditsScreen> {
  String _selectedTier = 'pro'; // 'pro' or 'premium'
  String _selectedPlan = 'pro_1y'; // 'pro_1m', 'pro_1y', 'premium_1m', 'premium_1y'
  bool _showCheckout = false;

  Timer? _countdownTimer;
  Duration _timeUntilRefill = const Duration(minutes: 8, seconds: 45);

  @override
  void initState() {
    super.initState();
    _showCheckout = widget.initialShowCheckout;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_timeUntilRefill.inSeconds > 0) {
            _timeUntilRefill -= const Duration(seconds: 1);
          } else {
            _timeUntilRefill = const Duration(minutes: 10);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final gamification = AppState.instance.gamificationService;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 68,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: VocaBackButton(),
          ),
        ),
        centerTitle: true,
        title: Text(
          context.t('subtitle.aiCredits', null, 'AI Credits & Upgrades'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textMuted, size: 22),
            onPressed: () async {
              await gamification.refreshDiamonds();
              if (context.mounted) {
                ToastService.success(context, 'AI Credits refreshed from cloud.');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Watch((context) {
          final diamonds = gamification.diamonds.value;
          final maxDiamonds = gamification.maxDiamonds.value;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // 1. Hero Diamond RPG Shield Crest
                _buildHeroDiamondCrest(colors),
                const SizedBox(height: 18),

                // 2. Credits Count Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$diamonds',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      ' / $maxDiamonds',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.35)),
                      ),
                      child: Text(
                        context.t('subtitle.creditsAvailable', null, 'Available'),
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Live Countdown or Auto-refill Pill
                if (diamonds < maxDiamonds)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.bgSecondary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 6),
                        Text(
                          '+1 credit in ${_formatTimer(_timeUntilRefill)}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                // Depleted notice if 0
                if (diamonds == 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: colors.warning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.t('subtitle.depletedNotice', null, 'Out of AI credits. Videos with existing captions are always free.'),
                            style: TextStyle(color: colors.textPrimary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 4. Usage Overview Cards (Captions vs AI Audio)
                _buildUsageOverviewCards(context, colors),
                const SizedBox(height: 28),

                // 5. Tier Switcher & Pro Comparison Section
                _buildProUpgradeSection(context, colors),
                const SizedBox(height: 24),

                // 6. VietQR Checkout Card (Conditional or Expandable)
                if (_showCheckout)
                  _buildVietQrCheckoutCard(context, colors)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showCheckout = true),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: Text(
                        context.t('pro.openVietQr', null, 'Pay with VietQR / Banking App'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTier == 'premium' ? const Color(0xFF7C3AED) : colors.accentPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Hero Diamond RPG Shield Crest
  Widget _buildHeroDiamondCrest(VocaColorPalette colors) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x3338BDF8),
          ),
        ),
        const RpgShieldCrest(
          width: 76,
          height: 86,
          style: RpgCrestStyle.diamond,
          icon: Icons.diamond_rounded,
          iconSize: 38,
          innerInset: 3.0,
        ),
      ],
    );
  }

  /// Usage Breakdown Cards
  Widget _buildUsageOverviewCards(BuildContext context, VocaColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.t('subtitle.howCreditsWork', null, 'How Credits Work'),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Free Native Captions
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.subtitles_rounded, color: colors.success, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('subtitle.nativeCaptionsTitle', null, 'Videos with Captions'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.t('subtitle.nativeCaptionsDesc', null, '100% Free and unlimited. Does not use credits.'),
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FREE',
                  style: TextStyle(color: colors.success, fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // AI Whisper Speech-to-Text
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('subtitle.aiTranscriptionTitle', null, 'AI Audio Transcription'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.t('subtitle.aiTranscriptionDesc', null, 'For videos without native captions (1-2 credits). Refills automatically.'),
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '1-2 💎',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Pro & Founder Plan Comparison Section
  Widget _buildProUpgradeSection(BuildContext context, VocaColorPalette colors) {
    final isPremium = _selectedTier == 'premium';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.t('pro.choosePlan', null, 'Supporter & Immersion Plans'),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tier Switcher: Voca Pro vs Founder VIP
        Container(
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTier = 'pro';
                      _selectedPlan = 'pro_1y';
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !isPremium ? colors.bgCard : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 16, color: colors.accentPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Voca Pro',
                          style: TextStyle(
                            color: !isPremium ? colors.textPrimary : colors.textMuted,
                            fontSize: 13,
                            fontWeight: !isPremium ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTier = 'premium';
                      _selectedPlan = 'premium_1y';
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPremium ? colors.bgCard : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.diamond_rounded, size: 16, color: Color(0xFFA78BFA)),
                        const SizedBox(width: 6),
                        Text(
                          'Founder VIP',
                          style: TextStyle(
                            color: isPremium ? colors.textPrimary : colors.textMuted,
                            fontSize: 13,
                            fontWeight: isPremium ? FontWeight.bold : FontWeight.w500,
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
        const SizedBox(height: 14),

        // Plan Cards (Annual vs Monthly)
        Row(
          children: [
            Expanded(
              child: _buildPlanCard(
                colors: colors,
                id: isPremium ? 'premium_1y' : 'pro_1y',
                title: isPremium ? 'Annual Founder' : 'Annual Pro',
                price: isPremium ? '499,000 đ' : '299,000 đ',
                period: '/ year',
                badge: 'SAVE 45%',
                isSelected: _selectedPlan == (isPremium ? 'premium_1y' : 'pro_1y'),
                onTap: () => setState(() => _selectedPlan = isPremium ? 'premium_1y' : 'pro_1y'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPlanCard(
                colors: colors,
                id: isPremium ? 'premium_1m' : 'pro_1m',
                title: isPremium ? 'Monthly Founder' : 'Monthly Pro',
                price: isPremium ? '69,000 đ' : '39,000 đ',
                period: '/ month',
                badge: null,
                isSelected: _selectedPlan == (isPremium ? 'premium_1m' : 'pro_1m'),
                onTap: () => setState(() => _selectedPlan = isPremium ? 'premium_1m' : 'pro_1m'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Benefits Checklist
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPremium ? const Color(0xFFA78BFA).withOpacity(0.4) : colors.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPremium ? "What's in Founder VIP:" : "What's in Voca Pro:",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (!isPremium) ...[
                _buildBenefitRow(colors, '10 Daily Audio Passes (Refills every 10m)', Icons.bolt_rounded),
                _buildBenefitRow(colors, 'Videos up to 20 Minutes transcribed', Icons.timer_outlined),
                _buildBenefitRow(colors, 'Priority AI speech processing queue', Icons.speed_rounded),
                _buildBenefitRow(colors, 'Infinite Spaced Repetition SRS Decks', Icons.style_outlined),
                _buildBenefitRow(colors, 'Seamless Cross-Platform Cloud Sync', Icons.cloud_done_outlined),
              ] else ...[
                _buildBenefitRow(colors, '25 Daily Audio Passes (Rapid 4m refill)', Icons.diamond_rounded),
                _buildBenefitRow(colors, 'Long-Form Videos & Podcasts up to 45 Mins', Icons.podcasts_rounded),
                _buildBenefitRow(colors, 'VIP Instant Priority Queue', Icons.flash_on_rounded),
                _buildBenefitRow(colors, 'Unlimited Bilingual Subtitles & Translations', Icons.translate_rounded),
                _buildBenefitRow(colors, 'Exclusive Founder VIP Profile Flair', Icons.military_tech_rounded),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required VocaColorPalette colors,
    required String id,
    required String title,
    required String price,
    required String period,
    required String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (_selectedTier == 'premium'
                  ? const Color(0xFFA78BFA).withOpacity(0.12)
                  : colors.accentPrimarySoft)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (_selectedTier == 'premium' ? const Color(0xFFA78BFA) : colors.accentPrimary)
                : colors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
              )
            else
              const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(VocaColorPalette colors, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _selectedTier == 'premium' ? const Color(0xFFA78BFA) : colors.accentPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Authentic VietQR Payment Checkout Card
  Widget _buildVietQrCheckoutCard(BuildContext context, VocaColorPalette colors) {
    const bankName = 'MBBank (970422)';
    const accountNo = '0987654321';
    const recipient = 'VOCA IMMERSION EDUTECH';
    final amount = _selectedPlan == 'pro_1y'
        ? '299,000 đ'
        : (_selectedPlan == 'pro_1m'
            ? '39,000 đ'
            : (_selectedPlan == 'premium_1y' ? '499,000 đ' : '69,000 đ'));
    final memo = 'VOCA ${_selectedPlan.toUpperCase()}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VietQR Direct Payment',
                style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: colors.textMuted),
                onPressed: () => setState(() => _showCheckout = false),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // QR Code Display
          Container(
            width: 180,
            height: 180,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 130, color: Colors.blue.shade900),
                  Text(
                    'MBBANK • VIETQR',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('pro.scanPrompt', null, 'Scan VietQR with any mobile banking or e-wallet app'),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Bank Details Rows with Copy Buttons
          _buildBankRow(colors, 'Bank', bankName),
          _buildBankRowWithCopy(context, colors, 'Account No.', accountNo),
          _buildBankRow(colors, 'Recipient', recipient),
          _buildBankRow(colors, 'Amount', amount),
          _buildBankRowWithCopy(context, colors, 'Transfer Memo', memo),

          const SizedBox(height: 16),

          // Waiting status pulse
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Auto-detecting payment via payOS...',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankRow(VocaColorPalette colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 12)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBankRowWithCopy(BuildContext context, VocaColorPalette colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 12)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ToastService.info(context, 'Copied $label: $value');
                },
                child: Icon(Icons.copy_rounded, size: 14, color: colors.accentPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
