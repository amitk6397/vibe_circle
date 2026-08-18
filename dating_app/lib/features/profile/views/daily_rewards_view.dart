import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';

class DailyRewardsView extends StatefulWidget {
  const DailyRewardsView({super.key});

  @override
  State<DailyRewardsView> createState() => _DailyRewardsViewState();
}

class _DailyRewardsViewState extends State<DailyRewardsView> {
  final NetworkApiService _apiService = NetworkApiService.instance;
  final AuthController _authController = Get.find<AuthController>();

  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _claiming = false;
  String _countdown = '';
  Timer? _countdownTimer;

  final List<String> _dayEmojis = ['🌱', '⭐', '💫', '🔥', '💎', '🏆', '👑'];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() async {
    setState(() => _loading = true);
    try {
      final res = await _apiService.get(ApiUrls.dailyRewardStatus);
      setState(() {
        _status = Map<String, dynamic>.from(res.data as Map);
      });
      _startCountdown();
    } catch (_) {
      // Setup mock default if fails
      setState(() {
        _status = {
          'streakDay': 3,
          'alreadyClaimedToday': false,
          'schedule': [5, 10, 15, 20, 30, 40, 50],
          'nextClaimAt': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
        };
      });
      _startCountdown();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_status?['nextClaimAt'] == null) return;

    final nextClaim = DateTime.parse(_status!['nextClaimAt'].toString());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final diff = nextClaim.difference(DateTime.now());
      if (diff.inSeconds <= 0) {
        timer.cancel();
        setState(() => _countdown = '00:00:00');
        _loadStatus();
      } else {
        final hours = diff.inHours.toString().padLeft(2, '0');
        final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
        setState(() {
          _countdown = '$hours:$mins:$secs';
        });
      }
    });
  }

  void _claimReward() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    try {
      final res = await _apiService.post(ApiUrls.claimDailyReward);
      final data = res.data;

      // Update wallet balance in global controller
      _authController.bootstrap();

      Get.defaultDialog(
        title: '🎉 Reward Claimed!',
        middleText: 'You earned ${data['coins_awarded']} coins!\nCome back tomorrow for more rewards.',
        textConfirm: 'Awesome',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () {
          Get.back();
          _loadStatus();
        },
      );
    } catch (e) {
      Get.defaultDialog(
        title: 'Claim failed',
        middleText: e.toString().contains('already')
            ? 'Come back tomorrow for your next reward.'
            : e.toString(),
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () => Get.back(),
      );
    } finally {
      setState(() => _claiming = false);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _status == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: AppScreen(
          header: const AppHeader(title: 'Daily Login Rewards'),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final int streakDay = _status?['streakDay'] ?? 0;
    final bool alreadyClaimed = _status?['alreadyClaimedToday'] ?? false;
    final List<dynamic> schedule = _status?['schedule'] ?? [5, 10, 15, 20, 30, 40, 50];
    final num todayReward = schedule[streakDay % schedule.length];
    final num nextReward = schedule[(streakDay + (alreadyClaimed ? 1 : 0)) % schedule.length];

    return AppScreen(
      header: AppHeader(
        title: 'Daily Login Rewards',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero banner containing streak fire
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.0),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT STREAK',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('🔥 ', style: TextStyle(fontSize: 26.0)),
                              Text(
                                '$streakDay',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36.0,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                ' days',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'NEXT REWARD',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '🪙 $nextReward coins',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    alreadyClaimed
                        ? "Today's reward has been claimed! 🎉"
                        : "Claim today's reward to keep your streak alive!",
                    style: const TextStyle(color: Colors.white70, fontSize: 13.0),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Claim Button
                  MaterialButton(
                    onPressed: alreadyClaimed || _claiming ? null : _claimReward,
                    color: Colors.white,
                    disabledColor: Colors.white24,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: _claiming
                        ? const SizedBox(
                            height: 18.0,
                            width: 18.0,
                            child: CircularProgressIndicator(color: Color(0xFF7C3AED), strokeWidth: 2.0),
                          )
                        : Text(
                            alreadyClaimed ? 'Reward Claimed ✓' : 'Claim $todayReward Coins Now!',
                            style: TextStyle(
                              color: alreadyClaimed ? Colors.white70 : const Color(0xFF7C3AED),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                  ),

                  // Countdown next reward timer
                  if (alreadyClaimed && _countdown.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70, size: 14.0),
                        const SizedBox(width: 6.0),
                        Text(
                          'Next reward available in $_countdown',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22.0),

            // Weekly Grid schedule section
            const Text('Weekly Reward Schedule', style: AppTextStyles.h2),
            const Text(
              'Login every day to maximize your coins!',
              style: TextStyle(color: AppColors.muted, fontSize: 12.0),
            ),
            const SizedBox(height: 12.0),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                childAspectRatio: 0.85,
              ),
              itemCount: schedule.length,
              itemBuilder: (context, index) {
                final int dayNum = index + 1;
                final bool isClaimed = alreadyClaimed ? dayNum <= streakDay : dayNum < streakDay;
                final bool isToday = alreadyClaimed
                    ? dayNum == streakDay
                    : dayNum == streakDay + 1;

                Color cardBg = AppColors.surfaceAlt;
                if (isToday && !alreadyClaimed) {
                  cardBg = AppColors.primary.withValues(alpha: 0.12);
                } else if (isClaimed) {
                  cardBg = const Color(0xFF10B981).withValues(alpha: 0.1);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isToday && !alreadyClaimed ? AppColors.primary : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isClaimed)
                        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22.0)
                      else if (isToday && !alreadyClaimed)
                        const Icon(Icons.card_giftcard, color: AppColors.primary, size: 22.0)
                      else
                        Text(
                          _dayEmojis[index % _dayEmojis.length],
                          style: const TextStyle(fontSize: 18.0),
                        ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Day $dayNum',
                        style: TextStyle(
                          color: isClaimed ? Colors.white30 : AppColors.text,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '🪙 ${schedule[index]}',
                        style: TextStyle(
                          color: isToday && !alreadyClaimed ? AppColors.primary : AppColors.muted,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20.0),

            // How it works card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('How it works', style: AppTextStyles.h2),
                  const SizedBox(height: 8.0),
                  _buildTipRow(Icons.flash_on, 'Login every day to maintain your streak'),
                  _buildTipRow(Icons.emoji_events_outlined, 'Day 7 gives maximum ${schedule.last} coins!'),
                  _buildTipRow(Icons.warning_amber_rounded, 'Missing a day resets your streak to Day 1'),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 15.0, color: AppColors.primary),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.text, fontSize: 12.0),
            ),
          ),
        ],
      ),
    );
  }
}
