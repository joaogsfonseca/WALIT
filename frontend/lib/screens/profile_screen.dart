import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _walletCount = 0;
  bool _isLoadingWallets = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();
      _loadWalletCount();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token != null) {
        final wallets = await ApiService.getWallets(token);
        if (mounted) {
          setState(() {
            _walletCount = wallets.length;
            _isLoadingWallets = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallets = false;
        });
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    HapticFeedback.mediumImpact();
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Logout',
          style: AppTheme.h3,
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.outfit(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final bool isPremium = user?['premium_active'] ?? false;

    return Scaffold(
      // backgroundColor: AppColors.background, // Removed to allow theme transparency
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          // Upgrade button
          if (!isPremium)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to upgrade
              },
              child: Container(
                margin: const EdgeInsets.only(right: AppTheme.spacingM),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.diamond_outlined,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Upgrade',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,

                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // Profile Avatar & Name
                    _buildProfileHeader(user),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Two Cards Row (Premium & Referrals)
                    _buildCardsRow(user),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Menu Items
                    _buildMenuSection(),

                    const SizedBox(height: AppTheme.spacingL),
                    
                    // Security Section
                    _buildSecuritySection(),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Logout Button
                    _buildLogoutButton(),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Version Info
                    _buildVersionInfo(),
                    
                    const SizedBox(height: AppTheme.spacingXL),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardsRow(Map<String, dynamic> user) {
    return Row(
      children: [
        // Active Wallets Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Navigate to wallets
            },
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: Theme.of(context).textTheme.bodySmall?.color,

                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    _isLoadingWallets ? '...' : '$_walletCount',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,

                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Active Wallets',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,

                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: AppTheme.spacingM),
        
        // Active Subscriptions Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Navigate to subscriptions
            },
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.subscriptions_outlined,
                      size: 20,
                      color: Theme.of(context).textTheme.bodySmall?.color,

                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    '0',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,

                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Active Subscriptions',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,

                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildProfileHeader(Map<String, dynamic> user) {
    final String name = user['name'] ?? 'No Name';
    final String email = user['email'] ?? 'No Email';
    final String? photoUrl = user['profile_image_url'];

    return Column(
      children: [
        // Avatar
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey800, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackWithOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Theme.of(context).colorScheme.surface,

                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          color: Theme.of(context).colorScheme.onSurface,

                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            // Edit Avatar Button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  // TODO: Edit profile photo
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingL),

        // Name
        Text(
          name,
          style: AppTheme.h2,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppTheme.spacingXS),

        // Email
        Text(
          email,
          style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }







  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) {
        return SafeArea(
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Select Theme',
                        style: AppTheme.h3,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildThemeOption(
                        context, 
                        title: 'Light', 
                        theme: AppThemeType.light, 
                        currentTheme: themeProvider.currentTheme,
                        icon: Icons.wb_sunny_rounded,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildThemeOption(
                        context,
                        title: 'Dark (Default)',
                        theme: AppThemeType.dark,
                        currentTheme: themeProvider.currentTheme,
                        icon: Icons.nightlight_round,
                        color: Colors.purple.shade200,
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required AppThemeType theme,
    required AppThemeType currentTheme,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = theme == currentTheme;
    return GestureDetector(
      onTap: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        Provider.of<ThemeProvider>(context, listen: false).setTheme(
          theme,
          token: authProvider.token,
        );
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withAlpha(25)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          _buildSimpleMenuItem(
            icon: Icons.palette_outlined, // Theme Icon
            title: 'App Theme',
            onTap: () {
              HapticFeedback.lightImpact();
              _showThemeSelector();
            },
          ),
          _buildDivider(),
          _buildSimpleMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Help',
            onTap: () => HapticFeedback.lightImpact(),
          ),
          _buildDivider(),
          _buildSimpleMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Account',
            onTap: () => HapticFeedback.lightImpact(),
          ),
          _buildDivider(),
          _buildSimpleMenuItem(
            icon: Icons.description_outlined,
            title: 'Documents & statements',
            onTap: () => HapticFeedback.lightImpact(),
          ),
          _buildDivider(),
          _buildSimpleMenuItem(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Learn',
            onTap: () => HapticFeedback.lightImpact(),
          ),
          _buildDivider(),
          _buildSimpleMenuItem(
            icon: Icons.inbox_rounded,
            title: 'Inbox',
            badge: 4, // TODO: Get from API
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          _buildSimpleMenuItem(
            icon: Icons.security_rounded,
            title: 'Security',
            onTap: () => HapticFeedback.lightImpact(),
          ),
          _buildDivider(),
          _buildSimpleMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notification settings',
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.grey800,
      indent: 56,
    );
  }

  Widget _buildSimpleMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badge',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Logout',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Column(
      children: [
        Text(
          'WALIT',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          'Version 1.0.0',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}
