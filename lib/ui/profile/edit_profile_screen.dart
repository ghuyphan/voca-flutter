// lib/ui/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../widgets/circle_flag.dart';
import '../widgets/voca_back_button.dart';
import '../widgets/voca_option_picker.dart';
export '../widgets/circle_flag.dart';

/// Preset avatar representation
class AvatarPreset {
  final String id;
  final String name;
  final String assetPath;

  const AvatarPreset({
    required this.id,
    required this.name,
    required this.assetPath,
  });
}

/// The 16 canonical preset avatars from assets/avatars/
const List<AvatarPreset> kPresetAvatars = [
  AvatarPreset(id: 'wizard', name: 'Scholar Mage', assetPath: 'assets/avatars/wizard.svg'),
  AvatarPreset(id: 'shinobi', name: 'Shadow Shinobi', assetPath: 'assets/avatars/shinobi.svg'),
  AvatarPreset(id: 'knight', name: 'Guardian Knight', assetPath: 'assets/avatars/knight.svg'),
  AvatarPreset(id: 'alchemist', name: 'Vocab Alchemist', assetPath: 'assets/avatars/alchemist.svg'),
  AvatarPreset(id: 'fox', name: 'Spirit Fox', assetPath: 'assets/avatars/fox.svg'),
  AvatarPreset(id: 'owl', name: 'Wise Owl', assetPath: 'assets/avatars/owl.svg'),
  AvatarPreset(id: 'cat', name: 'Shadow Cat', assetPath: 'assets/avatars/cat.svg'),
  AvatarPreset(id: 'dog', name: 'Loyal Hound', assetPath: 'assets/avatars/dog.svg'),
  AvatarPreset(id: 'ninja', name: 'Night Ninja', assetPath: 'assets/avatars/ninja.svg'),
  AvatarPreset(id: 'panda', name: 'Zen Panda', assetPath: 'assets/avatars/panda.svg'),
  AvatarPreset(id: 'rabbit', name: 'Swift Rabbit', assetPath: 'assets/avatars/rabbit.svg'),
  AvatarPreset(id: 'robot', name: 'Mecha Android', assetPath: 'assets/avatars/robot.svg'),
  AvatarPreset(id: 'ranger', name: 'Immersion Ranger', assetPath: 'assets/avatars/ranger.svg'),
  AvatarPreset(id: 'miner', name: 'Sentence Miner', assetPath: 'assets/avatars/miner.svg'),
  AvatarPreset(id: 'bard', name: 'Minstrel Bard', assetPath: 'assets/avatars/bard.svg'),
  AvatarPreset(id: 'sovereign', name: 'Mythic Sovereign', assetPath: 'assets/avatars/sovereign.svg'),
];

/// Supported country representation for leaderboards
class CountryOption {
  final String code;
  final String name;
  final String nativeName;
  final String flagAsset;

  const CountryOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagAsset,
  });
}

