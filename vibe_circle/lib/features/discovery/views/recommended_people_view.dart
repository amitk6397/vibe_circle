import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../widgets/person_grid_card.dart';
import '../controllers/discovery_controller.dart';
import '../../../routes/app_routes.dart';

class RecommendedPeopleView extends GetView<DiscoveryController> {
  const RecommendedPeopleView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadRecommendedPeople();

    return AppScreen(
      header: AppHeader(
        title: 'Recommended people',
        subtitle: 'Top recommendations based on your preferences',
        onBack: () => Get.back(),
      ),
      scroll: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          return controller.loading.value
              ? const Center(child: CircularProgressIndicator())
              : controller.recommendedPeople.isNotEmpty
                  ? GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12.0,
                        crossAxisSpacing: 12.0,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: controller.recommendedPeople.length,
                      itemBuilder: (context, idx) {
                        final person = controller.recommendedPeople[idx];
                        return PersonGridCard(
                          person: person,
                          onPressed: () => Get.toNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': person.id}),
                        );
                      },
                    )
                  : const AppEmptyState(
                      icon: Icons.people_outline,
                      title: 'No recommendations yet',
                      text: 'Add interests and conversation topics to receive relevant people.',
                    );
        }),
      ),
    );
  }
}
