import 'package:check_bird/models/user_profile.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/services/profile_controller.dart';
import 'package:check_bird/services/rewards_service.dart';
import 'package:flutter/material.dart';

class InventoryTab extends StatefulWidget {
  final UserProfile? userProfile;
  final VoidCallback onRefresh;

  const InventoryTab({
    super.key,
    required this.userProfile,
    required this.onRefresh,
  });

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  final _profileController = ProfileController();
  final _rewardsService = RewardsService();

  Future<void> _selectFrame(String frameId) async {
    if (Authentication.user == null) return;

    try {
      await _profileController.selectFrame(Authentication.user!.uid, frameId);
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting frame: $e')),
      );
    }
  }

  Future<void> _selectBackground(String backgroundId) async {
    if (Authentication.user == null) return;

    try {
      await _profileController.selectBackground(
          Authentication.user!.uid, backgroundId);
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting background: $e')),
      );
    }
  }

  Future<void> _purchaseFrame(ProfileFrame frame) async {
    if (Authentication.user == null) return;

    final rewards =
        await _rewardsService.getUserRewards(Authentication.user!.uid);
    if (rewards.coins < frame.price) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
      return;
    }

    try {
      final success = await _rewardsService.spendCoins(
        userId: Authentication.user!.uid,
        amount: frame.price,
      );

      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed')),
        );
        return;
      }

      await _profileController.purchaseItem(
        Authentication.user!.uid,
        frame.id,
        'frame',
      );
      widget.onRefresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased ${frame.name}!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error purchasing: $e')),
      );
    }
  }

  Future<void> _purchaseBackground(ProfileBackground background) async {
    if (Authentication.user == null) return;

    final rewards =
        await _rewardsService.getUserRewards(Authentication.user!.uid);
    if (rewards.coins < background.price) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
      return;
    }

    try {
      final success = await _rewardsService.spendCoins(
        userId: Authentication.user!.uid,
        amount: background.price,
      );

      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed')),
        );
        return;
      }

      await _profileController.purchaseItem(
        Authentication.user!.uid,
        background.id,
        'background',
      );
      widget.onRefresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased ${background.name}!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error purchasing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final frames = _profileController.getAvailableFrames();
    final backgrounds = _profileController.getAvailableBackgrounds();
    final ownedFrames = widget.userProfile?.ownedFrames ?? [];
    final ownedBackgrounds = widget.userProfile?.ownedBackgrounds ?? [];
    final selectedFrame = widget.userProfile?.selectedFrameId;
    final selectedBackground = widget.userProfile?.selectedBackgroundId;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frames Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.crop_square_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avatar Frames',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Customize your profile avatar',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${ownedFrames.length}/${frames.length}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: frames.length,
              itemBuilder: (context, index) {
                final frame = frames[index];
                final isOwned = ownedFrames.contains(frame.id);
                final isSelected = selectedFrame == frame.id;

                return _buildModernItemCard(
                  context: context,
                  name: frame.name,
                  price: frame.price,
                  isOwned: isOwned,
                  isSelected: isSelected,
                  icon: Icons.crop_square_rounded,
                  onTap: () {
                    if (isOwned) {
                      _selectFrame(frame.id);
                    } else {
                      _purchaseFrame(frame);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Backgrounds Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.wallpaper_rounded,
                  color: colorScheme.onTertiaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Backgrounds',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalize your profile header',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${ownedBackgrounds.length}/${backgrounds.length}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: backgrounds.length,
              itemBuilder: (context, index) {
                final background = backgrounds[index];
                final isOwned = ownedBackgrounds.contains(background.id);
                final isSelected = selectedBackground == background.id;

                return _buildModernItemCard(
                  context: context,
                  name: background.name,
                  price: background.price,
                  isOwned: isOwned,
                  isSelected: isSelected,
                  isWide: true,
                  icon: Icons.wallpaper_rounded,
                  onTap: () {
                    if (isOwned) {
                      _selectBackground(background.id);
                    } else {
                      _purchaseBackground(background);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Complete achievements and tasks to earn coins for more items!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernItemCard({
    required BuildContext context,
    required String name,
    required int price,
    required bool isOwned,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    bool isWide = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: isWide ? 220 : 160,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        elevation: isSelected ? 8 : 2,
        shadowColor: colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 3 : 1,
              ),
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item preview
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(19),
                        topRight: Radius.circular(19),
                      ),
                      gradient: isOwned
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.surfaceContainerHigh,
                                colorScheme.surfaceContainer,
                              ],
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            icon,
                            size: 48,
                            color: isOwned
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant.withOpacity(0.3),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: colorScheme.onPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        if (!isOwned)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(19),
                                  topRight: Radius.circular(19),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Item info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (isOwned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSelected ? 'Equipped' : 'Owned',
                            style: textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              size: 18,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$price',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
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
}
