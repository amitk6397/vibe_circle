import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/profile_controller.dart';

class ReferralView extends StatefulWidget {
  const ReferralView({super.key});

  @override
  State<ReferralView> createState() => _ReferralViewState();
}

class _ReferralViewState extends State<ReferralView> {
  final ProfileController _profileController = Get.find<ProfileController>();
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _profileController.loadReferralInfo();
  }

  void _copyCode() {
    final info = _profileController.referralInfo;
    final code = info['referralCode'] ?? '';
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    Get.snackbar(
      'Code Copied!',
      'Referral code $code copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  void _shareCode() {
    final info = _profileController.referralInfo;
    final code = info['referralCode'] ?? '';
    final inviteeBonus = info['inviteeBonus'] ?? 20;
    final inviteText =
        '🎉 Join me on VibeCircle! Use my referral code **$code** when signing up and get $inviteeBonus bonus coins for free! Download the app now.';
    Clipboard.setData(ClipboardData(text: inviteText));
    Get.snackbar(
      'Invitation Copied!',
      'Invitation message copied to clipboard. Share it with your friends!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Obx(() {
        if (_profileController.loading.value &&
            _profileController.referralInfo.isEmpty) {
          return AppScreen(
            header: const AppHeader(title: 'Refer & Earn'),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final info = _profileController.referralInfo;
        final code = info['referralCode'] ?? '••••••••';
        final int referrals = info['totalReferrals'] ?? 0;
        final num totalEarned = info['totalCoinsEarned'] ?? 0;
        final num perReferral = info['rewardPerReferral'] ?? 50;
        final num inviteeBonus = info['inviteeBonus'] ?? 20;

        return AppScreen(
          header: AppHeader(title: 'Refer & Earn', onBack: () => Get.back()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.0),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B5CE2), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        size: 40.0,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 12.0),
                      const Text(
                        'Invite Friends,\nEarn Coins!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        'You earn $perReferral coins for each friend who joins.\nThey get $inviteeBonus free coins too!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.0,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'YOUR REFERRAL CODE',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      MaterialButton(
                        onPressed: _copyCode,
                        color: _copied
                            ? const Color(0xFF10B981)
                            : AppColors.surfaceAlt,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _copied ? Icons.check : Icons.copy_all_outlined,
                              size: 16.0,
                              color: _copied ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              _copied ? 'Copied!' : 'Copy',
                              style: TextStyle(
                                color: _copied
                                    ? Colors.white
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                AppButton(title: 'Share with Friends', onPressed: _shareCode),
                const SizedBox(height: 22.0),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.people_outline,
                        '$referrals',
                        'Friends\nInvited',
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: _buildStatCard(
                        Icons.monetization_on_outlined,
                        '+$totalEarned',
                        'Coins\nEarned',
                        const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: _buildStatCard(
                        Icons.star_border,
                        '$perReferral',
                        'Per\nReferral',
                        const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22.0),
                const Text('How it works', style: AppTextStyles.h2),
                const SizedBox(height: 12.0),
                _buildHowStep(
                  1,
                  '🔗',
                  'Share Your Code',
                  'Send your unique referral code to friends.',
                ),
                _buildHowStep(
                  2,
                  '👤',
                  'Friend Joins',
                  'They sign up and get a welcome coin bonus too!',
                ),
                _buildHowStep(
                  3,
                  '🪙',
                  'You Earn Coins',
                  'Coins are instantly credited to your wallet.',
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Coins are credited instantly upon your referral\'s successful signup. '
                  'Referral bonuses are subject to VibeCircle\'s fair usage policy.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.0,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16.0,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 16.0, color: color),
          ),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowStep(int num, String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12.0,
            backgroundColor: AppColors.surfaceAlt,
            child: Text(
              '$num',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(emoji, style: const TextStyle(fontSize: 18.0)),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
