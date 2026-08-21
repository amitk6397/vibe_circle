import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../repositories/user_repository.dart';

class MyActivityView extends StatefulWidget {
  const MyActivityView({super.key});

  @override
  State<MyActivityView> createState() => _MyActivityViewState();
}

class _MyActivityViewState extends State<MyActivityView> {
  String _tab = 'posts';
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _activity;
  final UserRepository _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await _userRepo.activity();
      setState(() {
        _activity = res;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List get _items => _activity != null ? (_activity![_tab] as List? ?? []) : [];

  @override
  Widget build(BuildContext context) {
    final counts = _activity?['counts'] as Map? ?? {};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text('My activity', style: AppTextStyles.titleMedium),
      ),
      body: Column(
        children: [
          // Tab pills
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _TabPill(
                  label: 'Posts ${counts['posts'] ?? 0}',
                  selected: _tab == 'posts',
                  onTap: () => setState(() => _tab = 'posts'),
                ),
                _TabPill(
                  label: 'Comments ${counts['comments'] ?? 0}',
                  selected: _tab == 'comments',
                  onTap: () => setState(() => _tab = 'comments'),
                ),
                _TabPill(
                  label: 'Saved ${counts['saved'] ?? 0}',
                  selected: _tab == 'saved',
                  onTap: () => setState(() => _tab = 'saved'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? _ErrorState(error: _error, onRetry: _load)
                    : _items.isEmpty
                        ? _EmptyState(tab: _tab)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index] as Map;
                              return _ActivityCard(item: item, tab: _tab);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map item;
  final String tab;
  const _ActivityCard({required this.item, required this.tab});

  @override
  Widget build(BuildContext context) {
    final bodyText = item['content']?.toString() ??
        item['body']?.toString() ??
        item['text']?.toString() ??
        item['title']?.toString() ??
        'Activity';
    final postId = item['post_id']?.toString() ?? item['id']?.toString();

    return InkWell(
      onTap: postId != null
          ? () => Get.toNamed(AppRoutes.POST_DETAILS, arguments: {'postId': postId})
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tab == 'comments')
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Your comment',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
            Text(bodyText, style: AppTextStyles.body),
            const SizedBox(height: 6),
            Text(
              '${item['likes_count'] ?? item['likes'] ?? 0} likes · ${item['comments_count'] ?? item['comments'] ?? 0} comments',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Could not load activity', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(error, style: AppTextStyles.body.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String tab;
  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No activity yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text('Your $tab will appear here.', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
