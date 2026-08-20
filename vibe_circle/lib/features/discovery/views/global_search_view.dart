import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../widgets/person_card.dart';
import '../../community/widgets/community_card.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/discovery_controller.dart';
import '../../../routes/app_routes.dart';

class GlobalSearchView extends StatefulWidget {
  const GlobalSearchView({super.key});

  @override
  State<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<GlobalSearchView> {
  final DiscoveryController _discoveryController = Get.find<DiscoveryController>();
  final TextEditingController _searchController = TextEditingController();
  
  Timer? _debounce;
  String _query = '';
  String _error = '';

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {
      _query = val;
    });

    if (val.trim().length < 2) {
      _discoveryController.searchUsers.clear();
      _discoveryController.searchCommunities.clear();
      _discoveryController.searchPosts.clear();
      setState(() => _error = '');
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(val.trim());
    });
  }

  void _performSearch(String searchVal) async {
    setState(() => _error = '');
    try {
      await _discoveryController.performGlobalSearch(searchVal);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Global Search',
        subtitle: 'Find members, posts, or communities',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchField(
              value: _query,
              controller: _searchController,
              placeholder: 'Search keywords, names...',
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16.0),

            Obx(() {
              final loading = _discoveryController.loading.value;
              final users = _discoveryController.searchUsers;
              final communities = _discoveryController.searchCommunities;
              final posts = _discoveryController.searchPosts;

              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_error.isNotEmpty) {
                return Center(
                  child: Text(_error, style: const TextStyle(color: AppColors.danger)),
                );
              }

              if (_query.trim().length < 2) {
                return const AppEmptyState(
                  icon: Icons.search,
                  title: 'Start searching',
                  text: 'Type at least 2 characters to search across VibeCircle.',
                );
              }

              final bool isEmpty = users.isEmpty && communities.isEmpty && posts.isEmpty;
              if (isEmpty) {
                return const AppEmptyState(
                  icon: Icons.search_off,
                  title: 'No results found',
                  text: 'Try searching for different keywords or names.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // People section
                  if (users.isNotEmpty) ...[
                    const Text('Members', style: AppTextStyles.h2),
                    const SizedBox(height: 8.0),
                    ...users.map((person) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: PersonCard(person: person),
                        )),
                    const SizedBox(height: 16.0),
                  ],

                  // Communities section
                  if (communities.isNotEmpty) ...[
                    const Text('Communities', style: AppTextStyles.h2),
                    const SizedBox(height: 8.0),
                    ...communities.map((comm) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: CommunityCard(community: comm),
                        )),
                    const SizedBox(height: 16.0),
                  ],

                  // Posts section
                  if (posts.isNotEmpty) ...[
                    const Text('Related Posts', style: AppTextStyles.h2),
                    const SizedBox(height: 8.0),
                    ...posts.map((post) {
                      final body = post['body'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: AppCard(
                          onPressed: () => Get.toNamed(AppRoutes.POST_DETAILS, arguments: {'postId': post['id'].toString()}),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['title'] ?? 'Circle Post',
                                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14.0),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                body,
                                style: const TextStyle(color: AppColors.text, fontSize: 12.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
