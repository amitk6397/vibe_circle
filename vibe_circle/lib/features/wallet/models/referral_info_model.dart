class ReferralInfo {
  final String referralCode;
  final int rewardPerReferral;
  final int inviteeBonus;
  final int totalReferrals;
  final int totalEarned;

  ReferralInfo({
    this.referralCode = '',
    this.rewardPerReferral = 50,
    this.inviteeBonus = 20,
    this.totalReferrals = 0,
    this.totalEarned = 0,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      referralCode: json['referralCode']?.toString() ??
          json['referral_code']?.toString() ??
          '',
      rewardPerReferral: (json['rewardPerReferral'] as num?)?.toInt() ??
          (json['reward_per_referral'] as num?)?.toInt() ??
          50,
      inviteeBonus: (json['inviteeBonus'] as num?)?.toInt() ??
          (json['invitee_bonus'] as num?)?.toInt() ??
          20,
      totalReferrals: (json['totalReferrals'] as num?)?.toInt() ??
          (json['total_referrals'] as num?)?.toInt() ??
          0,
      totalEarned: (json['totalEarned'] as num?)?.toInt() ??
          (json['total_earned'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referralCode': referralCode,
      'rewardPerReferral': rewardPerReferral,
      'inviteeBonus': inviteeBonus,
      'totalReferrals': totalReferrals,
      'totalEarned': totalEarned,
    };
  }
}
