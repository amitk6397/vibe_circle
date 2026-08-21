import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/discovery_controller.dart';
import '../widgets/person_grid_card.dart';
import '../../../routes/app_routes.dart';

class DiscoverPeopleView extends GetView<DiscoveryController> {
  const DiscoverPeopleView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadDiscoverPeople();

    return AppScreen(
      scroll: false,
      header: AppHeader(
        title: 'Discover people',
        subtitle: 'Purpose and interest-based suggestions',
        onBack: () => Get.back(),
        right: AppIconButton(
          icon: Icons.tune,
          onPressed: () => Get.toNamed(AppRoutes.SEARCH_FILTERS),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.people.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline,
              title: 'No people found',
              text: 'Try adjusting your filters or checking back later.',
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 0.72,
            ),
            itemCount: controller.people.length,
            itemBuilder: (context, index) {
              final person = controller.people[index];
              return PersonGridCard(
                person: person,
                onPressed: () => Get.toNamed(
                  AppRoutes.PUBLIC_PROFILE,
                  arguments: {'personId': person.id},
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
