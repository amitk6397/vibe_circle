import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/community_controller.dart';
import '../models/post.dart';
import '../../../routes/app_routes.dart';

const _kPostGifts = [
  {'name': 'Heart', 'emoji': '❤️', 'coins': 5},
  {'name': 'Star', 'emoji': '⭐', 'coins': 10},
  {'name': 'Fire', 'emoji': '🔥', 'coins': 20},
  {'name': 'Diamond', 'emoji': '💎', 'coins': 50},
  {'name': 'Crown', 'emoji': '👑', 'coins': 100},
  {'name': 'Rocket', 'emoji': '🚀', 'coins': 200},
];

const _kTipAmounts = [5, 10, 20, 50, 100];

class PostCard extends StatelessWidget {
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

  void _showGiftSheet(BuildContext context) {
    final communityCtrl = Get.find<CommunityController>();

    Get.bottomSheet(
      Container(
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
              // Header
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

              // Gifts Section
              const Text(
                'SEND A GIFT',
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
                children: _kPostGifts.map((gift) {
                  return InkWell(
                    onTap: () async {
                      Get.back();
                      try {
                        await communityCtrl.sendGiftToPost(post.id, gift);
                        Get.snackbar(
                          'Gift Sent! ${gift['emoji']}',
                          'You sent a ${gift['name']} (${gift['coins']} coins) to ${post.authorName}.',
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
                          Text(gift['emoji'] as String, style: const TextStyle(fontSize: 26.0)),
                          const SizedBox(height: 4.0),
                          Text(
                            gift['name'] as String,
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

              // Quick Coin Tips
              const Text(
                'QUICK TIP COINS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: _kTipAmounts.map((amt) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: InkWell(
                        onTap: () async {
                          Get.back();
                          try {
                            await communityCtrl.tipPost(post.id, amt);
                            Get.snackbar(
                              'Tipped! 🪙',
                              'You tipped $amt coins to ${post.authorName}.',
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
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    final communityCtrl = Get.find<CommunityController>();

    Get.bottomSheet(
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (post.mine) ...[
                ListTile(
                  leading: const Icon(Icons.rocket_launch, color: Color(0xFF8B5CF6)),
                  title: const Text('Boost post (50 coins)', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pin your post to the top of feed', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                  onTap: () async {
                    Get.back();
                    try {
                      await communityCtrl.boostPost(post.id);
                      Get.snackbar(
                        'Post Boosted! 🚀',
                        'Your post is now boosted for higher visibility.',
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                      );
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
                      await communityCtrl.deletePost(post.id);
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
                  onSharePressed?.call();
                },
              ),
              ListTile(
                leading: Icon(
                  post.saved ? Icons.bookmark_remove : Icons.bookmark_add_outlined,
                  color: AppColors.text,
                ),
                title: Text(post.saved ? 'Remove from saved' : 'Save post', style: const TextStyle(color: AppColors.text)),
                onTap: () {
                  Get.back();
                  onBookmarkPressed?.call();
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
    final communityCtrl = Get.find<CommunityController>();

    return AppCard(
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          GestureDetector(
            onTap: onAuthorPressed,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AppAvatar(
                  name: post.authorName,
                  avatarUrl: post.authorAvatar,
                  size: 38.0,
                ),
                const SizedBox(width: 10.0),
                Expanded(
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
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      const SizedBox(height: 1.0),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 10.0, color: AppColors.muted),
                          const SizedBox(width: 3.0),
                          const Text(
                            'Recent',
                            style: TextStyle(color: AppColors.muted, fontSize: 10.5),
                          ),
                          if (post.community.isNotEmpty && post.community != 'Discover') ...[
                            const Text(' · ', style: TextStyle(color: AppColors.muted, fontSize: 10.5)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                post.community,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // More options button
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20.0, color: AppColors.muted),
                  onPressed: () => _showPostOptions(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),

          // Bounty banner
          if (post.bountyAmount > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10.0),
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
                              ? 'Active bounty! Best answer chosen by author wins the reward.'
                              : post.bountyStatus == 'awarded'
                                  ? 'Bounty awarded! This question has been solved.'
                                  : 'Status: ${post.bountyStatus}',
                          style: const TextStyle(
                            color: Color(0xFFC2410C),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Post body text (or locked placeholder)
          if (!post.locked) ...[
            Text(
              post.content,
              style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.45),
            ),

            // Media
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 10.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  post.mediaUrls.first,
                  height: 200.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140.0,
                    color: AppColors.surfaceAlt,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Exclusive / Locked Private Post Card
            Container(
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Unlock once to view this post and its content anytime.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.0),
                    textAlign: TextAlign.center,
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
                        Get.snackbar(
                          'Unlock failed',
                          'Check your coin balance and try again.',
                        );
                      }
                    },
                    icon: const Icon(Icons.lock_open, size: 16.0, color: Colors.white),
                    label: Text(
                      'Unlock · ${post.coinPrice.toInt()} coins',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Poll Options
          if (post.pollOptions.isNotEmpty && !post.locked) ...[
            const SizedBox(height: 10.0),
            Column(
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
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Tips and Gifts chips row
          if (post.tipTotal > 0 || post.gifts.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: [
                if (post.tipTotal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '💝 ${post.tipTotal.toInt()} coins tipped (${post.tipCount} tips)',
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
                      '${giftMap['gift_emoji'] ?? '🎁'} ${giftMap['gift_name'] ?? 'Gift'}',
                      style: const TextStyle(fontSize: 11.0, color: AppColors.text),
                    ),
                  );
                }),
              ],
            ),
          ],

          const SizedBox(height: 12.0),
          const Divider(color: AppColors.border, height: 1.0),
          const SizedBox(height: 8.0),

          // Action row — Like, Comment, Gift, then Bookmark + Share on right
          Row(
            children: [
              // Like
              _ActionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: '${post.likesCount}',
                color: post.isLiked ? AppColors.danger : AppColors.muted,
                onTap: onLikePressed,
              ),
              const SizedBox(width: 4.0),

              // Comment
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${post.commentsCount}',
                color: AppColors.muted,
                onTap: onCommentPressed ?? onPressed,
              ),
              const SizedBox(width: 4.0),

              // Gift / Tip
              _ActionButton(
                icon: Icons.card_giftcard_outlined,
                label: 'Gift',
                color: AppColors.muted,
                onTap: onGiftPressed ?? () => _showGiftSheet(context),
              ),

              const Spacer(),

              // Share
              _ActionButton(
                icon: Icons.share_outlined,
                label: '',
                color: AppColors.muted,
                onTap: onSharePressed,
              ),
              const SizedBox(width: 4.0),

              // Bookmark
              _ActionButton(
                icon: post.saved ? Icons.bookmark : Icons.bookmark_border,
                label: '',
                color: post.saved ? AppColors.primary : AppColors.muted,
                onTap: onBookmarkPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.0, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4.0),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
