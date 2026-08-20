class AgoraCredentials {
  final String appId;
  final String channel;
  final String userAccount;
  final String token;
  final String expiresAt;
  final int? reservedMinutes;
  final double? pricePerMinute;
  final double? heldCoins;
  final double? chargedCoins;

  AgoraCredentials({
    required this.appId,
    required this.channel,
    required this.userAccount,
    required this.token,
    required this.expiresAt,
    this.reservedMinutes,
    this.pricePerMinute,
    this.heldCoins,
    this.chargedCoins,
  });

  factory AgoraCredentials.fromJson(Map<String, dynamic> json) {
    return AgoraCredentials(
      appId: json['appId'] as String? ?? json['app_id'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      userAccount: json['userAccount'] as String? ?? json['user_account'] as String? ?? '',
      token: json['token'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? json['expires_at'] as String? ?? '',
      reservedMinutes: json['reservedMinutes'] as int? ?? json['reserved_minutes'] as int?,
      pricePerMinute: (json['pricePerMinute'] as num? ?? json['price_per_minute'] as num?)?.toDouble(),
      heldCoins: (json['heldCoins'] as num? ?? json['held_coins'] as num?)?.toDouble(),
      chargedCoins: (json['chargedCoins'] as num? ?? json['charged_coins'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'channel': channel,
      'userAccount': userAccount,
      'token': token,
      'expiresAt': expiresAt,
      'reservedMinutes': reservedMinutes,
      'pricePerMinute': pricePerMinute,
      'heldCoins': heldCoins,
      'chargedCoins': chargedCoins,
    };
  }
}

class CallSession {
  final String id;
  final String conversationId;
  final String callerId;
  final String recipientId;
  final String callType; // 'audio' | 'video'
  final String status;   // 'ringing' | 'accepted' | 'rejected' | 'ended' | 'missed'
  final String? answeredAt;
  final String? endedAt;
  final String expiresAt;
  final int? reservedMinutes;
  final double? pricePerMinute;
  final double? heldCoins;
  final double? chargedCoins;
  final int? heldCreditMinutes;
  final int? usedCreditMinutes;
  final String? callerJoinedAt;
  final String? recipientJoinedAt;
  final String? startedAt;
  final AgoraCredentials? rtc;

  CallSession({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.recipientId,
    required this.callType,
    required this.status,
    this.answeredAt,
    this.endedAt,
    required this.expiresAt,
    this.reservedMinutes,
    this.pricePerMinute,
    this.heldCoins,
    this.chargedCoins,
    this.heldCreditMinutes,
    this.usedCreditMinutes,
    this.callerJoinedAt,
    this.recipientJoinedAt,
    this.startedAt,
    this.rtc,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      id: json['id'].toString(),
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? '').toString(),
      callerId: (json['callerId'] ?? json['caller_id'] ?? '').toString(),
      recipientId: (json['recipientId'] ?? json['recipient_id'] ?? '').toString(),
      callType: json['callType'] as String? ?? json['call_type'] as String? ?? 'audio',
      status: json['status'] as String? ?? 'ringing',
      answeredAt: json['answeredAt'] as String? ?? json['answered_at'] as String?,
      endedAt: json['endedAt'] as String? ?? json['ended_at'] as String?,
      expiresAt: json['expiresAt'] as String? ?? json['expires_at'] as String? ?? '',
      reservedMinutes: json['reservedMinutes'] as int? ?? json['reserved_minutes'] as int?,
      pricePerMinute: (json['pricePerMinute'] as num? ?? json['price_per_minute'] as num?)?.toDouble(),
      heldCoins: (json['heldCoins'] as num? ?? json['held_coins'] as num?)?.toDouble(),
      chargedCoins: (json['chargedCoins'] as num? ?? json['charged_coins'] as num?)?.toDouble(),
      heldCreditMinutes: json['heldCreditMinutes'] as int? ?? json['held_credit_minutes'] as int?,
      usedCreditMinutes: json['usedCreditMinutes'] as int? ?? json['used_credit_minutes'] as int?,
      callerJoinedAt: json['callerJoinedAt'] as String? ?? json['caller_joined_at'] as String?,
      recipientJoinedAt: json['recipientJoinedAt'] as String? ?? json['recipient_joined_at'] as String?,
      startedAt: json['startedAt'] as String? ?? json['started_at'] as String?,
      rtc: json['rtc'] != null ? AgoraCredentials.fromJson(json['rtc'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'callerId': callerId,
      'recipientId': recipientId,
      'callType': callType,
      'status': status,
      'answeredAt': answeredAt,
      'endedAt': endedAt,
      'expiresAt': expiresAt,
      'reservedMinutes': reservedMinutes,
      'pricePerMinute': pricePerMinute,
      'heldCoins': heldCoins,
      'chargedCoins': chargedCoins,
      'heldCreditMinutes': heldCreditMinutes,
      'usedCreditMinutes': usedCreditMinutes,
      'callerJoinedAt': callerJoinedAt,
      'recipientJoinedAt': recipientJoinedAt,
      'startedAt': startedAt,
      'rtc': rtc?.toJson(),
    };
  }
}
