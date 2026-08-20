class CoinPackage {
  final String id;
  final String name;
  final int purchasedCoins;
  final int bonusCoins;
  final String price;
  final String currency;
  final bool isPopular;
  final int discountPercentage;

  CoinPackage({
    required this.id,
    this.name = '',
    this.purchasedCoins = 0,
    this.bonusCoins = 0,
    this.price = '0.00',
    this.currency = '\$',
    this.isPopular = false,
    this.discountPercentage = 0,
  });

  int get totalCoins => purchasedCoins + bonusCoins;

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    return CoinPackage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Coin Package',
      purchasedCoins: (json['purchasedCoins'] as num?)?.toInt() ??
          (json['purchased_coins'] as num?)?.toInt() ??
          (json['coins'] as num?)?.toInt() ??
          0,
      bonusCoins: (json['bonusCoins'] as num?)?.toInt() ??
          (json['bonus_coins'] as num?)?.toInt() ??
          0,
      price: json['price']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? '\$',
      isPopular: json['isPopular'] == true || json['is_popular'] == true,
      discountPercentage: (json['discountPercentage'] as num?)?.toInt() ??
          (json['discount_percentage'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'purchasedCoins': purchasedCoins,
      'bonusCoins': bonusCoins,
      'price': price,
      'currency': currency,
      'isPopular': isPopular,
      'discountPercentage': discountPercentage,
    };
  }
}
