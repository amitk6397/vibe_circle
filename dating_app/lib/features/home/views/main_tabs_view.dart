import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import 'home_view.dart';
import '../../discovery/views/discover_view.dart';
import '../../chat/views/inbox_view.dart';
import '../../profile/views/profile_view.dart';
import '../../matching/views/connect_view.dart';
import '../controllers/home_controller.dart';
import '../../chat/controllers/chat_controller.dart';

class MainTabsView extends GetView<HomeController> {
  const MainTabsView({super.key});

  static final List<Widget> _screens = [
    const HomeView(),
    const DiscoverView(),
    const ConnectView(),
    const InboxView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double barHeight = 64.0 + bottomInset;
    final chatController = Get.find<ChatController>();

    return Obx(() {
      final currentIndex = controller.selectedTabIndex.value;
      return Scaffold(
        body: _screens[currentIndex],
        bottomNavigationBar: Container(
          height: barHeight,
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8.0),
          decoration: const BoxDecoration(
            color: Color(0xFF15192B), // Custom dark tab bar bg
            border: Border(
              top: BorderSide(color: Color(0xFF2B304A), width: 1.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                index: 0,
                label: 'Home',
                activeIcon: Icons.home,
                inactiveIcon: Icons.home_outlined,
                currentIndex: currentIndex,
              ),
              _buildTabItem(
                index: 1,
                label: 'Discover',
                activeIcon: Icons.explore,
                inactiveIcon: Icons.explore_outlined,
                currentIndex: currentIndex,
              ),
              _buildCenterTabItem(index: 2, currentIndex: currentIndex),
              _buildTabItem(
                index: 3,
                label: 'Inbox',
                activeIcon: Icons.chat_bubble,
                inactiveIcon: Icons.chat_bubble_outline,
                badgeCount: chatController.chats.fold(0, (sum, chat) => sum + chat.unread),
                currentIndex: currentIndex,
              ),
              _buildTabItem(
                index: 4,
                label: 'Profile',
                activeIcon: Icons.person,
                inactiveIcon: Icons.person_outline,
                currentIndex: currentIndex,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required int currentIndex,
    int badgeCount = 0,
  }) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? AppColors.primary : AppColors.muted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.changeTab(index),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: 22.0,
                  color: color,
                ),
                const SizedBox(height: 4.0),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 4,
                right: 24,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16.0),
                  height: 16.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3040), // Red badge background
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterTabItem({required int index, required int currentIndex}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.changeTab(index),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -18,
              child: Container(
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(19.0),
                  border: Border.all(
                    color: AppColors.bg, // Matches scaffold bg
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.radio,
                  size: 26.0,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Text(
                'Live',
                style: TextStyle(
                  color: currentIndex == index ? AppColors.primary : AppColors.muted,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
