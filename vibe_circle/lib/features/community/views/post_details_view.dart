import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/community_controller.dart';
import '../widgets/post_card.dart';
import '../models/post.dart';
import '../../chat/widgets/chat_skeleton.dart';

class PostDetailsView extends StatefulWidget {
  const PostDetailsView({super.key});

  @override
  State<PostDetailsView> createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<PostDetailsView> {
  final CommunityController _communityController = Get.find<CommunityController>();
  final TextEditingController _commentController = TextEditingController();

  Post? _post;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  void _loadPostDetails() async {
    final Map args = Get.arguments ?? {};
    final String? postId = args['postId']?.toString();

    if (postId != null) {
      _post = _communityController.posts.firstWhereOrNull((p) => p.id == postId);
      await _communityController.loadComments(postId);
    }
  }

  void _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _post == null) return;

    setState(() => _submitting = true);
    try {
      await _communityController.addComment(_post!.id, text);
      _commentController.clear();
      Get.snackbar('Comment added', 'Your response has been posted.');
    } catch (e) {
      Get.snackbar('Could not post comment', e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_post == null) {
      return AppScreen(
        header: AppHeader(
          title: 'Post',
          onBack: () => Get.back(),
        ),
        child: const AppEmptyState(
          title: 'Post unavailable',
          text: 'It may have been removed by its author or a moderator.',
        ),
      );
    }

    return AppScreen(
      header: AppHeader(
        title: 'Discussion',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Post Card
            PostCard(post: _post!),
            const SizedBox(height: 16.0),

            const Text('Comments', style: AppTextStyles.h2),
            const SizedBox(height: 10.0),

            // Comments List
            Obx(() {
              final commentsList = _communityController.comments;
              return _communityController.loading.value
                  ? const ChatSkeleton(rows: 3)
                  : commentsList.isNotEmpty
                      ? Column(
                          children: commentsList.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.authorName,
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6.0),
                                        const Text('·', style: TextStyle(color: AppColors.muted)),
                                        const SizedBox(width: 6.0),
                                        const Text(
                                          'Recent',
                                          style: TextStyle(color: AppColors.muted, fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6.0),
                                    Text(
                                      item.text,
                                      style: const TextStyle(color: AppColors.text, fontSize: 13.0, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : const AppEmptyState(
                          title: 'No comments yet',
                          text: 'Be the first to share your opinion or advice!',
                        );
            }),
            const SizedBox(height: 16.0),

            // Reply Box Field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _commentController,
                    style: const TextStyle(color: AppColors.text, fontSize: 15.0),
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15.0),
                      fillColor: AppColors.surface,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 13.0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.0),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.0),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                AppButton(
                  title: 'Post',
                  compact: true,
                  loading: _submitting,
                  onPressed: _addComment,
                ),
              ],
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
