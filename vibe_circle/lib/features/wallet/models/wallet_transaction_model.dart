class WalletTransaction {
  final String id;
  final String transactionType;
  final int amount;
  final String status;
  final String createdAt;
  final String paymentMethod;
  final String? description;
  final String? referenceId;

  WalletTransaction({
    required this.id,
    this.transactionType = 'transaction',
    this.amount = 0,
    this.status = 'completed',
    this.createdAt = '',
    this.paymentMethod = 'wallet coins',
    this.description,
    this.referenceId,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ??
          json['type']?.toString() ??
          'transaction',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'completed',
      createdAt: json['created_at']?.toString() ??
          json['createdAt']?.toString() ??
          '',
      paymentMethod: json['payment_method']?.toString() ??
          json['paymentMethod']?.toString() ??
          'wallet coins',
      description: json['description']?.toString(),
      referenceId: json['reference_id']?.toString() ??
          json['referenceId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_type': transactionType,
      'amount': amount,
      'status': status,
      'created_at': createdAt,
      'payment_method': paymentMethod,
      'description': description,
      'reference_id': referenceId,
    };
  }
}
