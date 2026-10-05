// lib/ui/auth/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/voca_theme.dart';
import '../../services/auth_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../widgets/kikyou_logo.dart';

const String _googleSvg = '''
<svg viewBox="0 0 24 24" width="20" height="20">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
</svg>
''';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _showPassword = false;
  bool _magicLinkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  AuthService? get _auth {
    try {
      return AppState.instance.authService;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = _auth;
    if (auth == null) return;
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      ToastService.success(context, context.t('auth.welcomeBack', null, 'Welcome back!'));
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleAppleSignIn() async {
    final auth = _auth;
    if (auth == null) return;
    final success = await auth.signInWithApple();
    if (success && mounted) {
      ToastService.success(context, context.t('auth.welcomeBack', null, 'Welcome back!'));
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleEmailSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = _auth;
    if (auth == null) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success;
    if (_isSignUp) {
      final name = _nameController.text.trim();
      success = await auth.signUpWithEmail(email, password, name: name);
      if (success && mounted) {
        ToastService.success(context, context.t('auth.accountCreated', null, 'Account created successfully!'));
        Navigator.of(context).pop(true);
      }
    } else {
      success = await auth.signInWithEmail(email, password);
      if (success && mounted) {
        ToastService.success(context, context.t('auth.welcomeBack', null, 'Welcome back!'));
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleSendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ToastService.warning(context, context.t('auth.enterValidEmail', null, 'Please enter a valid email address first.'));
      return;
    }

    final auth = _auth;
    if (auth == null) return;

    final success = await auth.sendMagicLink(email);
    if (success && mounted) {
      setState(() => _magicLinkSent = true);
      ToastService.info(context, context.t('auth.magicLinkSent', null, 'Magic link sent! Check your email inbox.'));
    }
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VocaColorPalette colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.accentPrimarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.accentPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final auth = _auth;

    final isLoggingIn = auth?.isLoggingIn.value ?? false;
    final authError = auth?.authError.value;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
          tooltip: context.t('common.close', null, 'Close'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Kikyou Flower Emblem & Brand Header
                  Hero(
                    tag: 'voca_kikyou_logo',
                    child: KikyouLogo(size: 60, color: colors.accentPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VOCA',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('auth.subtitle', null, 'Learn languages through authentic videos'),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Value Propositions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildBenefitRow(
                          icon: Icons.cloud_sync_rounded,
                          title: 'Seamless Cloud Sync',
                          subtitle: 'Access saved words & playlists across all your devices',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        _buildBenefitRow(
                          icon: Icons.local_fire_department_rounded,
                          title: 'Streak & Progress Guard',
                          subtitle: 'Keep your immersion streak and review milestones safe',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        _buildBenefitRow(
                          icon: Icons.leaderboard_outlined,
                          title: 'Global Learner Ranks',
                          subtitle: 'Climb leaderboards and track authentic immersion minutes',
                          colors: colors,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Error Feedback Card
                  if (authError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: colors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authError,
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 3. Social OAuth Buttons
                  // Continue with Google
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: isLoggingIn ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.bgCard,
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.string(_googleSvg),
                          const SizedBox(width: 12),
                          Text(
                            context.t('auth.continueGoogle', null, 'Continue with Google'),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sign in with Apple
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: isLoggingIn ? null : _handleAppleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.bgCard,
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple_rounded, size: 22, color: colors.textPrimary),
                          const SizedBox(width: 10),
                          Text(
                            context.t('auth.continueApple', null, 'Sign in with Apple'),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. "Or continue with email" Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.borderColorLight, height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          context.t('auth.orEmail', null, 'Or continue with email'),
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colors.borderColorLight, height: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 5. Form (Email & Password)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: colors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: context.t('auth.nameLabel', null, 'Full Name'),
                              labelStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                              prefixIcon: Icon(Icons.person_outline_rounded, color: colors.textMuted, size: 20),
                              filled: true,
                              fillColor: colors.bgSurface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colors.borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colors.borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return context.t('auth.emailRequired', null, 'Please enter your email');
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return context.t('auth.emailInvalid', null, 'Please enter a valid email');
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: context.t('auth.emailLabel', null, 'Email address'),
                            labelStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                            prefixIcon: Icon(Icons.mail_outline_rounded, color: colors.textMuted, size: 20),
                            filled: true,
                            fillColor: colors.bgSurface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return context.t('auth.passwordRequired', null, 'Please enter your password');
                            }
                            if (v.length < 6) {
                              return context.t('auth.passwordLength', null, 'Password must be at least 6 characters');
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: context.t('auth.passwordLabel', null, 'Password'),
                            labelStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: colors.textMuted, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: colors.textMuted,
                                size: 19,
                              ),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                            filled: true,
                            fillColor: colors.bgSurface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoggingIn ? null : _handleEmailSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.accentPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoggingIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isSignUp
                                        ? context.t('auth.createAccount', null, 'Create Account')
                                        : context.t('auth.signIn', null, 'Sign In'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Toggle Sign In / Create Account
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? context.t('auth.alreadyHaveAccount', null, 'Already have an account? ')
                            : context.t('auth.dontHaveAccount', null, "Don't have an account? "),
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            auth?.authError.value = null;
                          });
                        },
                        child: Text(
                          _isSignUp
                              ? context.t('auth.signIn', null, 'Sign In')
                              : context.t('auth.createAccount', null, 'Sign Up'),
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Magic Link option
                  TextButton(
                    onPressed: isLoggingIn ? null : _handleSendMagicLink,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      _magicLinkSent
                          ? context.t('auth.magicLinkResend', null, 'Resend Magic Link')
                          : context.t('auth.magicLink', null, 'Email me a sign-in link (Passwordless)'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Continue as Guest (so learner is never blocked)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                    ),
                    child: Text(
                      context.t('auth.continueAsGuest', null, 'Continue as Guest'),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.textSecondary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
