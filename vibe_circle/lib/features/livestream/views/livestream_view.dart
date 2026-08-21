import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../controllers/livestream_controller.dart';

class LivestreamView extends GetView<LivestreamController> {
  const LivestreamView({super.key});

  @override
  Widget build(BuildContext context) {
    final LivestreamController c = Get.isRegistered<LivestreamController>()
        ? Get.find<LivestreamController>()
        : Get.put(LivestreamController());

    final insets = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: insets.top),
          _buildHeader(),
          _buildCategoryFilter(c),
          Expanded(child: _buildBody(c)),
          _buildEarnBanner(insets.bottom),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VIBECAM',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  'Live Streams',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 26.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          // Go Live button
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.GO_LIVE),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B5CE2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(22.0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radio, size: 18.0, color: Colors.white),
                  SizedBox(width: 6.0),
                  Text(
                    'Go Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(LivestreamController c) {
    return SizedBox(
      height: 46.0,
      child: Obx(() {
        final active = c.activeCategory.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          itemCount: c.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8.0),
          itemBuilder: (context, idx) {
            final cat = c.categories[idx];
            final isActive = active == cat;
            return GestureDetector(
              onTap: () => c.setCategory(cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.0,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBody(LivestreamController c) {
    return Obx(() {
      if (c.loading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 14.0),
              Text(
                'Finding live streams…',
                style: TextStyle(color: AppColors.muted, fontSize: 15.0),
              ),
            ],
          ),
        );
      }

      final items = c.filteredStreams;

      if (items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96.0,
                  height: 96.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.radio_outlined,
                    size: 48.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'No live streams right now',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Be the first to go live and earn coins from your audience!',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14.0,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.GO_LIVE),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 13.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF5B5CE2)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radio, size: 18.0, color: Colors.white),
                        SizedBox(width: 8.0),
                        Text(
                          'Start Streaming',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => c.loadStreams(isRefresh: true),
        color: AppColors.primary,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 80.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
            childAspectRatio: 0.62,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final stream = items[idx];
            return _StreamCard(
              stream: stream,
              onTap: () => Get.toNamed(
                AppRoutes.WATCH_STREAM,
                arguments: {
                  'streamId': stream['id'].toString(),
                  'title': stream['title'] ?? '',
                },
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEarnBanner(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.0,
        12.0,
        16.0,
        12.0 + (bottomInset > 0 ? bottomInset : 0.0),
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.card_giftcard_outlined, size: 18.0, color: Color(0xFFF59E0B)),
          SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Viewers can send you gifts. Every gift earns you real coins!',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12.0,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamCard extends StatelessWidget {
  final Map<String, dynamic> stream;
  final VoidCallback onTap;

  const _StreamCard({required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final host = stream['host'] as Map<String, dynamic>? ?? {};
    final avatarUrl = host['avatar_url'] as String?;
    final initial = ((host['name'] as String?) ?? '?')[0].toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                children: [
                  // Background
                  Positioned.fill(
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF3B3F9A), Color(0xFF7C3AED)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 40.0,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF3B3F9A), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 40.0,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),

                  // LIVE badge
                  Positioned(
                    top: 8.0,
                    left: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Viewer count badge
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye, size: 12.0, color: Colors.white),
                          const SizedBox(width: 3.0),
                          Text(
                            '${stream['current_viewers'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Footer info
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream['title'] ?? 'Live stream',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8.0,
                        backgroundColor: AppColors.primary,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(
                                initial,
                                style: const TextStyle(fontSize: 8.0, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          host['name'] ?? 'Creator',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