/// The 17 supported countries matching assets/flags/
const List<CountryOption> kSupportedCountries = [
  CountryOption(code: 'VN', name: 'Vietnam', nativeName: 'Việt Nam', flagAsset: 'assets/flags/vn.svg'),
  CountryOption(code: 'US', name: 'United States', nativeName: 'United States', flagAsset: 'assets/flags/us.svg'),
  CountryOption(code: 'JP', name: 'Japan', nativeName: '日本', flagAsset: 'assets/flags/jp.svg'),
  CountryOption(code: 'KR', name: 'South Korea', nativeName: '대한민국', flagAsset: 'assets/flags/kr.svg'),
  CountryOption(code: 'CN', name: 'China', nativeName: '中国', flagAsset: 'assets/flags/cn.svg'),
  CountryOption(code: 'GB', name: 'United Kingdom', nativeName: 'United Kingdom', flagAsset: 'assets/flags/gb.svg'),
  CountryOption(code: 'CA', name: 'Canada', nativeName: 'Canada', flagAsset: 'assets/flags/ca.svg'),
  CountryOption(code: 'AU', name: 'Australia', nativeName: 'Australia', flagAsset: 'assets/flags/au.svg'),
  CountryOption(code: 'FR', name: 'France', nativeName: 'France', flagAsset: 'assets/flags/fr.svg'),
  CountryOption(code: 'DE', name: 'Germany', nativeName: 'Deutschland', flagAsset: 'assets/flags/de.svg'),
  CountryOption(code: 'ES', name: 'Spain', nativeName: 'España', flagAsset: 'assets/flags/es.svg'),
  CountryOption(code: 'IT', name: 'Italy', nativeName: 'Italia', flagAsset: 'assets/flags/it.svg'),
  CountryOption(code: 'BR', name: 'Brazil', nativeName: 'Brasil', flagAsset: 'assets/flags/br.svg'),
  CountryOption(code: 'RU', name: 'Russia', nativeName: 'Россия', flagAsset: 'assets/flags/ru.svg'),
  CountryOption(code: 'TH', name: 'Thailand', nativeName: 'ประเทศไทย', flagAsset: 'assets/flags/th.svg'),
  CountryOption(code: 'ID', name: 'Indonesia', nativeName: 'Indonesia', flagAsset: 'assets/flags/id.svg'),
  CountryOption(code: 'PT', name: 'Portugal', nativeName: 'Portugal', flagAsset: 'assets/flags/pt.svg'),
];

/// Helper widget to render any avatar string (SVG preset, URL, or fallback)
class VocaAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const VocaAvatarWidget({
    super.key,
    required this.avatarUrl,
    this.size = 48,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final url = avatarUrl?.trim() ?? '';

    Widget imageWidget;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => SvgPicture.asset(
          'assets/avatars/wizard.svg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      String assetPath = url;
      if (assetPath.isEmpty) {
        assetPath = 'assets/avatars/wizard.svg';
      } else if (assetPath.startsWith('/avatars/')) {
        assetPath = 'assets$assetPath';
      } else if (!assetPath.startsWith('assets/avatars/')) {
        final id = assetPath.replaceAll('.svg', '');
        assetPath = 'assets/avatars/$id.svg';
      }
      imageWidget = SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => Icon(Icons.person_rounded, size: size * 0.5, color: colors.textSecondary),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.bgSurface,
        border: border,
        boxShadow: boxShadow,
      ),
      child: ClipOval(child: imageWidget),
    );
  }
}


