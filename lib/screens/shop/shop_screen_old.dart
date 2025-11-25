import 'package:check_bird/widgets/focus/focus_widget.dart';
import 'package:check_bird/services/rewards_controller.dart';
import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  static const routeName = '/shop-screen';

  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rewards = RewardsController();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(Icons.menu),
        ),
        title: const Text("Shop"),
        actions: const [
          Icon(Icons.shopping_cart_outlined),
          SizedBox(width: 12),
          FocusButton(),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder(
        future: rewards.load(),
        builder: (context, snapshot) {
          final coins = rewards.coins;
          final gems = 50;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6200EA),
                      ),
                    ),
                    const Spacer(),
                    // Coins
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$coins',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.monetization_on,
                              color: Colors.grey[700], size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Gems
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.pink[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$gems',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.diamond,
                              color: Colors.pink, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Frames Category
                    const Text(
                      'Frames',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6200EA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _ShopItemCard(
                            name: 'Challenger',
                            price: 10,
                            currencyType: 'coins',
                            imagePath: 'assets/images/frame_challenger.png',
                          ),
                          _ShopItemCard(
                            name: 'Purple',
                            price: 5,
                            currencyType: 'coins',
                            imagePath: 'assets/images/frame_purple.png',
                          ),
                          _ShopItemCard(
                            name: 'HangHieu',
                            price: 12,
                            currencyType: 'coins',
                            imagePath: 'assets/images/frame_hanghieu.png',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Backgrounds',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6200EA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _ShopItemCard(
                            name: 'Space',
                            price: 5,
                            currencyType: 'coins',
                            imagePath: 'assets/images/bg_space.png',
                            isWide: true,
                          ),
                          _ShopItemCard(
                            name: 'Wjbu',
                            price: 7,
                            currencyType: 'coins',
                            imagePath: 'assets/images/bg_wjbu.png',
                            isWide: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Charity Packs Category
                    const Text(
                      'Charity packs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6200EA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _ShopItemCard(
                            name: 'Book pack',
                            price: 5,
                            currencyType: 'gems',
                            imagePath: 'assets/images/charity_books.png',
                          ),
                          _ShopItemCard(
                            name: 'Plant a tree',
                            price: 8,
                            currencyType: 'gems',
                            imagePath: 'assets/images/charity_tree.png',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.name,
    required this.price,
    required this.currencyType,
    this.imagePath,
    this.isWide = false,
  });

  final String name;
  final int price;
  final String currencyType;
  final String? imagePath;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isWide ? 200 : 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  currencyType == 'gems'
                      ? Icons.volunteer_activism
                      : Icons.image_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Item Name
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$price',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                currencyType == 'gems' ? Icons.diamond : Icons.monetization_on,
                size: 16,
                color: currencyType == 'gems' ? Colors.pink : Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
