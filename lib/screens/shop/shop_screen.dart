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
          FocusButton(),
        ],
      ),
      body: FutureBuilder(
        future: rewards.load(),
        builder: (context, snapshot) {
          final coins = rewards.coins;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Coins: $coins',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    _ShopItemTile(
                      title: 'Pastel theme pack',
                      priceCoins: 20,
                      description: 'Soft colors for a calmer task view.',
                    ),
                    SizedBox(height: 8),
                    _ShopItemTile(
                      title: 'Confetti completion',
                      priceCoins: 15,
                      description:
                          'Fun confetti animation when you finish tasks.',
                    ),
                    SizedBox(height: 8),
                    _ShopItemTile(
                      title: 'Focus timer skin',
                      priceCoins: 10,
                      description: 'A new look for your focus sessions.',
                    ),
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

class _ShopItemTile extends StatelessWidget {
  const _ShopItemTile({
    required this.title,
    required this.priceCoins,
    required this.description,
  });

  final String title;
  final int priceCoins;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 16),
                const SizedBox(width: 4),
                Text('$priceCoins'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Coming soon',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
