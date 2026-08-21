import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/community_controller.dart';
import '../models/post.dart';
import '../../../routes/app_routes.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onPressed;
  final VoidCallback? onAuthorPressed;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onBookmarkPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onGiftPressed;

  const PostCard({
    super.key,
    required this.post,
    this.onPressed,
    this.onAuthorPressed,
    this.onLikePressed,
    this.onCommentPressed,
    this.onBookmarkPressed,
    this.onSharePressed,
    this.onGiftPressed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool _showBigHeart = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartAnimController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartAnimController);
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onDoubleTapLike() {
    setState(() => _showBigHeart = true);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _showBigHeart = false);
    });
    HapticFeedback.mediumImpact();

    if (!widget.post.isLiked) {
      if (widget.onLikePressed != null) {
        widget.onLikePressed!();
      } else if (Get.isRegistered<CommunityController>()) {
        Get.find<CommunityController>().toggleLike(widget.post.id);
      }
    }
  }

  void _handleLike() {
    HapticFeedback.selectionClick();
    if (widget.onLikePressed != null) {
      widget.onLikePressed!();
    } else if (Get.isRegistered<CommunityController>()) {
      Get.find<CommunityController>().toggleLike(widget.post.id);
    }
  }

  void _handleBookmark() {
    HapticFeedback.selectionClick();
    if (widget.onBookmarkPressed != null) {
      widget.onBookmarkPressed!();
    } else if (Get.isRegistered<CommunityController>()) {
      Get.find<CommunityController>().toggleSave(widget.post.id);
    }
  }

  void _handleShare() {
    if (widget.onSharePressed != null) {
      widget.onSharePressed!();
      return;
    }
    final shareText = 'Check out this post on VibeCircle: "${widget.post.content.isNotEmpty ? widget.post.content : 'Post'}" by ${widget.post.authorName}';
    Clipboard.setData(ClipboardData(text: shareText));
    Get.snackbar(
      'Link copied! 📋',
      'Post link copied to clipboard.',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _showGiftSheet(BuildContext context) {
    if (widget.onGiftPressed != null) {
      widget.onGiftPressed!();
      return;
    }
    final communityCtrl = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : Get.put(CommunityController());

    Get.bottomSheet(
      FutureBuilder<dynamic>(
        future: () async {
          try {
            return await NetworkApiService.instance.get('/gifts');
          } catch (_) {
            return null;
          }
        }(),
        builder: (context, snapshot) {
          List<Map<String, dynamic>> giftsList = [
            {'id': 'gift_heart', 'name': 'Heart', 'emoji': '❤️', 'coins': 5, 'coin_price': 5},
            {'id': 'gift_star', 'name': 'Star', 'emoji': '⭐', 'coins': 10, 'coin_price': 10},
            {'id': 'gift_fire', 'name': 'Fire', 'emoji': '🔥', 'coins': 20, 'coin_price': 20},
            {'id': 'gift_diamond', 'name': 'Diamond', 'emoji': '💎', 'coins': 50, 'coin_price': 50},
            {'id': 'gift_crown', 'name': 'Crown', 'emoji': '👑', 'coins': 100, 'coin_price': 100},
            {'id': 'gift_rocket', 'name': 'Rocket', 'emoji': '🚀', 'coins': 200, 'coin_price': 200},
          ];

          if (snapshot.hasData && snapshot.data != null && snapshot.data.data is List) {
            final fetched = (snapshot.data.data as List).map((g) {
              final map = Map<String, dynamic>.from(g as Map);
              return {
                'id': map['id']?.toString() ?? '',
                'name': map['name']?.toString() ?? 'Gift',
                'emoji': map['icon']?.toString() ?? '🎁',
                'coins': map['coin_price'] ?? 10,
                'coin_price': map['coin_price'] ?? 10,
              };
            }).toList();
            if (fetched.isNotEmpty) {
              giftsList = fetched;
            }
          }

          return Container(
            padding: const EdgeInsets.all(20.0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Send Gift or Tip 🎁',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.SUBSCRIPTION_PLANS);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on, size: 14.0, color: AppColors.primary),
                              SizedBox(width: 4.0),
                              Text(
                                'Buy Coins',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  const Text(
                    'SELECT A VIRTUAL GIFT',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: giftsList.map((gift) {
                      return InkWell(
                        onTap: () async {
                          Get.back();
                          try {
                            await communityCtrl.sendGiftToPost(
                              widget.post.id,
                              gift,
                              widget.post.authorId,
                            );
                            Get.snackbar(
                              'Gift Sent! ${gift['emoji']}',
                              'You sent a ${gift['name']} (${gift['coins']} coins) to ${widget.post.authorName}.',
                              backgroundColor: AppColors.primary,
                              colorText: Colors.white,
                            );
                          } catch (e) {
                            Get.snackbar('Gift failed', e.toString());
                          }
                        },
                        borderRadius: BorderRadius.circular(14.0),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 56) / 3,
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Text(gift['emoji'] as String? ?? '🎁', style: const TextStyle(fontSize: 26.0)),
                              const SizedBox(height: 4.0),
                              Text(
                                gift['name'] as String? ?? 'Gift',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                '🪙 ${gift['coins']}',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'QUICK COIN TIPS',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [5, 10, 20, 50, 100].map((amt) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: InkWell(
                            onTap: () async {
                              Get.back();
                              try {
                                await communityCtrl.tipPost(widget.post.id, amt);
                                Get.snackbar(
                                  'Tipped! 🪙',
                                  'You tipped $amt coins to ${widget.post.authorName}.',
                                  backgroundColor: AppColors.primary,
                                  colorText: Colors.white,
                                );
                              } catch (e) {
                                Get.snackbar('Tip failed', e.toString());
                              }
                            },
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '+$amt 🪙',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditPostDialog(BuildContext context) {
    final editCtrl = TextEditingController(text: widget.post.content.isNotEmpty ? widget.post.content : widget.post.body);
    Get.defaultDialog(
      title: 'Edit Post',
      content: TextField(
        controller: editCtrl,
        maxLines: 4,
        style: const TextStyle(color: AppColors.text),
        decoration: const InputDecoration(
          hintText: 'Edit your post content...',
          hintStyle: TextStyle(color: AppColors.muted),
          border: OutlineInputBorder(),
        ),
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () async {
        final newBody = editCtrl.text.trim();
        if (newBody.length < 3) return;
        Get.back();
        try {
          final ctrl = Get.isRegistered<CommunityController>()
              ? Get.find<CommunityController>()
              : Get.put(CommunityController());
          await ctrl.updatePost(widget.post.id, newBody);
          Get.snackbar('Updated', 'Post has been updated.');
        } catch (e) {
          Get.snackbar('Update failed', e.toString());
        }
      },
    );
  }

  void _showReportDialog() {
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
              'target_id': widget.post.id,
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
              'target_id': widget.post.id,
              'reason': 'Harassment',
            });
            Get.snackbar('Report submitted', 'Thank you. Our safety team will review your report.');
          },
        ),
      ],
    );
  }

  void _showPostOptions(BuildContext context) {
    final communityCtrl = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : Get.put(CommunityController());

    Get.bottomSheet(
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.post.mine) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('Edit post', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Get.back();
                    _showEditPostDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.rocket_launch, color: Color(0xFF8B5CF6)),
                  title: const Text('Boost post (50 coins)', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pin your post to the top of feed', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                  onTap: () async {
                    Get.back();
                    try {
                      await communityCtrl.boostPost(widget.post.id);
                      Get.snackbar('Post Boosted! 🚀', 'Your post is now boosted for higher visibility.', backgroundColor: AppColors.primary, colorText: Colors.white);
                    } catch (e) {
                      Get.snackbar('Boost failed', e.toString());
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text('Delete post', style: TextStyle(color: AppColors.danger)),
                  onTap: () async {
                    Get.back();
                    try {
                      await communityCtrl.deletePost(widget.post.id);
                      Get.snackbar('Deleted', 'Post has been removed.');
                    } catch (e) {
                      Get.snackbar('Delete failed', e.toString());
                    }
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share_outlined, color: AppColors.text),
                title: const Text('Share post', style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Get.back();
                  _handleShare();
                },
              ),
              ListTile(
                leading: Icon(
                  widget.post.saved ? Icons.bookmark_remove : Icons.bookmark_add_outlined,
                  color: AppColors.text,
                ),
                title: Text(widget.post.saved ? 'Remove from saved' : 'Save post', style: const TextStyle(color: AppColors.text)),
                onTap: () {
                  Get.back();
                  _handleBookmark();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.danger),
                title: const Text('Report post', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Get.back();
                  _showReportDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final communityCtrl = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : Get.put(CommunityController());

    final timeString = Helpers.timeAgo(post.createdAt);
    final String? resolvedImageUrl = post.mediaUrls.isNotEmpty
        ? Helpers.resolveImageUrl(post.mediaUrls.first)
        : null;

    return AppCard(
      onPressed: widget.onPressed,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Instagram Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onAuthorPressed ?? () {
                    if (post.authorId.isNotEmpty) {
                      Get.toNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': post.authorId});
                    }
                  },
                  child: AppAvatar(
                    name: post.authorName,
                    avatarUrl: post.authorAvatar,
                    size: 38.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onAuthorPressed ?? () {
                      if (post.authorId.isNotEmpty) {
                        Get.toNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': post.authorId});
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.authorUsername != null && post.authorUsername!.isNotEmpty) ...[
                              const SizedBox(width: 4.0),
                              Text(
                                '@${post.authorUsername}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (post.isBoosted) ...[
                              const SizedBox(width: 6.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 9.0, color: Colors.white),
                                    SizedBox(width: 2.0),
                                    Text(
                                      'BOOSTED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.0,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2.0),
                        Row(
                          children: [
                            Text(
                              timeString,
                              style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
                            ),
                            if (post.community.isNotEmpty && post.community != 'Discover') ...[
                              const Text(' · ', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                              Text(
                                post.community,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20.0, color: AppColors.muted),
                  onPressed: () => _showPostOptions(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 2. Ask & Earn Bounty banner
          if (post.bountyAmount > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFEA580C), size: 18.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ASK & EARN BOUNTY: ${post.bountyAmount.toInt()} COINS',
                            style: const TextStyle(
                              color: Color(0xFF9A3412),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            post.bountyStatus == 'open'
                                ? 'Active bounty! Best answer chosen by author wins reward.'
                                : post.bountyStatus == 'awarded'
                                    ? 'Bounty awarded! This question has been solved.'
                                    : 'Status: ${post.bountyStatus}',
                            style: const TextStyle(color: Color(0xFFC2410C), fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 3. Media Image (Instagram full-width with double tap to like)
          if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty && !post.locked) ...[
            GestureDetector(
              onDoubleTap: _onDoubleTapLike,
              onTap: () => _showImagePreview(context, resolvedImageUrl),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 380.0, minHeight: 200.0),
                    color: AppColors.surfaceAlt,
                    child: Image.network(
                      resolvedImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160.0,
                        color: AppColors.surfaceAlt,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, color: AppColors.muted, size: 36),
                      ),
                    ),
                  ),

                  // Animated Heart overlay on double tap
                  if (_showBigHeart)
                    AnimatedBuilder(
                      animation: _heartAnimController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _heartScale.value,
                          child: Opacity(
                            opacity: _heartOpacity.value.clamp(0.0, 1.0),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 100.0,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 16.0),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],

          // 4. Locked / Exclusive Post Card
          if (post.locked) ...[
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF231C35), Color(0xFF1B1829)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, color: AppColors.primary, size: 24.0),
                    ),
                    const SizedBox(height: 10.0),
                    const Text(
                      'Exclusive Post',
                      style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Unlock once to view this post anytime.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.0),
                    ),
                    const SizedBox(height: 14.0),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await communityCtrl.unlockPost(post.id);
                          Get.snackbar(
                            'Post Unlocked! 🎉',
                            '${post.coinPrice.toInt()} coins deducted.',
                            backgroundColor: AppColors.primary,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.snackbar('Unlock failed', 'Check your coin balance.');
                        }
                      },
                      icon: const Icon(Icons.lock_open, size: 16.0, color: Colors.white),
                      label: Text('Unlock · ${post.coinPrice.toInt()} coins', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 5. Poll Options
          if (post.pollOptions.isNotEmpty && !post.locked) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                children: post.pollOptions.map((opt) {
                  final int totalVotes = post.pollResults.values.fold(0, (sum, v) => sum + v);
                  final int optVotes = post.pollResults[opt] ?? 0;
                  final int pct = totalVotes > 0 ? ((optVotes / totalVotes) * 100).round() : 0;
                  final bool isMyVote = post.myVote == opt;

                  return GestureDetector(
                    onTap: () => communityCtrl.vote(post.id, opt),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isMyVote ? AppColors.primary : AppColors.border,
                          width: isMyVote ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            opt,
                            style: TextStyle(
                              color: isMyVote ? AppColors.primary : AppColors.text,
                              fontWeight: isMyVote ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13.0,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold, fontSize: 12.0),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // 6. Instagram Action Row: Like, Comment, Share, Gift (Left) + Bookmark (Right)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Row(
              children: [
                // Heart Like
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? const Color(0xFFFF3040) : AppColors.text,
                    size: 26.0,
                  ),
                  onPressed: _handleLike,
                ),
                // Comment
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.text,
                    size: 23.0,
                  ),
                  onPressed: widget.onCommentPressed ?? widget.onPressed ?? () {
                    Get.toNamed(AppRoutes.POST_DETAILS, arguments: {'postId': post.id});
                  },
                ),
                // Share
                IconButton(
                  icon: const Icon(
                    Icons.send_outlined,
                    color: AppColors.text,
                    size: 22.0,
                  ),
                  onPressed: _handleShare,
                ),
                // Gift / Tip
                IconButton(
                  icon: const Icon(
                    Icons.card_giftcard_outlined,
                    color: AppColors.text,
                    size: 23.0,
                  ),
                  onPressed: () => _showGiftSheet(context),
                ),
                const Spacer(),
                // Bookmark
                IconButton(
                  icon: Icon(
                    post.saved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.saved ? AppColors.primary : AppColors.text,
                    size: 25.0,
                  ),
                  onPressed: _handleBookmark,
                ),
              ],
            ),
          ),

          // 7. Likes & Tips Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${post.likesCount} likes',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                if (post.tipTotal > 0 || post.gifts.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      if (post.tipTotal > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            '💝 ${post.tipTotal.toInt()} coins tipped',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ...post.gifts.map((g) {
                        final giftMap = g is Map ? g : {};
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            '${giftMap['gift_emoji'] ?? giftMap['emoji'] ?? '🎁'} ${giftMap['gift_name'] ?? giftMap['name'] ?? 'Gift'}',
                            style: const TextStyle(fontSize: 11.0, color: AppColors.text),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 8. Caption Row: Author Name in Bold + Text
          if (post.content.isNotEmpty && !post.locked) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.4),
                  children: [
                    TextSpan(
                      text: '${post.authorName} ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: post.content),
                  ],
                ),
              ),
            ),
          ],

          // 9. View all comments link
          if (post.commentsCount > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
              child: GestureDetector(
                onTap: widget.onCommentPressed ?? widget.onPressed ?? () {
                  Get.toNamed(AppRoutes.POST_DETAILS, arguments: {'postId': post.id});
                },
                child: Text(
                  'View all ${post.commentsCount} comment${post.commentsCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          // 10. Timestamp
          Padding(
            padding: const EdgeInsets.fromLTRB(14.0, 4.0, 14.0, 12.0),
            child: Text(
              timeString.toUpperCase(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.0,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
