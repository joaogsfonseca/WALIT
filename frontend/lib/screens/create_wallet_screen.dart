import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String? _selectedType;
  String _selectedCurrency = 'EUR';
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // For group wallet - invite emails
  final List<String> _inviteEmails = [];
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _walletTypes = [
    {
      'type': 'PERSONAL',
      'title': 'Personal Wallet',
      'subtitle': 'Track your own expenses and income',
      'icon': Icons.person_rounded,
      'color': AppColors.info,
    },
    {
      'type': 'GROUP',
      'title': 'Group Wallet',
      'subtitle': 'Share expenses with family or friends',
      'icon': Icons.people_rounded,
      'color': AppColors.success,
    },
  ];

  final List<Map<String, String>> _currencies = [
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'BRL', 'symbol': 'R\$', 'name': 'Brazilian Real'},
  ];

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
    _nameController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _animationController.reverse().then((_) {
      setState(() {
        _currentStep = step;
      });
      _animationController.forward();
    });
  }

  void _addEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email');
      return;
    }
    
    if (_inviteEmails.contains(email)) {
      _showErrorSnackBar('Email already added');
      return;
    }
    
    setState(() {
      _inviteEmails.add(email);
      _emailController.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _removeEmail(String email) {
    setState(() {
      _inviteEmails.remove(email);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      _showErrorSnackBar('Please select a wallet type');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create the wallet
      final wallet = await ApiService.createWallet(
        token,
        _nameController.text.trim(),
        _selectedType!,
        _selectedCurrency,
      );

      // If group wallet and we have emails to invite
      if (_selectedType == 'GROUP' && _inviteEmails.isNotEmpty) {
        final walletId = wallet['id'] as String;
        for (final email in _inviteEmails) {
          try {
            await ApiService.inviteUser(token, walletId, email);
          } catch (e) {
            // Continue even if some invites fail
            debugPrint('Failed to invite $email: $e');
          }
        }
      }

      if (!mounted) return;

      _showSuccessSnackBar('Wallet created successfully!');
      context.pop(true); // Return true to indicate success
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackBar(_error!);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    return Scaffold(
      backgroundColor: AppColors.background,
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
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Wallet',
          style: AppTheme.h3,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Step Indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
                child: _buildStepIndicator(),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),

              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: _buildActionButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final int totalSteps = _selectedType == 'GROUP' ? 3 : 2;
    
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: _currentStep > stepIndex
                    ? AppColors.gold
                    : AppColors.grey800,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        } else {
          // Step dot
          final stepIndex = index ~/ 2;
          final isActive = _currentStep >= stepIndex;
          final isCurrent = _currentStep == stepIndex;
          
          return AnimatedContainer(
            duration: AppTheme.animationFast,
            width: isCurrent ? 32 : 24,
            height: isCurrent ? 32 : 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.gold : AppColors.surface,
              border: Border.all(
                color: isActive ? AppColors.gold : AppColors.grey700,
                width: 2,
              ),
            ),
            child: Center(
              child: isActive && stepIndex < _currentStep
                  ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
                  : Text(
                      '${stepIndex + 1}',
                      style: GoogleFonts.outfit(
                        color: isActive ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: isCurrent ? 14 : 12,
                      ),
                    ),
            ),
          );
        }
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildTypeSelection();
      case 1:
        return _buildWalletDetails();
      case 2:
        return _buildInviteMembers();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Wallet Type', style: AppTheme.h2),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Select the type of wallet you want to create',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        
        ..._walletTypes.map((type) => _buildTypeCard(type)),
      ],
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> type) {
    final isSelected = _selectedType == type['type'];
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedType = type['type'];
        });
      },
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: isSelected
              ? (type['color'] as Color).withAlpha(20)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? type['color'] : AppColors.grey800,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: (type['color'] as Color).withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                type['icon'],
                color: type['color'],
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type['title'],
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    type['subtitle'],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AppTheme.animationFast,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? type['color'] : Colors.transparent,
                border: Border.all(
                  color: isSelected ? type['color'] : AppColors.grey600,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wallet Details', style: AppTheme.h2),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Give your wallet a name and select currency',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        
        // Wallet Name
        CustomTextField(
          controller: _nameController,
          label: 'Wallet Name',
          hint: 'e.g., Monthly Budget, Trip to Paris',
          icon: Icons.edit_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a wallet name';
            }
            if (value.length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppTheme.spacingL),
        
        // Currency Selection
        Text(
          'Currency',
          style: AppTheme.label.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: AppTheme.spacingS),
        
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: _currencies.map((currency) {
            final isSelected = _selectedCurrency == currency['code'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCurrency = currency['code']!;
                });
              },
              child: AnimatedContainer(
                duration: AppTheme.animationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold.withAlpha(20)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.grey800,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currency['symbol']!,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.gold : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      currency['code']!,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInviteMembers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite Members', style: AppTheme.h2),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Add people to share this wallet with (optional)',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        
        // Email Input
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'friend@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addEmail(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            GestureDetector(
              onTap: _addEmail,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingL),
        
        // Invited Emails List
        if (_inviteEmails.isNotEmpty) ...[
          Text(
            'Invitations (${_inviteEmails.length})',
            style: AppTheme.label.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppTheme.spacingS),
          ..._inviteEmails.map((email) => _buildEmailChip(email)),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.grey800),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.grey800,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'You can skip this step and invite members later',
                    style: AppTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmailChip(String email) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.grey800),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXS),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.info,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              email,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _removeEmail(email),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    String buttonText;
    VoidCallback? onPressed;

    switch (_currentStep) {
      case 0:
        buttonText = 'Continue';
        onPressed = _selectedType != null ? () => _goToStep(1) : null;
        break;
      case 1:
        if (_selectedType == 'GROUP') {
          buttonText = 'Continue';
          onPressed = () {
            if (_formKey.currentState!.validate()) {
              _goToStep(2);
            }
          };
        } else {
          buttonText = 'Create Wallet';
          onPressed = _createWallet;
        }
        break;
      case 2:
        buttonText = 'Create Wallet';
        onPressed = _createWallet;
        break;
      default:
        buttonText = 'Continue';
        onPressed = null;
    }

    return Column(
      children: [
        PrimaryButton(
          text: buttonText,
          onPressed: onPressed,
          isLoading: _isLoading,
        ),
        if (_currentStep > 0) ...[
          const SizedBox(height: AppTheme.spacingS),
          TextButton(
            onPressed: () => _goToStep(_currentStep - 1),
            child: Text(
              'Back',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
