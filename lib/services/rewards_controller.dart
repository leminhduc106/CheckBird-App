import 'package:shared_preferences/shared_preferences.dart';

class RewardsController {
  static const _coinsKey = 'user_coins';

  RewardsController._();
  static final RewardsController _instance = RewardsController._();
  factory RewardsController() => _instance;

  int _coins = 0;
  bool _loaded = false;

  int get coins => _coins;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(_coinsKey) ?? 0;
    _loaded = true;
  }

  Future<void> addCoins(int delta) async {
    if (!_loaded) {
      await load();
    }
    _coins += delta;
    if (_coins < 0) _coins = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, _coins);
  }
}
