class WalletDashboard {
  final int currentCoins;
  final int totalSpent;
  final int totalEarned;
  final int availableToWithdraw;
  final int purchasedCoins;
  final int bonusCoins;
  final int pendingEarnings;
  final int heldCoins;
  final List<ChartItem> chart;
  final List<DashboardHistoryItem> history;

  WalletDashboard({
    this.currentCoins = 0,
    this.totalSpent = 0,
    this.totalEarned = 0,
    this.availableToWithdraw = 0,
    this.purchasedCoins = 0,
    this.bonusCoins = 0,
    this.pendingEarnings = 0,
    this.heldCoins = 0,
    this.chart = const [],
    this.history = const [],
  });

  factory WalletDashboard.fromJson(Map<String, dynamic> json) {
    return WalletDashboard(
      currentCoins: (json['currentCoins'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      totalEarned: (json['totalEarned'] as num?)?.toInt() ?? 0,
      availableToWithdraw: (json['availableToWithdraw'] as num?)?.toInt() ?? 0,
      purchasedCoins: (json['purchasedCoins'] as num?)?.toInt() ?? 0,
      bonusCoins: (json['bonusCoins'] as num?)?.toInt() ?? 0,
      pendingEarnings: (json['pendingEarnings'] as num?)?.toInt() ?? 0,
      heldCoins: (json['heldCoins'] as num?)?.toInt() ?? 0,
      chart: (json['chart'] as List?)
              ?.map((e) => ChartItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      history: (json['history'] as List?)
              ?.map((e) => DashboardHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentCoins': currentCoins,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'availableToWithdraw': availableToWithdraw,
      'purchasedCoins': purchasedCoins,
      'bonusCoins': bonusCoins,
      'pendingEarnings': pendingEarnings,
      'heldCoins': heldCoins,
      'chart': chart.map((e) => e.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
    };
  }
}

class ChartItem {
  final String date;
  final int earned;
  final int spent;

  ChartItem({
    required this.date,
    this.earned = 0,
    this.spent = 0,
  });

  factory ChartItem.fromJson(Map<String, dynamic> json) {
    return ChartItem(
      date: json['date']?.toString() ?? '',
      earned: (json['earned'] as num?)?.toInt() ?? 0,
      spent: (json['spent'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'earned': earned,
      'spent': spent,
    };
  }
}

class DashboardHistoryItem {
  final String id;
  final String kind;
  final String type;
  final String title;
  final int amount;
  final String status;
  final String createdAt;
  final String currency;

  DashboardHistoryItem({
    required this.id,
    this.kind = 'coins',
    this.type = 'transaction',
    this.title = '',
    this.amount = 0,
    this.status = 'completed',
    this.createdAt = '',
    this.currency = '',
  });

  factory DashboardHistoryItem.fromJson(Map<String, dynamic> json) {
    return DashboardHistoryItem(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'coins',
      type: json['type']?.toString() ?? 'transaction',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'completed',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'type': type,
      'title': title,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'currency': currency,
    };
  }
}
