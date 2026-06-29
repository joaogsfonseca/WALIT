import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<dynamic> _wallets = [];
  String? _selectedWalletId; // null = "All Wallets"
  bool _isLoadingWallets = true;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _loadWallets();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token != null) {
        final wallets = await ApiService.getWallets(token);
        if (mounted) {
          setState(() {
            _wallets = wallets;
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

  double get _totalBalance {
    // TODO: Calculate from transactions when implemented
    // For now, sum wallet balances or return 0
    return 0.0;
  }

  String get _selectedWalletName {
    if (_selectedWalletId == null) return 'All Wallets';
    final wallet = _wallets.firstWhere(
      (w) => w['id'].toString() == _selectedWalletId,
      orElse: () => null,
    );
    return wallet?['name'] ?? 'All Wallets';
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('home'),
          child: _buildHomeContent(),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('analytics'),
          child: _buildAnalyticsContent(),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey('wallets'),
          child: _buildWalletsContent(),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey('home'),
          child: _buildHomeContent(),
        );
    }
  }

  Widget _buildAnalyticsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color,

          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Analytics',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,

            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Coming soon',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,

            ),
          ),
        ],
      ),
    );
  }

  void _onFabPressed() {
    HapticFeedback.mediumImpact();
    _showActionSheet();
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildActionSheet(),
    );
  }

  Widget _buildActionSheet() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,

        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          Text(
            'Quick Actions',
            style: AppTheme.h3,
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Action Items
          _buildActionItem(
            icon: Icons.add_card_rounded,
            title: 'Create Wallet',
            subtitle: 'Start a new personal or group wallet',
            color: AppColors.gold,
            onTap: () async {
              Navigator.pop(context);
              final result = await context.push('/create-wallet');
              if (result == true) {
                _loadWallets(); // Refresh wallet count after creation
              }
            },
          ),
          _buildActionItem(
            icon: Icons.add_rounded,
            title: 'Add Transaction',
            subtitle: 'Record income or expense',
            color: AppColors.success,
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to add transaction
            },
          ),
          _buildActionItem(
            icon: Icons.person_add_rounded,
            title: 'Invite Member',
            subtitle: 'Add someone to your wallet',
            color: AppColors.info,
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to invite member
            },
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          SafeArea(
            child: SizedBox(height: AppTheme.spacingS),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,

                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,

                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.background, // Removed to allow theme transparency
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildCurrentPage(),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingS,
          ),
          child: Consumer<AuthProvider>(
            builder: (context, auth, child) {
              final user = auth.user;
              final String name = user?['name'] ?? 'User';
              final String? photoUrl = user?['profile_image_url'];
              final bool isPremium = user?['premium_active'] == true;

              return Row(
                children: [
                  // Profile Avatar - opens Profile page
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/profile');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: photoUrl == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: GoogleFonts.outfit(
                                  color: Theme.of(context).colorScheme.onSurface,

                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppTheme.spacingM),

                  // Greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hello,',
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).textTheme.bodySmall?.color,

                            fontSize: 14,
                          ),
                        ),
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,

                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Premium Badge or Upgrade Button
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldBackgroundGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                        border: Border.all(color: AppColors.goldWithOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: GoogleFonts.outfit(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // TODO: Navigate to premium upgrade
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldBackgroundGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                          border: Border.all(color: AppColors.goldWithOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.gold,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Go Premium',
                              style: GoogleFonts.outfit(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(width: AppTheme.spacingM),

                  // Notifications
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedIndex = 2);
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,

                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: Theme.of(context).colorScheme.onSurface,

                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Selector Dropdown
          _buildWalletSelector(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Total Balance
          _buildTotalBalance(),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Quick Stats
          _buildQuickStats(),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Recent Transactions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: AppTheme.h3),
              TextButton(
                onPressed: () {
                  // TODO: View all transactions
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.outfit(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Empty State for Transactions
          _buildEmptyTransactions(),
        ],
      ),
    );
  }

  Widget _buildWalletSelector() {
    return GestureDetector(
      onTap: _showWalletPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedWalletName,
            style: GoogleFonts.outfit(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.gold,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showWalletPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Wallet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,

              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            // All Wallets option
            _buildWalletOption(null, 'All Wallets'),
            if (!_isLoadingWallets)
              ..._wallets.map((wallet) => _buildWalletOption(
                wallet['id'].toString(),
                wallet['name'] ?? 'Unnamed Wallet',
              )),
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption(String? walletId, String name) {
    final isSelected = _selectedWalletId == walletId;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withAlpha(30)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(
          walletId == null ? Icons.account_balance_wallet : Icons.wallet,
          color: isSelected ? AppColors.gold : AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        name,
        style: GoogleFonts.outfit(
          color: isSelected ? AppColors.gold : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.gold)
          : null,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedWalletId = walletId;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTotalBalance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Balance',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.bodySmall?.color,

            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          '\$${_totalBalance.toStringAsFixed(2)}',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,

            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }



  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.account_balance_wallet_rounded,
          value: _isLoadingWallets ? '...' : '${_wallets.length}',
          label: 'Wallets',
          color: AppColors.gold,
        )),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(child: _buildStatCard(
          icon: Icons.receipt_long_rounded,
          value: '0',
          label: 'Transactions',
          color: AppColors.info,
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,

        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,

              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Theme.of(context).textTheme.bodySmall?.color,

              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,

        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.textHint,
              size: 32,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No transactions yet',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Create a wallet and add your first transaction',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWalletsContent() {
    if (_isLoadingWallets) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_wallets.isEmpty) {
      return _buildWalletsEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _loadWallets,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        itemCount: _wallets.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingM),
        itemBuilder: (context, index) => _buildWalletCard(_wallets[index]),
      ),
    );
  }

  Widget _buildWalletCard(dynamic wallet) {
    final String name = wallet['name'] ?? 'Unnamed Wallet';
    final String currency = wallet['currency'] ?? '';
    final String type = wallet['type'] ?? '';
    final bool isGroup = type.toUpperCase() == 'GROUP';
    final int memberCount = wallet['_count']?['members'] ?? 0;

    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?['id'];
    final bool isOwner = wallet['owner_id'] != null && wallet['owner_id'] == currentUserId;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(30),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              isGroup ? Icons.groups_rounded : Icons.account_balance_wallet_rounded,
              color: AppColors.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isGroup
                      ? 'Group · $memberCount ${memberCount == 1 ? 'member' : 'members'}'
                      : 'Personal',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
            child: Text(
              currency,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _buildWalletMenu(wallet, isOwner),
        ],
      ),
    );
  }

  Widget _buildWalletMenu(dynamic wallet, bool isOwner) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      onSelected: (value) {
        if (value == 'delete') {
          _confirmDeleteWallet(wallet);
        } else if (value == 'leave') {
          _confirmLeaveWallet(wallet);
        }
      },
      itemBuilder: (context) => [
        if (isOwner)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: AppTheme.spacingS),
                Text('Delete',
                    style: GoogleFonts.outfit(color: AppColors.error)),
              ],
            ),
          )
        else
          PopupMenuItem<String>(
            value: 'leave',
            child: Row(
              children: [
                const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: AppTheme.spacingS),
                Text('Leave',
                    style: GoogleFonts.outfit(color: AppColors.error)),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDeleteWallet(dynamic wallet) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final confirmed = await _showConfirmDialog(
      title: 'Delete wallet?',
      message:
          '"${wallet['name']}" and all of its data will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true || token == null) return;

    await _runWalletAction(
      () => ApiService.deleteWallet(token, wallet['id'].toString()),
      'Wallet deleted',
    );
  }

  Future<void> _confirmLeaveWallet(dynamic wallet) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final confirmed = await _showConfirmDialog(
      title: 'Leave wallet?',
      message: 'You will lose access to "${wallet['name']}".',
      confirmLabel: 'Leave',
    );
    if (confirmed != true || token == null) return;

    await _runWalletAction(
      () => ApiService.leaveWallet(token, wallet['id'].toString()),
      'Left wallet',
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title, style: AppTheme.h3),
        content: Text(message, style: AppTheme.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: GoogleFonts.outfit(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _runWalletAction(
      Future<void> Function() action, String successMessage) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      _loadWallets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  Widget _buildWalletsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,

              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.textHint,
              size: 48,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No wallets yet',
            style: AppTheme.h3,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
            child: Text(
              'Tap the + button to create your first wallet',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFAB() {
    return GestureDetector(
      onTapDown: (_) => _fabAnimationController.forward(),
      onTapUp: (_) {
        _fabAnimationController.reverse();
        _onFabPressed();
      },
      onTapCancel: () => _fabAnimationController.reverse(),
      child: ScaleTransition(
        scale: _fabScaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingXS),
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.whiteGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.whiteWithOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.black,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor, // Use theme color
        border: Border(
          top: BorderSide(color: AppColors.grey800, width: 0.5), // Consider changing border color based on theme too?
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          // backgroundColor: AppColors.background, // Handled by theme
          // selectedItemColor: AppColors.textPrimary, // Handled by theme
          // unselectedItemColor: AppColors.grey600, // Handled by theme
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_filled, size: 24),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.show_chart_rounded, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.show_chart_rounded, size: 24),
              ),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.account_balance_wallet_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.account_balance_wallet, size: 24),
              ),
              label: 'Wallets',
            ),
          ],
        ),
      ),
    );
  }
}
