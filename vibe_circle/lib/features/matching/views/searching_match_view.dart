import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SearchingMatchView extends StatefulWidget {
  const SearchingMatchView({super.key});

  @override
  State<SearchingMatchView> createState() => _SearchingMatchViewState();
}

class _SearchingMatchViewState extends State<SearchingMatchView>
    with TickerProviderStateMixin {
  int _seconds = 0;
  String _searchState = 'searching'; // searching | expired | error
  Timer? _clock;
  Timer? _polling;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late Map<String, dynamic> _params;

  @override
  void initState() {
    super.initState();
    _params = (Get.arguments as Map<String, dynamic>?) ?? {};

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });

    // Simulate search timeout after 30s
    _polling = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _searchState = 'expired');
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _polling?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purpose = _params['purpose']?.toString() ?? '';
    final anonymous = _params['anonymous'] as bool? ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Radar animation
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: _pulseAnim.value * 1.3,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.search, size: 36, color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
              Text(
                _searchState == 'expired'
                    ? 'No relevant person is available yet'
                    : _searchState == 'error'
                        ? 'Search temporarily unavailable'
                        : 'Finding the right vibe...',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Looking for $purpose · ${anonymous ? 'Anonymous' : 'Social profile'}',
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Timer pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_seconds}s', style: AppTextStyles.buttonText),
              ),
              const SizedBox(height: 24),
              if (_searchState != 'searching') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.offAndToNamed('/searching-match', arguments: _params),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Try again', style: AppTextStyles.buttonText),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _polling?.cancel();
                    Get.back();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Cancel search', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
