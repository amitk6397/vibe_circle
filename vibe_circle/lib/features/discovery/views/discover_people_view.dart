import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class DiscoverPeopleView extends StatelessWidget {
  const DiscoverPeopleView({super.key});

  @override
  Widget build(BuildContext context) {
    // In real app: from discovery store/controller, filter out blocked users
    final List people = [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discover people', style: AppTextStyles.title),
            Text(
              'Purpose and interest-based suggestions',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () => Get.toNamed('/search-filters'),
          ),
        ],
      ),
      body: people.isEmpty
          ? const _EmptyState()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final person = people[index] as Map;
                  return _PersonGridCard(
                    person: person,
                    onPress: () => Get.toNamed('/public-profile', arguments: {'personId': person['id']}),
                  );
                },
              ),
            ),
    );
  }
}

class _PersonGridCard extends StatelessWidget {
  final Map person;
  final VoidCallback onPress;
  const _PersonGridCard({required this.person, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              backgroundImage: person['avatarUrl'] != null ? NetworkImage(person['avatarUrl'].toString()) : null,
              child: person['avatarUrl'] == null
                  ? Text(
                      (person['name']?.toString() ?? '?').isNotEmpty
                          ? (person['name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w900),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              person['name']?.toString() ?? '',
              style: AppTextStyles.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (person['online'] == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text('Online', style: AppTextStyles.caption.copyWith(color: Colors.green, fontSize: 10)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.muted),
            SizedBox(height: 16),
            Text('No people found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Try adjusting your filters.', style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
