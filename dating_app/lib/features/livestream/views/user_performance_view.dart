import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_animated_loader.dart';

class UserPerformanceView extends StatefulWidget {
  const UserPerformanceView({super.key});

  @override
  State<UserPerformanceView> createState() => _UserPerformanceViewState();
}

class _UserPerformanceViewState extends State<UserPerformanceView> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _profile;
  List _gifts = [];
  List _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _profile = {
          'name': 'Creator Name',
          'verified': true,
          'category': 'Life Coach',
          'availabilityStatus': 'Available',
          'introduction': 'I help people find clarity and purpose in life.',
          'rating': 4.8,
          'totalCompletedSessions': 142,
          'responseRate': 95,
          'topics': ['Mindfulness', 'Career', 'Relationships'],
          'chatPrice': 2,
          'chatAvailable': true,
          'audioPricePerMinute': 5,
          'audioAvailable': true,
          'videoPricePerMinute': 8,
          'videoAvailable': true,
        };
        _gifts = [];
        _reviews = [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: AppColors.bg, body: const AppAnimatedLoader());
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Get.back()),
          title: const Text('Performance', style: AppTextStyles.title),
        ),
        body: Center(child: Text(_error, style: AppTextStyles.body.copyWith(color: AppColors.danger))),
      );
    }

    final p = _profile!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Performance & rates', style: AppTextStyles.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile hero
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    child: Text(
                      (p['name'] as String).isNotEmpty ? (p['name'] as String)[0] : '?',
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('${p['name']}${p['verified'] == true ? ' ✓' : ''}', style: AppTextStyles.title),
                  Text('${p['category']} · ${p['availabilityStatus']}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['introduction'] ?? '', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Text(
                    '${(p['rating'] as num).toStringAsFixed(1)} rating · ${p['totalCompletedSessions']} sessions · ${p['responseRate']}% response',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Topics
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (p['topics'] as List).map((topic) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(topic.toString(), style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Action buttons
            _ActionButton(
              title: 'Start chat · ${p['chatPrice']} coins/min',
              disabled: p['chatAvailable'] != true,
              onPress: () => Get.toNamed('/new-message-request'),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              title: 'Audio call · ${p['audioPricePerMinute']}/min',
              disabled: p['audioAvailable'] != true,
              onPress: () {},
            ),
            const SizedBox(height: 10),
            _ActionButton(
              title: 'Video call · ${p['videoPricePerMinute']}/min',
              disabled: p['videoAvailable'] != true,
              onPress: () {},
            ),

            // Gifts
            if (_gifts.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Send a gift', style: AppTextStyles.title),
              const SizedBox(height: 10),
              ..._gifts.map((gift) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('${gift['name']} · ${gift['coin_price']} coins', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                ),
              )),
            ],

            // Reviews
            const SizedBox(height: 20),
            const Text('Recent reviews', style: AppTextStyles.title),
            const SizedBox(height: 10),
            _reviews.isEmpty
                ? const Text('No reviews yet.', style: TextStyle(color: AppColors.muted))
                : Column(
                    children: _reviews.take(5).map((review) {
                      final rating = review['overall_rating'] as int? ?? 0;
                      return _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${'★' * rating}${'☆' * (5 - rating)}', style: const TextStyle(color: Colors.amber, fontSize: 18)),
                            Text(review['review']?.toString() ?? 'No written review.', style: AppTextStyles.body),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                child: const Text('Report user', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final bool disabled;
  final VoidCallback onPress;
  const _ActionButton({required this.title, required this.disabled, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(title, style: AppTextStyles.buttonText),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
