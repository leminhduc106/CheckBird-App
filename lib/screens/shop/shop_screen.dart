import 'package:check_bird/models/reward/user_rewards.dart';
import 'package:check_bird/models/shop/shop_item.dart';
import 'package:check_bird/models/user_profile.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/services/profile_controller.dart';
import 'package:check_bird/services/rewards_service.dart';
import 'package:check_bird/services/shop_controller.dart';
import 'package:check_bird/widgets/focus/focus_widget.dart';
import 'package:flutter/material.dart';

class ShopScreen extends StatefulWidget {
  static const routeName = '/shop-screen';

  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShopController _shopController = ShopController();
  final RewardsService _rewardsService = RewardsService();
  final ProfileController _profileController = ProfileController();

  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (Authentication.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile =
        await _profileController.getUserProfile(Authentication.user!.uid);
    setState(() {
      _userProfile = profile;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Authentication.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop')),
        body: const Center(
          child: Text('Please sign in to access the shop'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu),
        ),
        title: const Text('Shop'),
        actions: const [
          FocusButton(),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const [
            Tab(text: 'Frames'),
            Tab(text: 'Backgrounds'),
            Tab(text: 'Titles'),
            Tab(text: 'Charity'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Currency header with real-time updates
                StreamBuilder<UserRewards>(
                  stream: _rewardsService
                      .getUserRewardsStream(Authentication.user!.uid),
                  builder: (context, snapshot) {
                    final rewards = snapshot.data ??
                        UserRewards(userId: Authentication.user!.uid);
                    return _buildCurrencyHeader(rewards);
                  },
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildShopCategory(ShopCategory.frames),
                      _buildShopCategory(ShopCategory.backgrounds),
                      _buildShopCategory(ShopCategory.titles),
                      _buildShopCategory(ShopCategory.charityPacks),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrencyHeader(UserRewards rewards) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.tertiaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.military_tech, size: 18, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Lv ${rewards.level}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Coins
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${rewards.coins}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Gems
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond, color: Colors.pink, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${rewards.gems}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCategory(ShopCategory category) {
    final items = _shopController.getItemsByCategory(category);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _ShopItemCard(
          item: items[index],
          isOwned: _isItemOwned(items[index]),
          onPurchase: () => _handlePurchase(items[index]),
        );
      },
    );
  }

  bool _isItemOwned(ShopItem item) {
    if (_userProfile == null) return false;

    switch (item.category) {
      case ShopCategory.frames:
        return _userProfile!.ownedFrames.contains(item.id);
      case ShopCategory.backgrounds:
        return _userProfile!.ownedBackgrounds.contains(item.id);
      case ShopCategory.titles:
        return _userProfile!.ownedTitles.contains(item.id);
      case ShopCategory.charityPacks:
        return false; // Can buy multiple times
    }
  }

  Future<void> _handlePurchase(ShopItem item) async {
    if (Authentication.user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${item.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            if (item is CharityPackItem) ...[
              const SizedBox(height: 12),
              Text(
                item.charityDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  item.currencyType == ShopCurrencyType.coins
                      ? Icons.monetization_on
                      : Icons.diamond,
                  color: item.currencyType == ShopCurrencyType.coins
                      ? Colors.amber
                      : Colors.pink,
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.price} ${item.currencyType == ShopCurrencyType.coins ? 'Coins' : 'Gems'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Attempt purchase
    final success = await _shopController.purchaseItem(
      userId: Authentication.user!.uid,
      item: item,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (success) {
      await _loadUserProfile(); // Reload profile
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.category == ShopCategory.charityPacks
                ? 'Thank you for your donation! 💚'
                : 'Purchased ${item.name}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase failed. Check your balance!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool isOwned;
  final VoidCallback onPurchase;

  const _ShopItemCard({
    required this.item,
    required this.isOwned,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOwned ? 0 : 2,
      child: InkWell(
        onTap: isOwned ? null : onPurchase,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon/Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isOwned
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getIconForCategory(item.category),
                    size: 32,
                    color: isOwned
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOwned ? colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price or Owned badge
              if (isOwned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OWNED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.currencyType == ShopCurrencyType.coins
                          ? [Colors.amber.shade400, Colors.amber.shade600]
                          : [Colors.pink.shade300, Colors.pink.shade500],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (item.currencyType == ShopCurrencyType.coins
                                ? Colors.amber
                                : Colors.pink)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.currencyType == ShopCurrencyType.coins
                            ? Icons.monetization_on
                            : Icons.diamond,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(ShopCategory category) {
    switch (category) {
      case ShopCategory.frames:
        return Icons.filter_frames_rounded;
      case ShopCategory.backgrounds:
        return Icons.wallpaper_rounded;
      case ShopCategory.titles:
        return Icons.workspace_premium_rounded;
      case ShopCategory.charityPacks:
        return Icons.volunteer_activism_rounded;
    }
  }
}
