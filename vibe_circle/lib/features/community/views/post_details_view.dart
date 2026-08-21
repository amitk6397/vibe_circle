import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_screen.dart';
import '../../chat/widgets/chat_skeleton.dart';
import '../controllers/community_controller.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import '../../../routes/app_routes.dart';

class PostDetailsView extends StatefulWidget {
  const PostDetailsView({super.key});

  @override
  State<PostDetailsView> createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<PostDetailsView> {
  final CommunityController _communityController = Get.find<CommunityController>();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  String? _postId;
  bool _submitting = false;
  Comment? _replyTo;
  Post? _passedPost;

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  void _loadPostDetails() async {
    final Map args = Get.arguments is Map ? Get.arguments : {};
    _postId = args['postId']?.toString();
    if (args['post'] is Post) {
      _passedPost = args['post'];
    }

    if (_postId != null) {
      await _communityController.loadComments(_postId!);
      if (mounted) setState(() {});
    }
  }

  void _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _postId == null) return;

    setState(() => _submitting = true);
    try {
      await _communityController.addComment(
        _postId!,
        text,
        parentId: _replyTo?.id,
      );
      _commentController.clear();
      setState(() => _replyTo = null);
      Get.snackbar(
        'Comment added 💬',
        'Your reply has been posted.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Could not post comment', e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showReportDialog(String postId) {
    Get.defaultDialog(
      title: 'Report Post',
      middleText: 'Choose a reason for reporting. Only relevant evidence will be shared with moderators.',
      actions: [
        ListTile(
          title: const Text('Spam or scam', style: TextStyle(color: AppColors.text)),
          onTap: () {
            Get.back();
            NetworkApiService.instance.post('/safety/reports', data: {
              'target_type': 'post',
              'target_id': postId,
              'reason': 'Spam or scam',
            });
            Get.snackbar('Report submitted', 'Thank you. Our safety team will review your report.');
          },
        ),
        ListTile(
          title: const Text('Harassment', style: TextStyle(color: AppColors.danger)),
          onTap: () {
            Get.back();
            NetworkApiService.instance.post('/safety/reports', data: {
              'target_type': 'post',
              'target_id': postId,
              'reason': 'Harassment',
            });
            Get.snackbar('Report submitted', 'Thank you. Our safety team will review your report.');
          },
        ),
      ],
    );
  }

  void _confirmDeleteComment(Comment comment, String postId) {
    Get.defaultDialog(
      title: 'Delete comment?',
      middleText: 'This comment will be permanently removed.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        try {
          await _communityController.deleteComment(comment.id, postId);
          Get.snackbar('Deleted', 'Comment was deleted.');
        } catch (e) {
          Get.snackbar('Delete failed', e.toString());
        }
      },
    );
  }

