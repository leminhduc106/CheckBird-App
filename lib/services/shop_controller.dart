import 'package:check_bird/models/shop/shop_item.dart';
import 'package:check_bird/models/user_profile.dart' as profile;
import 'package:check_bird/services/profile_controller.dart';
import 'package:check_bird/services/rewards_service.dart';
import 'package:flutter/material.dart';

/// Controller for shop operations - items, purchases, inventory
class ShopController {
  static final ShopController _instance = ShopController._();
  factory ShopController() => _instance;
  ShopController._();

  final RewardsService _rewardsService = RewardsService();
  final ProfileController _profileController = ProfileController();

  /// Get all available frames
  List<FrameItem> getAvailableFrames() {
    return [
      const FrameItem(
        id: 'challenger',
        name: 'Challenger',
        description: 'Show your competitive spirit',
        price: 10,
        currencyType: ShopCurrencyType.coins,
        imagePath: 'assets/images/frame_challenger.png',
      ),
      const FrameItem(
        id: 'purple',
        name: 'Purple Dream',
        description: 'Elegant purple border',
        price: 5,
        currencyType: ShopCurrencyType.coins,
        imagePath: 'assets/images/frame_purple.png',
      ),
      const FrameItem(
        id: 'hanghieu',
        name: 'Premium Gold',
        description: 'Luxurious golden frame',
        price: 15,
        currencyType: ShopCurrencyType.coins,
        imagePath: 'assets/images/frame_hanghieu.png',
      ),
      const FrameItem(
        id: 'diamond',
        name: 'Diamond Elite',
        description: 'Ultimate prestige frame',
        price: 50,
        currencyType: ShopCurrencyType.coins,
        imagePath: 'assets/images/frame_diamond.png',
      ),
    ];
  }

  /// Get all available backgrounds
  List<BackgroundItem> getAvailableBackgrounds() {
    return [
      const BackgroundItem(
        id: 'space',
        name: 'Space Explorer',
        description: 'Journey through the cosmos',
        price: 8,
        currencyType: ShopCurrencyType.coins,
        imagePath: 'assets/images/bg_space.png',
      ),
      const BackgroundItem(
        id: 'wjbu1',
        name: 'Wjbu Sunset',
        description: 'Beautiful sunset theme',
        price: 10,
        currencyType: ShopCurrencyType.coins,
        imagePath: 'assets/images/bg_wjbu.png',
      ),
      const BackgroundItem(
        id: 'wjbu2',
        name: 'Wjbu Dawn',
        description: 'Fresh morning theme',
        price: 10,
        currencyType: ShopCurrencyType.coins,
        imagePath: 'assets/images/bg_wjbu2.png',
      ),
      const BackgroundItem(
        id: 'forest',
        name: 'Forest Serenity',
        description: 'Peaceful nature background',
        price: 12,
        currencyType: ShopCurrencyType.coins,
        imagePath: 'assets/images/bg_forest.png',
      ),
    ];
  }

  /// Get all available titles
  List<TitleItem> getAvailableTitles() {
    return [
      const TitleItem(
        id: 'taskmaster',
        name: 'Task Master',
        description: 'Complete 50 tasks',
        price: 20,
        colorValue: 0xFF2196F3, // Blue
        currencyType: ShopCurrencyType.coins,
      ),
      const TitleItem(
        id: 'habitking',
        name: 'Habit King',
        description: 'Maintain a 30-day streak',
        price: 25,
        colorValue: 0xFF4CAF50, // Green
        currencyType: ShopCurrencyType.coins,
      ),
      const TitleItem(
        id: 'legendary',
        name: 'Legendary',
        description: 'Reach level 20',
        price: 100,
        colorValue: 0xFFFF9800, // Orange
        currencyType: ShopCurrencyType.coins,
      ),
    ];
  }

  /// Get all charity packs
  List<CharityPackItem> getCharityPacks() {
    return [
      const CharityPackItem(
        id: 'books_pack',
        name: 'Books for Kids',
        description: 'Support education',
        charityDescription:
            'Donate books to underprivileged children in rural areas',
        price: 10,
        imagePath: 'assets/images/charity_books.png',
      ),
      const CharityPackItem(
        id: 'tree_pack',
        name: 'Plant a Tree',
        description: 'Help the environment',
        charityDescription:
            'Plant trees to combat climate change and restore forests',
        price: 15,
        imagePath: 'assets/images/charity_tree.png',
      ),
      const CharityPackItem(
        id: 'meal_pack',
        name: 'Feed the Hungry',
        description: 'Provide meals',
        charityDescription: 'Provide nutritious meals to families in need',
        price: 20,
        imagePath: 'assets/images/charity_meal.png',
      ),
    ];
  }

  /// Purchase an item from the shop
  /// Returns true if purchase successful
  Future<bool> purchaseItem({
    required String userId,
    required ShopItem item,
  }) async {
    try {
      // Check if user owns item already
      final userProfile = await _profileController.getUserProfile(userId);
      if (userProfile != null && _isItemOwned(userProfile, item)) {
        debugPrint('User already owns item ${item.id}');
        return false;
      }

      // Spend currency
      bool paymentSuccess = false;
      if (item.currencyType == ShopCurrencyType.coins) {
        paymentSuccess = await _rewardsService.spendCoins(
          userId: userId,
          amount: item.price,
        );
      } else {
        paymentSuccess = await _rewardsService.spendGems(
          userId: userId,
          amount: item.price,
        );
      }

      if (!paymentSuccess) {
        debugPrint('Insufficient funds for purchase');
        return false;
      }

      // Add item to user's inventory
      final itemType = _getItemType(item);
      await _profileController.purchaseItem(userId, item.id, itemType);

      debugPrint('Purchase successful: ${item.name}');
      return true;
    } catch (e) {
      debugPrint('Error purchasing item: $e');
      return false;
    }
  }

  /// Check if user owns an item
  bool _isItemOwned(profile.UserProfile userProfile, ShopItem item) {
    switch (item.category) {
      case ShopCategory.frames:
        return userProfile.ownedFrames.contains(item.id);
      case ShopCategory.backgrounds:
        return userProfile.ownedBackgrounds.contains(item.id);
      case ShopCategory.titles:
        return userProfile.ownedTitles.contains(item.id);
      case ShopCategory.charityPacks:
        // Charity packs can be purchased multiple times
        return false;
    }
  }

  /// Get item type string for profile controller
  String _getItemType(ShopItem item) {
    switch (item.category) {
      case ShopCategory.frames:
        return 'frame';
      case ShopCategory.backgrounds:
        return 'background';
      case ShopCategory.titles:
        return 'title';
      case ShopCategory.charityPacks:
        return 'charity';
    }
  }

  /// Check if user can afford an item
  Future<bool> canAfford({
    required String userId,
    required ShopItem item,
  }) async {
    try {
      final rewards = await _rewardsService.getUserRewards(userId);
      if (item.currencyType == ShopCurrencyType.coins) {
        return rewards.coins >= item.price;
      } else {
        return rewards.gems >= item.price;
      }
    } catch (e) {
      debugPrint('Error checking affordability: $e');
      return false;
    }
  }

  /// Get all shop items by category
  List<ShopItem> getItemsByCategory(ShopCategory category) {
    switch (category) {
      case ShopCategory.frames:
        return getAvailableFrames();
      case ShopCategory.backgrounds:
        return getAvailableBackgrounds();
      case ShopCategory.titles:
        return getAvailableTitles();
      case ShopCategory.charityPacks:
        return getCharityPacks();
    }
  }
}
