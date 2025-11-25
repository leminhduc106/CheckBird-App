/// Base class for all shop items (frames, backgrounds, titles, charity packs)
abstract class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final ShopCurrencyType currencyType;
  final String? imagePath;
  final ShopCategory category;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currencyType,
    required this.category,
    this.imagePath,
  });
}

enum ShopCurrencyType {
  coins,
  gems,
}

enum ShopCategory {
  frames,
  backgrounds,
  titles,
  charityPacks,
}

/// Profile frame item
class FrameItem extends ShopItem {
  const FrameItem({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.currencyType = ShopCurrencyType.coins,
    super.imagePath,
  }) : super(category: ShopCategory.frames);
}

/// Profile background item
class BackgroundItem extends ShopItem {
  const BackgroundItem({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.currencyType = ShopCurrencyType.coins,
    super.imagePath,
  }) : super(category: ShopCategory.backgrounds);
}

/// Profile title item
class TitleItem extends ShopItem {
  final int colorValue;

  const TitleItem({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required this.colorValue,
    super.currencyType = ShopCurrencyType.coins,
  }) : super(category: ShopCategory.titles, imagePath: null);
}

/// Charity pack item (special category)
class CharityPackItem extends ShopItem {
  final String charityDescription;

  const CharityPackItem({
    required super.id,
    required super.name,
    required super.description,
    required this.charityDescription,
    required super.price,
    super.imagePath,
  }) : super(
          currencyType: ShopCurrencyType.gems,
          category: ShopCategory.charityPacks,
        );
}