  void _confirmAwardBounty(Post post, Comment comment) {
    Get.defaultDialog(
      title: 'Award Bounty? 🏆',
      middleText: 'Do you want to award the ${post.bountyAmount.toInt()} coins bounty to ${comment.authorName}?',
      textConfirm: 'Award Bounty',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFD88712),
      onConfirm: () async {
        Get.back();
        try {
          await _communityController.awardBounty(post.id, comment.id);
          Get.snackbar('Bounty Awarded! 🏆', '${comment.authorName} has won the bounty reward.');
        } catch (e) {
          Get.snackbar('Award failed', e.toString());
        }
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Post? post = _postId != null
          ? (_communityController.posts.firstWhereOrNull((p) => p.id == _postId) ?? _passedPost)
          : null;

      if (post == null) {
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
          right: AppIconButton(
            icon: Icons.more_horiz,
            onPressed: () => _showReportDialog(post.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Post Card
              PostCard(
                post: post,
                onLikePressed: () => _communityController.toggleLike(post.id),
                onBookmarkPressed: () => _communityController.toggleSave(post.id),
                onAuthorPressed: () => Get.toNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': post.authorId}),
              ),
              const SizedBox(height: 16.0),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Comments (${_communityController.comments.length})', style: AppTextStyles.h2),
                ],
              ),
              const SizedBox(height: 10.0),

              // Comments List
              Builder(
                builder: (context) {
                  final commentsList = _communityController.comments;
                  if (_communityController.loading.value) {
                    return const ChatSkeleton(rows: 3);
                  }
                  if (commentsList.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No comments yet',
                      text: 'Be the first to share your opinion or advice!',
                    );
                  }

                  return Column(
                    children: commentsList.map((item) {
                      final bool isNested = item.parentId != null && item.parentId!.isNotEmpty;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 10.0,
                          left: isNested ? 26.0 : 0.0,
                        ),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => Get.toNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': item.authorId}),
                                    child: AppAvatar(
                                      name: item.authorName,
                                      avatarUrl: item.authorAvatar,
                                      size: 32.0,
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
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
                                                fontSize: 13.0,
                                              ),
                                            ),
                                            if (item.authorUsername != null && item.authorUsername!.isNotEmpty) ...[
                                              const SizedBox(width: 4.0),
                                              Text(
                                                '@${item.authorUsername}',
                                                style: const TextStyle(color: AppColors.primary, fontSize: 11.0, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                            const SizedBox(width: 6.0),
                                            const Text('·', style: TextStyle(color: AppColors.muted)),
                                            const SizedBox(width: 6.0),
                                            Text(
                                              Helpers.timeAgo(item.createdAt),
                                              style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5.0),
                                        Text(
                                          item.body.isNotEmpty ? item.body : item.text,
                                          style: const TextStyle(color: AppColors.text, fontSize: 13.0, height: 1.35),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              const Divider(height: 1.0, color: AppColors.border),
                              const SizedBox(height: 6.0),

                              // Actions Row (Like, Reply, Delete, Award Bounty)
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _communityController.toggleCommentLike(item.id),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item.liked ? Icons.favorite : Icons.favorite_border,
                                          color: item.liked ? const Color(0xFFFF3040) : AppColors.muted,
                                          size: 16.0,
                                        ),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          '${item.likeCount}',
                                          style: TextStyle(
                                            color: item.liked ? const Color(0xFFFF3040) : AppColors.muted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _replyTo = item);
                                      _commentFocusNode.requestFocus();
                                    },
                                    child: const Text(
                                      'Reply',
                                      style: TextStyle(color: AppColors.primary, fontSize: 12.0, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (item.mine) ...[
                                    const SizedBox(width: 16.0),
                                    GestureDetector(
                                      onTap: () => _confirmDeleteComment(item, post.id),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: AppColors.danger, fontSize: 12.0, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                  if (post.mine && post.bountyStatus == 'open' && item.authorId != post.authorId) ...[
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _confirmAwardBounty(post, item),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD88712).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.emoji_events, size: 12.0, color: Color(0xFFD88712)),
                                            SizedBox(width: 4.0),
                                            Text(
                                              'Award Bounty 🏆',
                                              style: TextStyle(color: Color(0xFFD88712), fontSize: 11.0, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16.0),

              // Replying Banner
              if (_replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, color: AppColors.primary, size: 16.0),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          'Replying to ${_replyTo!.authorName}',
                          style: const TextStyle(color: AppColors.text, fontSize: 12.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _replyTo = null),
                        child: const Icon(Icons.close, color: AppColors.muted, size: 16.0),
                      ),
                    ],
                  ),
                ),

              // Reply Box Field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      style: const TextStyle(color: AppColors.text, fontSize: 14.0),
                      decoration: InputDecoration(
                        hintText: _replyTo != null ? 'Reply to ${_replyTo!.authorName}...' : 'Add a respectful comment...',
                        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13.5),
                        fillColor: AppColors.surface,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  AppButton(
                    title: _replyTo != null ? 'Reply' : 'Post',
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
    });
  }
}