/// Dedicated Edit Profile screen for learners
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late String _selectedAvatar;
  late String _selectedCountry;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = AppState.instance.userProfile.value;
    dynamic user;
    try {
      user = AppState.instance.supabaseService.currentUser;
    } catch (_) {}
    final meta = user?.userMetadata;

    final initialName = profile?.name ??
        (meta?['name'] ?? meta?['full_name']) as String? ??
        (user?.email != null && user!.email!.contains('@') ? user.email!.split('@').first : '');
    final initialAvatar = profile?.avatarUrl ??
        (meta?['avatar_url'] ?? meta?['picture']) as String? ??
        'assets/avatars/wizard.svg';
    final initialCountry = profile?.country ?? 'auto';

    _nameController = TextEditingController(text: initialName);
    _selectedAvatar = initialAvatar;
    _selectedCountry = initialCountry;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  CountryOption? _getCountryInfo(String code) {
    if (code.isEmpty || code.toLowerCase() == 'auto') return null;
    return kSupportedCountries.cast<CountryOption?>().firstWhere(
      (c) => c?.code.toUpperCase() == code.toUpperCase(),
      orElse: () => null,
    );
  }

  String _getCountryDisplay(BuildContext context, String code) {
    if (code.isEmpty || code.toLowerCase() == 'auto') {
      return '${context.t('settings.countryAuto', null, 'Auto-detect')} (Global)';
    }
    final info = _getCountryInfo(code);
    if (info == null) return code.toUpperCase();
    final isVi = I18nService.instance.currentLanguage.value == 'vi';
    return isVi ? info.nativeName : info.name;
  }

  Future<void> _pickCountry() async {
    final colors = context.vocaColors;
    final isVi = I18nService.instance.currentLanguage.value == 'vi';

    final options = <OptionItem>[
      OptionItem(
        value: 'auto',
        label: context.t('settings.countryAuto', null, 'Auto-detect'),
        example: context.t('settings.countryGlobal', null, 'Worldwide leaderboard'),
        leading: Icon(Icons.public_rounded, size: 22, color: colors.accentPrimary),
      ),
      ...kSupportedCountries.map((c) => OptionItem(
            value: c.code,
            label: isVi ? c.nativeName : c.name,
            example: c.nativeName != c.name ? c.nativeName : c.code,
            leading: VocaFlagWidget(countryCode: c.code, size: 22),
          )),
    ];

    final result = await showVocaOptionPicker(
      context: context,
      title: context.t('settings.country', null, 'Country / Region'),
      selectedValue: _selectedCountry,
      options: options,
    );

    if (result != null && mounted) {
      setState(() {
        _selectedCountry = result;
      });
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ToastService.show(
        context,
        context.t('settings.displayNamePlaceholder', null, 'Please enter a display name'),
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await AppState.instance.updateUserProfile(
        name: name,
        avatarUrl: _selectedAvatar,
        country: _selectedCountry == 'auto' ? null : _selectedCountry,
      );

      if (!mounted) return;

      if (success) {
        ToastService.show(
          context,
          context.t('settings.profileUpdated', null, 'Profile updated successfully!'),
          type: ToastType.success,
        );
        Navigator.of(context).pop(true);
      } else {
        ToastService.show(
          context,
          context.t('settings.profileUpdateFailed', null, 'Failed to update profile. Saved locally.'),
          type: ToastType.info,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ToastService.show(
          context,
          'Error updating profile: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        leadingWidth: 68,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: VocaBackButton(),
          ),
        ),
        title: Text(
          context.t('settings.editProfile', null, 'Edit Profile'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accentPrimary,
                      ),
                    )
                  : Text(
                      context.t('common.save', null, 'Save'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // 1. Hero Avatar Preview with Camera Edit Badge
              _buildHeroAvatarPreview(colors),

              const SizedBox(height: 24),

              // 2. Preset Avatars Block (16 SVG Avatars)
              _buildPresetAvatarsSection(colors),

              const SizedBox(height: 28),

              // 3. Form Fields: Display Name & Country
              _buildFormFields(colors),

              const SizedBox(height: 36),

              // 4. Primary CTA Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.t('settings.saveProfile', null, 'Save Changes'),
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAvatarPreview(VocaColorPalette colors) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            VocaAvatarWidget(
              avatarUrl: _selectedAvatar,
              size: 96,
              border: Border.all(color: colors.accentPrimary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: colors.accentPrimary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accentPrimary,
                border: Border.all(color: colors.bgCard, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          context.t('settings.chooseAvatar', null, 'Choose a Companion Avatar'),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetAvatarsSection(VocaColorPalette colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.face_retouching_natural_rounded, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                context.t('settings.presetAvatars', null, 'Companion Archetypes').toUpperCase(),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kPresetAvatars.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final preset = kPresetAvatars[index];
              final isSelected = _selectedAvatar.contains(preset.id);

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedAvatar = preset.assetPath;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.bgSurface,
                            border: Border.all(
                              color: isSelected ? colors.accentPrimary : colors.borderColorLight,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colors.accentPrimary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: SvgPicture.asset(
                              preset.assetPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.accentPrimary,
                              border: Border.all(color: colors.bgCard, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preset.name.split(' ').last,
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textMuted,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(VocaColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display Name Field
        Text(
          context.t('settings.displayName', null, 'Display Name'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColor),
          ),
          child: TextField(
            controller: _nameController,
            maxLength: 40,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: context.t('settings.displayNamePlaceholder', null, 'Enter your display name'),
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
              prefixIcon: Icon(Icons.person_outline_rounded, color: colors.textMuted, size: 20),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Country / Region Field
        Text(
          context.t('settings.country', null, 'Country / Region'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCountry,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                VocaFlagWidget(countryCode: _selectedCountry, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getCountryDisplay(context, _selectedCountry),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            context.t('settings.countryHint', null, 'Appears next to your name on the global leaderboard'),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}
