// lib/ui/settings/offline_translation_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../../utils/language_utils.dart';
import '../widgets/circle_flag.dart';
import '../widgets/voca_back_button.dart';
import '../widgets/voca_confirm_dialog.dart';
import '../widgets/voca_download_progress_indicator.dart';
import '../widgets/voca_switch.dart';

/// Screen for managing on-device ML Kit language models and offline subtitle settings.
///
/// Complies with:
/// - RULE 1: Material 3 (M3) surface hierarchy, tokens from voca_theme.dart, min 48x48 touch targets
/// - RULE 5: Signal-first reactivity via Watch()
class OfflineTranslationScreen extends StatelessWidget {
  const OfflineTranslationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final appState = AppState.instance;
    final onDeviceService = appState.onDeviceTranslationService;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Center(child: VocaBackButton()),
        ),
        title: Text(
          context.t('settings.offlineTranslation', null, 'On-Device Translation'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Watch((context) {
        final settings = appState.userSettings.value;
        final downloaded = onDeviceService.downloadedLanguages.value;
        final downloading = onDeviceService.downloadingLanguages.value;
        final errors = onDeviceService.downloadErrors.value;
        final isSlowDevice = onDeviceService.isSlowDevice.value;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Informational Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.accentPrimarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.translate_rounded,
                        color: colors.accentPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t(
                            'settings.offlineDescTitle',
                            null,
                            'Instant On-Device Subtitles',
                          ),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.t(
                            'settings.offlineDescBody',
                            null,
                            'Language models run locally using Google ML Kit. Translations appear in <50ms with zero server latency and work completely offline.',
                          ),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Performance Warning Banner (if hardware triggered slow fallback)
            if (isSlowDevice) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded, color: colors.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.t(
                          'settings.slowDeviceNotice',
                          null,
                          'Translation was switched to cloud fallback due to high device latency.',
                        ),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        onDeviceService.resetPerformanceState();
                        ToastService.show(
                          context,
                          context.t(
                            'settings.performanceReset',
                            null,
                            'Performance monitor reset',
                          ),
                          type: ToastType.success,
                        );
                      },
                      child: Text(
                        context.t('common.retry', null, 'Retry'),
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. Settings Controls Group
            _buildSectionHeader(
              context.t('settings.preferences', null, 'PREFERENCES'),
              colors,
            ),
            Container(
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderColor),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: VocaSwitch(
                      value: settings.offlineTranslationEnabled,
                      label: context.t(
                        'settings.enableOffline',
                        null,
                        'Enable On-Device Translation',
                      ),
                      subtitle: context.t(
                        'settings.enableOfflineSub',
                        null,
                        'Prioritizes local models over cloud API calls',
                      ),
                      onChanged: (val) {
                        appState.updateUserSettings(
                          settings.copyWith(offlineTranslationEnabled: val),
                        );
                      },
                    ),
                  ),
                  Divider(height: 1, color: colors.borderColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: VocaSwitch(
                      value: settings.offlineTranslationWifiOnly,
                      label: context.t(
                        'settings.wifiOnly',
                        null,
                        'Download Models Over Wi-Fi Only',
                      ),
                      subtitle: context.t(
                        'settings.wifiOnlySub',
                        null,
                        'Protects cellular data plans (~30 MB per model)',
                      ),
                      onChanged: (val) {
                        appState.updateUserSettings(
                          settings.copyWith(offlineTranslationWifiOnly: val),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. On-Device Language Models List
            _buildSectionHeader(
              context.t('settings.languageModels', null, 'ON-DEVICE LANGUAGE MODELS (~30 MB EACH)'),
              colors,
            ),
            Container(
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderColor),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kSupportedSubtitleLanguages.length,
                separatorBuilder: (context, _) => Divider(
                  height: 1,
                  color: colors.borderColor,
                ),
                itemBuilder: (context, index) {
                  final lang = kSupportedSubtitleLanguages[index];
                  final isDownloaded = downloaded.contains(lang.code);
                  final isDownloading = downloading.contains(lang.code);
                  final err = errors[lang.code];

                  return _buildLanguageRow(
                    context: context,
                    colors: colors,
                    lang: lang,
                    isDownloaded: isDownloaded,
                    isDownloading: isDownloading,
                    errorMessage: err,
                    wifiOnly: settings.offlineTranslationWifiOnly,
                    onDownload: () async {
                      final success = await onDeviceService.downloadModel(
                        lang.code,
                        isWifiRequired: settings.offlineTranslationWifiOnly,
                      );
                      if (context.mounted && !success) {
                        final rawErr = onDeviceService.downloadErrors.value[lang.code];
                        if (rawErr != null) {
                          String toastMsg;
                          if (rawErr == 'settings.restartRequired' ||
                              rawErr.contains('MissingPluginException')) {
                            toastMsg = context.t(
                              'settings.restartRequired',
                              null,
                              'Please restart the app to activate on-device models',
                            );
                          } else if (rawErr == 'settings.downloadWaitingWifi') {
                            toastMsg = context.t(
                              'settings.downloadWaitingWifi',
                              null,
                              'Download failed or paused (waiting for Wi-Fi)',
                            );
                          } else {
                            toastMsg = rawErr;
                          }
                          ToastService.show(context, toastMsg, type: ToastType.error);
                        }
                      }
                    },
                    onDelete: () async {
                      final locName = lang.getLocalizedName(context);
                      final confirmed = await showVocaConfirmDialog(
                        context: context,
                        title: context.t(
                          'settings.removeModelTitle',
                          {'name': locName},
                          'Remove $locName model?',
                        ),
                        message: context.t(
                          'settings.removeModelMessage',
                          {'name': locName},
                          'This will remove the offline language model (~30 MB) from your device. You can download it again anytime.',
                        ),
                        confirmLabel: context.t('common.remove', null, 'Remove'),
                        variant: ConfirmDialogVariant.danger,
                        isDestructive: true,
                        icon: Icons.delete_outline_rounded,
                      );

                      if (confirmed && context.mounted) {
                        final success = await onDeviceService.deleteModel(lang.code);
                        if (context.mounted && success) {
                          ToastService.show(
                            context,
                            context.t(
                              'settings.modelRemoved',
                              {'name': locName},
                              '$locName model removed',
                            ),
                            type: ToastType.info,
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildLanguageRow({
    required BuildContext context,
    required VocaColorPalette colors,
    required SubtitleLanguageOption lang,
    required bool isDownloaded,
    required bool isDownloading,
    required String? errorMessage,
    required bool wifiOnly,
    required VoidCallback onDownload,
    required VoidCallback onDelete,
  }) {
    final localizedName = lang.getLocalizedName(context);
    final displayName = localizedName == lang.name
        ? lang.name
        : '$localizedName (${lang.name})';

    String? displayError;
    if (errorMessage != null) {
      if (errorMessage == 'settings.restartRequired' ||
          errorMessage.contains('MissingPluginException')) {
        displayError = context.t(
          'settings.restartRequired',
          null,
          'Please restart the app to activate on-device models',
        );
      } else if (errorMessage == 'settings.downloadWaitingWifi') {
        displayError = context.t(
          'settings.downloadWaitingWifi',
          null,
          'Download failed or paused (waiting for Wi-Fi)',
        );
      } else {
        displayError = errorMessage;
      }
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          CircleFlag(code: lang.code, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _buildSubtitle(context, colors, lang, isDownloaded, isDownloading),
                if (displayError != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    displayError,
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _buildActionWidget(
              context: context,
              colors: colors,
              lang: lang,
              isDownloaded: isDownloaded,
              isDownloading: isDownloading,
              onDownload: onDownload,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    VocaColorPalette colors,
    SubtitleLanguageOption lang,
    bool isDownloaded,
    bool isDownloading,
  ) {
    if (lang.isBuiltIn) {
      return Text(
        context.t('settings.builtInPivot', null, 'Built-in (Pivot language)'),
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    if (isDownloading) {
      return Text(
        context.t('settings.downloadingModel', null, 'Downloading model (~30 MB)...'),
        style: TextStyle(
          color: colors.accentPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (isDownloaded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 13,
            color: colors.colorGrammar,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.t('settings.modelReady', null, 'Downloaded • Ready on-device'),
              style: TextStyle(
                color: colors.colorGrammar,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      context.t('settings.notDownloaded', null, 'Not downloaded (~30 MB)'),
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildActionWidget({
    required BuildContext context,
    required VocaColorPalette colors,
    required SubtitleLanguageOption lang,
    required bool isDownloaded,
    required bool isDownloading,
    required VoidCallback onDownload,
    required VoidCallback onDelete,
  }) {
    final locName = lang.getLocalizedName(context);

    if (lang.isBuiltIn) {
      return Container(
        key: const ValueKey('builtin'),
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderColor),
          ),
          child: Text(
            context.t('settings.builtIn', null, 'Built-in'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (isDownloading) {
      return SizedBox(
        key: const ValueKey('downloading'),
        width: 48,
        height: 48,
        child: Center(
          child: Tooltip(
            message: context.t(
              'settings.downloadingTooltip',
              {'name': locName},
              'Downloading $locName model...',
            ),
            child: VocaDownloadProgressIndicator(
              size: 28,
              strokeWidth: 2.5,
              semanticsLabel: 'Downloading $locName model',
            ),
          ),
        ),
      );
    }

    if (isDownloaded) {
      return SizedBox(
        key: const ValueKey('downloaded'),
        width: 48,
        height: 48,
        child: IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: colors.textMuted,
            size: 22,
          ),
          tooltip: context.t(
            'settings.removeModelTooltip',
            {'name': locName},
            'Remove $locName model',
          ),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: onDelete,
        ),
      );
    }

    return SizedBox(
      key: const ValueKey('not_downloaded'),
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(
          Icons.cloud_download_outlined,
          color: colors.accentPrimary,
          size: 22,
        ),
        tooltip: context.t(
          'settings.downloadModelTooltip',
          {'name': locName},
          'Download $locName model (~30 MB)',
        ),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: onDownload,
      ),
    );
  }
}
