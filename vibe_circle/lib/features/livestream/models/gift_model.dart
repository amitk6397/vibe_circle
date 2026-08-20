class GiftItem {
  final String id;
  final String name;
  final String icon;
  final int coinPrice;
  final String? animationUrl;

  GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    this.coinPrice = 5,
    this.animationUrl,
  });

  factory GiftItem.fromJson(Map<String, dynamic> json) {
    return GiftItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gift',
      icon: json['icon']?.toString() ?? '🎁',
      coinPrice: (json['coin_price'] as num?)?.toInt() ??
          (json['coinPrice'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          5,
      animationUrl: json['animation_url']?.toString() ?? json['animationUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'coin_price': coinPrice,
      'animation_url': animationUrl,
    };
  }
}
