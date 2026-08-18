import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_data.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../routes/app_routes.dart';

class ChoosePurposeView extends GetView<DiscoveryController> {
  const ChoosePurposeView({super.key});

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'chatbubbles':
        return Icons.chat;
      case 'people':
        return Icons.people;
      case 'bulb':
        return Icons.lightbulb;
      case 'school':
        return Icons.school;
      case 'heart':
        return Icons.favorite;
      case 'sparkles':
        return Icons.auto_awesome;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Choose your purpose',
        subtitle: 'You can change this anytime.',
        onBack: () => Get.back(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final String selected = controller.selectedPurpose.value;

            return Column(
              children: AppData.purposes.map((item) {
                final name = item['name']!;
                final icon = item['icon']!;
                final subtitle = item['subtitle']!;
                final colorHex = item['color']!;
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                final bool isSelected = selected == name;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: AppCard(
                    onPressed: () => controller.selectPurpose(name),
                    borderColor: isSelected ? color : const Color(0xFF2B304A),
                    child: Row(
                      children: [
                        Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(13.0),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getIcon(icon),
                            size: 21.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 12.0),
                          Icon(
                            Icons.check_circle,
                            size: 24.0,
                            color: color,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 16.0),
          AppButton(
            title: 'Show my recommendations',
            onPressed: () {
              Get.offAllNamed(AppRoutes.MAIN);
            },
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}
