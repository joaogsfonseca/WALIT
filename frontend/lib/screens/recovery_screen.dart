import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _animationController.reverse().then((_) {
      setState(() {
        _step = step;
      });
      _animationController.forward();
    });
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.forgotPassword(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar('Recovery code sent! Check your email.');
      _goToStep(1);
    } else if (authProvider.error != null) {
      _showErrorSnackBar(authProvider.error!);
      authProvider.clearError();
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(
      _tokenController.text.trim(),
      _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar('Password changed successfully!');
      context.go('/login');
    } else if (authProvider.error != null) {
      _showErrorSnackBar(authProvider.error!);
      authProvider.clearError();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: const BorderSide(color: AppColors.success, width: 1),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingM),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: const BorderSide(color: AppColors.error, width: 1),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingM),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      // backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () {
            if (_step == 1) {
              _goToStep(0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Indicator
                _buildStepIndicator(),

                const SizedBox(height: AppTheme.spacingXL),

                // Header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildHeader(),
                ),

                const SizedBox(height: AppTheme.spacingXXL),

                // Form Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedSwitcher(
                      duration: AppTheme.animationNormal,
                      child: _step == 0 ? _buildStep1() : _buildStep2(),
                    ),
                  ),
                ),

                // Action Button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _step == 0
                      ? PrimaryButton(
                          text: 'Send Recovery Code',
                          onPressed: _handleSendCode,
                          isLoading: authProvider.isLoading,
                        )
                      : PrimaryButton(
                          text: 'Reset Password',
                          onPressed: _handleResetPassword,
                          isLoading: authProvider.isLoading,
                        ),
                ),

                const SizedBox(height: AppTheme.spacingL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'Email'),
        _buildStepLine(),
        _buildStepDot(1, 'Reset'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final bool isActive = _step >= step;
    final bool isCurrent = _step == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: AppTheme.animationFast,
          width: isCurrent ? 40 : 32,
          height: isCurrent ? 40 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.gold : Theme.of(context).colorScheme.surface,

            border: Border.all(
              color: isActive ? AppColors.gold : AppColors.grey700,
              width: 2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.goldWithOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isActive && step < _step
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 18)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.outfit(
                      color: isActive ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: isCurrent ? 16 : 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isActive ? AppColors.textPrimary : AppColors.textHint,
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: _step > 0
            ? AppColors.goldGradient
            : null,
        color: _step > 0 ? null : AppColors.grey700,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _step == 0 ? 'Reset Password' : 'Create New Password',
          style: AppTheme.h1,
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          _step == 0
              ? 'Enter your email address and we\'ll send you a recovery code.'
              : 'Enter the code from your email and your new password.',
          style: AppTheme.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),

        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      children: [
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSendCode(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(20),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppColors.info.withAlpha(50)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  'Code sent to ${_emailController.text}',
                  style: GoogleFonts.outfit(
                    color: AppColors.info,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingL),

        CustomTextField(
          controller: _tokenController,
          label: 'Recovery Code',
          hint: 'Enter the code from your email',
          icon: Icons.key_outlined,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the recovery code';
            }
            return null;
          },
        ),

        const SizedBox(height: AppTheme.spacingM),

        CustomTextField(
          controller: _newPasswordController,
          label: 'New Password',
          hint: 'Create a new password',
          icon: Icons.lock_outline,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleResetPassword(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a new password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }
}
