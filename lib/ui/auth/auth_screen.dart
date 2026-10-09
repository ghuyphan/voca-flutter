// lib/ui/auth/auth_screen.dart

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/voca_theme.dart';
import '../../services/auth_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../widgets/kikyou_logo.dart';
import '../widgets/voca_back_button.dart';

const String _googleSvg = '''
<svg viewBox="0 0 24 24" width="20" height="20">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
</svg>
''';

final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

enum AuthScreenMode {
  landing,
  signIn,
  register,
  resetPassword,
}

enum ActiveAuthAction {
  google,
  apple,
  signIn,
  register,
  reset,
}

/// Production AuthScreen pairing the layout of ACTE with VOCA's design system:
/// - Layout Architecture (ACTE):
///     * Hero area with ambient emblem glow
///     * Bottom CTA stack (Google, Apple, Continue with email, Continue as guest)
///     * Interactive privacy consent checkbox on both landing and registration
///     * Smooth slide-up bottom sheet for email authentication (Sign In / Register / Reset)
///     * Hierarchical back button and Android PopScope navigation
/// - VOCA App Styling & Theming:
///     * Rich Obsidian (dark) & Crisp Porcelain (light) linear gradient canvas
///     * Voca Radiant Coral (`accentPrimary`) primary action CTAs and focused glows
///     * Authentic `.btn-google` elevated card styling with Google G emblem
///     * Integrated top-bar Locale & UI Language switcher pill with native option picker
///     * Reactive `Watch((context) => ...)` reactivity on `I18nService.instance.currentLanguage`
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  late final AnimationController _sheetAnimationController;
  late final Animation<double> _sheetAnimation;

  AuthScreenMode _screenMode = AuthScreenMode.landing;
  ActiveAuthAction? _activeAction;
  String? _authMessage;
  String? _successMessage;

  bool _hasAcceptedPolicyConsent = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  bool get _isApplePlatform =>
      defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  AuthService? get _auth {
    try {
      return AppState.instance.authService;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _sheetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _sheetAnimationController.dispose();
    super.dispose();
  }

  void _resetMessages() {
    setState(() {
      _authMessage = null;
      _successMessage = null;
    });
  }

  void _openForm(AuthScreenMode mode) {
    _resetMessages();
    setState(() {
      _screenMode = mode;
      if (mode == AuthScreenMode.register) {
        _hasAcceptedPolicyConsent = false;
      }
    });
    _sheetAnimationController.forward();
  }

  void _goBackInFlow() {
    _resetMessages();
    FocusScope.of(context).unfocus();
    if (_screenMode == AuthScreenMode.register || _screenMode == AuthScreenMode.resetPassword) {
      setState(() => _screenMode = AuthScreenMode.signIn);
    } else {
      _dismissForm();
    }
  }

  void _dismissForm() {
    _resetMessages();
    FocusScope.of(context).unfocus();
    _sheetAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() => _screenMode = AuthScreenMode.landing);
      }
    });
  }


  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AuthScreen] Error opening $url: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_activeAction != null) return;
    final auth = _auth;
    if (auth == null) return;

    _resetMessages();
    setState(() => _activeAction = ActiveAuthAction.google);

    try {
      final success = await auth.signInWithGoogle();
      if (!mounted) return;
      if (success) {
        ToastService.success(context, context.t('auth.welcomeBack', null, 'Welcome back!'));
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _authMessage = auth.authError.value ?? context.t('auth.signInFailed', null, 'Sign in failed. Please try again.');
        _activeAction = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authMessage = e.toString();
        _activeAction = null;
      });
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_activeAction != null) return;
    final auth = _auth;
    if (auth == null) return;

    _resetMessages();
    setState(() => _activeAction = ActiveAuthAction.apple);

    try {
      final success = await auth.signInWithApple();
      if (!mounted) return;
      if (success) {
        ToastService.success(context, context.t('auth.welcomeBack', null, 'Welcome back!'));
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _authMessage = auth.authError.value ?? context.t('auth.signInFailed', null, 'Sign in failed. Please try again.');
        _activeAction = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authMessage = e.toString();
        _activeAction = null;
      });
    }
  }

  Future<void> _handleEmailSignIn() async {
    if (_activeAction != null) return;
    final trimmedEmail = _emailController.text.trim();
    final password = _passwordController.text;

    if (trimmedEmail.isEmpty) {
      setState(() => _authMessage = context.t('auth.validationEmail', null, 'Enter your email address.'));
      return;
    }
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      setState(() => _authMessage = context.t('auth.errorInvalidEmail', null, 'Enter a valid email address.'));
      return;
    }
    if (password.isEmpty) {
      setState(() => _authMessage = context.t('auth.validationPassword', null, 'Enter your password.'));
      return;
    }

    final auth = _auth;
    if (auth == null) return;

    _resetMessages();
    setState(() => _activeAction = ActiveAuthAction.signIn);

    try {
      final success = await auth.signInWithEmail(trimmedEmail, password);
      if (!mounted) return;
      if (success) {
        ToastService.success(context, context.t('auth.welcomeBack', null, 'Welcome back!'));
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _authMessage = auth.authError.value ?? context.t('auth.signInFailed', null, 'Unable to sign in right now. Please try again.');
        _activeAction = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authMessage = e.toString();
        _activeAction = null;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_activeAction != null) return;
    final trimmedEmail = _emailController.text.trim();
    final trimmedName = _displayNameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (trimmedEmail.isEmpty) {
      setState(() => _authMessage = context.t('auth.validationEmail', null, 'Enter your email address.'));
      return;
    }
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      setState(() => _authMessage = context.t('auth.errorInvalidEmail', null, 'Enter a valid email address.'));
      return;
    }
    if (trimmedName.length > 40) {
      setState(() => _authMessage = context.t('auth.validationDisplayNameLength', null, 'Use 40 characters or fewer for your name.'));
      return;
    }
    if (password.isEmpty) {
      setState(() => _authMessage = context.t('auth.validationPassword', null, 'Enter your password.'));
      return;
    }
    if (password.length < 6) {
      setState(() => _authMessage = context.t('auth.validationPasswordLength', null, 'Use at least 6 characters for your password.'));
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _authMessage = context.t('auth.validationConfirmPassword', null, 'Confirm your password.'));
      return;
    }
    if (password != confirmPassword) {
      setState(() => _authMessage = context.t('auth.validationPasswordMatch', null, 'Your passwords do not match.'));
      return;
    }
    if (!_hasAcceptedPolicyConsent) {
      setState(() => _authMessage = context.t('auth.validationPrivacyConsent', null, 'Accept the privacy policy before creating your account.'));
      return;
    }

    final auth = _auth;
    if (auth == null) return;

    _resetMessages();
    setState(() => _activeAction = ActiveAuthAction.register);

    try {
      final success = await auth.signUpWithEmail(trimmedEmail, password, name: trimmedName);
      if (!mounted) return;
      if (success) {
        ToastService.success(context, context.t('auth.accountCreated', null, 'Account created successfully!'));
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _authMessage = auth.authError.value ?? context.t('auth.signUpFailed', null, 'Unable to create your account right now. Please try again.');
        _activeAction = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authMessage = e.toString();
        _activeAction = null;
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_activeAction != null) return;
    final trimmedEmail = _emailController.text.trim();

    if (trimmedEmail.isEmpty) {
      setState(() => _authMessage = context.t('auth.validationEmail', null, 'Enter your email address.'));
      return;
    }
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      setState(() => _authMessage = context.t('auth.errorInvalidEmail', null, 'Enter a valid email address.'));
      return;
    }

    final auth = _auth;
    if (auth == null) return;

    _resetMessages();
    setState(() => _activeAction = ActiveAuthAction.reset);

    try {
      final success = await auth.sendPasswordResetEmail(trimmedEmail);
      if (!mounted) return;
      if (success) {
        setState(() {
          _screenMode = AuthScreenMode.signIn;
          _successMessage = context.t('auth.resetPasswordSent', {'email': trimmedEmail}, 'We sent a password reset link to $trimmedEmail.');
          _activeAction = null;
        });
        return;
      }
      setState(() {
        _authMessage = auth.authError.value ?? context.t('auth.resetPasswordFailed', null, 'Unable to send a reset link right now.');
        _activeAction = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authMessage = e.toString();
        _activeAction = null;
      });
    }
  }

  void _submitForm() {
    switch (_screenMode) {
      case AuthScreenMode.signIn:
        _handleEmailSignIn();
        break;
      case AuthScreenMode.register:
        _handleRegister();
        break;
      case AuthScreenMode.resetPassword:
        _handlePasswordReset();
        break;
      case AuthScreenMode.landing:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      // Re-trigger build whenever UI language changes in I18nService
      final _ = I18nService.instance.currentLanguage.value;

      final colors = context.vocaColors;
      final isDark = colors.isDark;

      // Subtle atmospheric gradient matching VOCA canvas tokens
      final gradientColors = isDark
          ? [colors.bgPrimary, colors.bgSecondary, colors.bgTertiary]
          : [colors.bgPrimary, colors.bgSurface, colors.bgSecondary];

      return PopScope(
        canPop: _screenMode == AuthScreenMode.landing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _goBackInFlow();
          }
        },
        child: Scaffold(
          backgroundColor: colors.bgPrimary,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Stack(
              children: [
                // 1. Landing Screen Content (Center Kikyou Emblem + CTAs)
                _buildLandingContent(colors, isDark),

                // 2. Animated Modal Backdrop Scrim
                AnimatedBuilder(
                  animation: _sheetAnimation,
                  builder: (context, _) {
                    if (_sheetAnimation.value <= 0.001) {
                      return const SizedBox.shrink();
                    }
                    return Positioned.fill(
                      child: GestureDetector(
                        onTap: _dismissForm,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55 * _sheetAnimation.value),
                        ),
                      ),
                    );
                  },
                ),

                // 3. ACTE-style AppSheet Email Form Modal
                AnimatedBuilder(
                  animation: _sheetAnimation,
                  builder: (context, _) {
                    if (_sheetAnimation.value <= 0.001 && _screenMode == AuthScreenMode.landing) {
                      return const SizedBox.shrink();
                    }
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(_sheetAnimation),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildFormSheet(colors, isDark),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ===========================================================================
  // 1. LANDING CONTENT (ACTE Layout with VOCA App Styling)
  // ===========================================================================

  Widget _buildLandingContent(VocaColorPalette colors, bool isDark) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedBuilder(
            animation: _sheetAnimation,
            builder: (context, child) {
              final translateY = -28.0 * _sheetAnimation.value;
              final opacity = (1.0 - 0.12 * _sheetAnimation.value).clamp(0.0, 1.0);

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                // Top App Bar with Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: VocaBackButton(
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ),

                // Hero Emblem, Title & Subtitle (Centered vertically)
                Expanded(
                  child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ambient Coral Glow Container behind emblem
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft radial background halo
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colors.accentPrimary.withValues(alpha: isDark ? 0.22 : 0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // 104x104 App Icon Container
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: colors.bgCard,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: colors.borderColor, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: KikyouLogo(size: 60, color: colors.accentPrimary),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // VOCA Brand Title
                      Text(
                        'VOCA',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Localized Hero Subtitle
                      Text(
                        context.t('auth.subtitle', null, 'Learn languages through authentic videos'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions (ACTE Hierarchy with VOCA Styling)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Landing Error Message Slot
                  if (_authMessage != null && _screenMode == AuthScreenMode.landing) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _authMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.error,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // 1. Google Sign-In Button (.btn-google style with card elevated surface)
                  _buildSecondaryButton(
                    label: _activeAction == ActiveAuthAction.google
                        ? context.t('auth.signingIn', null, 'Signing in...')
                        : context.t('auth.continueWithGoogle', null, 'Continue with Google'),
                    leading: _activeAction == ActiveAuthAction.google
                        ? null
                        : SvgPicture.string(_googleSvg, width: 20, height: 20),
                    isLoading: _activeAction == ActiveAuthAction.google,
                    backgroundColor: colors.bgCard,
                    textColor: colors.textPrimary,
                    borderColor: colors.borderColor,
                    onPressed: _handleGoogleSignIn,
                    colors: colors,
                  ),

                  // 2. Apple Sign-In Button (for Apple platforms)
                  if (_isApplePlatform) ...[
                    const SizedBox(height: 12),
                    _buildSecondaryButton(
                      label: context.t('auth.signInApple', null, 'Sign in with Apple'),
                      leading: Icon(Icons.apple_rounded, size: 22, color: colors.textPrimary),
                      isLoading: _activeAction == ActiveAuthAction.apple,
                      backgroundColor: colors.bgCard,
                      textColor: colors.textPrimary,
                      borderColor: colors.borderColor,
                      onPressed: _handleAppleSignIn,
                      colors: colors,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 3. Continue with Email Button (Card container matching Google & Apple buttons)
                  _buildSecondaryButton(
                    label: context.t('auth.continueWithEmail', null, 'Continue with email'),
                    leading: Icon(Icons.mail_outline_rounded, size: 20, color: colors.accentPrimary),
                    backgroundColor: colors.bgCard,
                    textColor: colors.textPrimary,
                    borderColor: colors.borderColor,
                    onPressed: () => _openForm(AuthScreenMode.signIn),
                    colors: colors,
                  ),

                  const SizedBox(height: 10),

                  // 4. Continue as Guest Link Button (Min 48dp Touch Target)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _activeAction != null ? null : () => Navigator.of(context).pop(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(
                        context.t('auth.continueLocal', null, 'Continue as Guest'),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 5. Legal Terms & Privacy Consent Row
                  _buildLegalConsentRow(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  // ===========================================================================
  // 2. FORM BOTTOM SHEET (ACTE Flow with VOCA Design System)
  // ===========================================================================

  Widget _buildFormSheet(VocaColorPalette colors, bool isDark) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;

    String formTitle;
    String formDescription;
    String submitButtonLabel;

    switch (_screenMode) {
      case AuthScreenMode.register:
        formTitle = context.t('auth.registerTitle', null, 'Create your account');
        formDescription = context.t('auth.registerDescription', null, 'Save your vocabulary, keep them backed up, and sync everywhere.');
        submitButtonLabel = context.t('auth.createAccount', null, 'Create account');
        break;
      case AuthScreenMode.resetPassword:
        formTitle = context.t('auth.resetTitle', null, 'Reset your password');
        formDescription = context.t('auth.resetDescription', null, 'Enter your email and we will send you a password reset link.');
        submitButtonLabel = context.t('auth.sendResetLink', null, 'Send reset link');
        break;
      case AuthScreenMode.signIn:
      case AuthScreenMode.landing:
        formTitle = context.t('auth.emailTitle', null, 'Continue with email');
        formDescription = context.t('auth.emailDescription', null, 'Sign in to keep your vocabulary backed up and synced automatically.');
        submitButtonLabel = context.t('auth.signIn', null, 'Sign In');
        break;
    }

    final isFormSubmitting = _activeAction == ActiveAuthAction.signIn ||
        _activeAction == ActiveAuthAction.register ||
        _activeAction == ActiveAuthAction.reset;

    return Container(
      constraints: BoxConstraints(maxWidth: 560, maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: colors.borderColor, width: 1.0),
              left: BorderSide(color: colors.borderColor, width: 1.0),
              right: BorderSide(color: colors.borderColor, width: 1.0),
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
                  _dismissForm();
                }
              },
              child: Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: colors.borderColorHover,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 8, 20, viewInsets.bottom + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Form Header (Circular Back Button + Title + Description)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSheetBackButton(colors),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formTitle,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formDescription,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Inline Success Banner
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: colors.success, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Inline Error Banner
                    if (_authMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _authMessage!,
                                style: TextStyle(
                                  color: colors.error,
                                  fontSize: 13.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Form Fields with Smooth Layout Transitions
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Display Name (Register only)
                          if (_screenMode == AuthScreenMode.register) ...[
                            _buildAuthField(
                              controller: _displayNameController,
                              focusNode: _nameFocusNode,
                              label: context.t('auth.displayNameLabel', null, 'Name (optional)'),
                              placeholder: context.t('auth.displayNamePlaceholder', null, 'How should we call you?'),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              colors: colors,
                              onSubmitted: () => _emailFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email Field (All Modes)
                          _buildAuthField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            label: context.t('auth.emailLabel', null, 'Email'),
                            placeholder: context.t('auth.emailPlaceholder', null, 'you@example.com'),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: _screenMode == AuthScreenMode.resetPassword
                                ? TextInputAction.done
                                : TextInputAction.next,
                            colors: colors,
                            onSubmitted: () {
                              if (_screenMode == AuthScreenMode.resetPassword) {
                                _submitForm();
                              } else {
                                _passwordFocusNode.requestFocus();
                              }
                            },
                          ),

                          // Password Field (Sign In & Register)
                          if (_screenMode != AuthScreenMode.resetPassword) ...[
                            const SizedBox(height: 14),
                            _buildAuthField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              label: context.t('auth.passwordLabel', null, 'Password'),
                              placeholder: context.t('auth.passwordPlaceholder', null, 'Enter your password'),
                              obscureText: !_showPassword,
                              textInputAction: _screenMode == AuthScreenMode.register
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              colors: colors,
                              trailing: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: colors.textMuted,
                                ),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                              onSubmitted: () {
                                if (_screenMode == AuthScreenMode.register) {
                                  _confirmPasswordFocusNode.requestFocus();
                                } else {
                                  _submitForm();
                                }
                              },
                            ),
                          ],

                          // Confirm Password Field (Register only)
                          if (_screenMode == AuthScreenMode.register) ...[
                            const SizedBox(height: 14),
                            _buildAuthField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              label: context.t('auth.confirmPasswordLabel', null, 'Confirm password'),
                              placeholder: context.t('auth.confirmPasswordPlaceholder', null, 'Type your password again'),
                              obscureText: !_showConfirmPassword,
                              textInputAction: TextInputAction.done,
                              colors: colors,
                              trailing: IconButton(
                                icon: Icon(
                                  _showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: colors.textMuted,
                                ),
                                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                              ),
                              onSubmitted: _submitForm,
                            ),

                            const SizedBox(height: 14),

                            // Register Privacy Policy Consent Card (VOCA Styling)
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() => _hasAcceptedPolicyConsent = !_hasAcceptedPolicyConsent);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: colors.bgSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: colors.borderColor),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildCheckbox(
                                      checked: _hasAcceptedPolicyConsent,
                                      colors: colors,
                                      onChanged: (val) {
                                        setState(() => _hasAcceptedPolicyConsent = val ?? false);
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: context.t('auth.privacyConsentPrefix', null, 'I agree to the '),
                                          style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                                          children: [
                                            WidgetSpan(
                                              alignment: PlaceholderAlignment.baseline,
                                              baseline: TextBaseline.alphabetic,
                                              child: GestureDetector(
                                                onTap: () => _openLegalUrl('https://voca.study/privacy'),
                                                child: Text(
                                                  context.t('settings.privacyPolicy', null, 'Privacy Policy'),
                                                  style: TextStyle(
                                                    color: colors.accentPrimary,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const TextSpan(text: '.'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Forgot Password Link (Sign In only - Min 48dp Touch Target)
                          if (_screenMode == AuthScreenMode.signIn) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _openForm(AuthScreenMode.resetPassword),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(48, 48),
                                ),
                                child: Text(
                                  context.t('auth.forgotPassword', null, 'Forgot password?'),
                                  style: TextStyle(
                                    color: colors.accentPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Primary Form Submit Button (VOCA Radiant Coral Signature CTA)
                    _buildPrimaryActionButton(
                      label: submitButtonLabel,
                      isLoading: isFormSubmitting,
                      colors: colors,
                      onPressed: _submitForm,
                    ),

                    const SizedBox(height: 14),

                    // Mode Switch Links (Sign In <-> Register <-> Reset Password)
                    if (_screenMode == AuthScreenMode.register) ...[
                      _buildSwitchModeLink(
                        prefix: context.t('auth.alreadyHaveAccountPrefix', null, 'Already have an account? '),
                        action: context.t('auth.signInAction', null, 'Sign in'),
                        colors: colors,
                        onTap: () => _openForm(AuthScreenMode.signIn),
                      ),
                    ] else if (_screenMode == AuthScreenMode.resetPassword) ...[
                      _buildSwitchModeLink(
                        prefix: '',
                        action: context.t('auth.backToSignIn', null, 'Back to sign in'),
                        colors: colors,
                        onTap: () => _openForm(AuthScreenMode.signIn),
                      ),
                    ] else ...[
                      _buildSwitchModeLink(
                        prefix: context.t('auth.needAccountPrefix', null, 'Need an account? '),
                        action: context.t('auth.createOneAction', null, 'Create one'),
                        colors: colors,
                        onTap: () => _openForm(AuthScreenMode.register),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Bottom Legal Links (Privacy Policy & Support - min 48dp target)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: GestureDetector(
                            onTap: () => _openLegalUrl('https://voca.study/privacy'),
                            child: Text(
                              context.t('settings.privacyPolicy', null, 'Privacy Policy'),
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '  •  ',
                          style: TextStyle(color: colors.borderColorHover, fontSize: 12),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: GestureDetector(
                            onTap: () => _openLegalUrl('https://voca.study/terms'),
                            child: Text(
                              context.t('settings.support', null, 'Terms & Support'),
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ATOMIC REUSABLE WIDGETS (VOCA Design Tokens & Button Hierarchy)
  // ===========================================================================

  Widget _buildSheetBackButton(VocaColorPalette colors) {
    return VocaBackButton(
      onPressed: _goBackInFlow,
    );
  }

  /// VOCA Signature Primary CTA Button (Material 3 FilledButton with WCAG AA compliant contrast)
  Widget _buildPrimaryActionButton({
    required String label,
    required VoidCallback onPressed,
    required VocaColorPalette colors,
    bool isLoading = false,
  }) {
    const foregroundColor = Colors.white;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: colors.accentPrimary.withValues(alpha: 0.55),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  /// VOCA M3 Outlined Secondary Button (Used for Google, Apple, and Email landing cards)
  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
    required VocaColorPalette colors,
    Widget? leading,
    bool isLoading = false,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.55),
          disabledForegroundColor: textColor.withValues(alpha: 0.55),
          side: borderColor != null ? BorderSide(color: borderColor, width: 1.2) : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading,
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAuthField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String placeholder,
    required VocaColorPalette colors,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? trailing,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onSubmitted: (_) => onSubmitted?.call(),
          cursorColor: colors.accentPrimary,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: colors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: colors.bgSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
            ),
            suffixIcon: trailing,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool checked,
    required VocaColorPalette colors,
    required ValueChanged<bool?> onChanged,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: checked,
        onChanged: onChanged,
        activeColor: colors.accentPrimary,
        checkColor: Colors.white,
        side: BorderSide(
          color: checked ? colors.accentPrimary : colors.borderColorHover,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSwitchModeLink({
    required String prefix,
    required String action,
    required VocaColorPalette colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text.rich(
          TextSpan(
            text: prefix,
            style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
            children: [
              TextSpan(
                text: action,
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLegalConsentRow(VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text.rich(
        TextSpan(
          text: context.t('auth.landingPolicyConsentPrefix', null, 'By continuing, you agree to our '),
          style: TextStyle(
            color: colors.textSecondary.withValues(alpha: 0.85),
            fontSize: 12.5,
            height: 1.35,
          ),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => _openLegalUrl('https://voca.study/privacy'),
                child: Text(
                  context.t('settings.privacyPolicy', null, 'Privacy Policy'),
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            TextSpan(
              text: context.t('auth.landingPolicyConsentJoiner', null, ' and '),
              style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.85), fontSize: 12.5),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => _openLegalUrl('https://voca.study/terms'),
                child: Text(
                  context.t('settings.terms', null, 'Terms of Service'),
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
