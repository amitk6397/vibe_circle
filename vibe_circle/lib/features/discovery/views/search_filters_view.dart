import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_data.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/discovery_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';

class SearchFiltersView extends StatefulWidget {
  const SearchFiltersView({super.key});

  @override
  State<SearchFiltersView> createState() => _SearchFiltersViewState();
}

class _SearchFiltersViewState extends State<SearchFiltersView> {
  final DiscoveryController _discoveryController = Get.find<DiscoveryController>();

  String _selectedPurpose = 'Talk';
  String _selectedGender = 'Any';
  String _selectedLanguage = 'English';
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _ageRangeController = TextEditingController();
  bool _onlineOnly = false;
  bool _ageRangeValid = true;

  final RegExp _ageRangeRegExp = RegExp(r'^\s*(1[89]|[2-9]\d)\s*-\s*(1[89]|[2-9]\d)\s*$');

  @override
  void initState() {
    super.initState();
    final filters = _discoveryController.searchFilters;
    _selectedPurpose = filters['purpose'] ?? 'Talk';
    _selectedGender = filters['gender'] ?? 'Any';
    _selectedLanguage = filters['language'] ?? 'English';
    _cityController.text = filters['city'] ?? '';
    _ageRangeController.text = '${filters['minAge'] ?? 18}-${filters['maxAge'] ?? 35}';
    _onlineOnly = filters['onlineOnly'] ?? false;
    _validateAgeRange(_ageRangeController.text);
  }

  void _validateAgeRange(String val) {
    setState(() {
      _ageRangeValid = _ageRangeRegExp.hasMatch(val);
    });
  }

  void _apply() {
    if (!_ageRangeValid) return;
    final parts = _ageRangeController.text.split('-');
    final int minAge = int.parse(parts[0].trim());
    final int maxAge = int.parse(parts[1].trim());

    _discoveryController.setSearchFilters({
      'purpose': _selectedPurpose,
      'gender': _selectedGender,
      'language': _selectedLanguage,
      'city': _cityController.text.trim(),
      'minAge': minAge,
      'maxAge': maxAge,
      'onlineOnly': _onlineOnly,
    });

    // Re-trigger load in background to refresh lists according to filters
    _discoveryController.loadDiscoverPeople();

    Get.back();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _ageRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Search filters',
        subtitle: 'Control who appears in discovery',
        onBack: () => Get.back(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Purpose
          const Text('Purpose', style: AppTextStyles.h2),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: AppData.purposes.map((x) {
              final name = x['name']!;
              return AppPill(
                label: name,
                selected: _selectedPurpose == name,
                onPressed: () => setState(() => _selectedPurpose = name),
              );
            }).toList(),
          ),
          const SizedBox(height: 20.0),

          // Gender
          const Text('Gender', style: AppTextStyles.h2),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: ['Any', 'Male', 'Female', 'Non-binary'].map((g) {
              return AppPill(
                label: g,
                selected: _selectedGender == g,
                onPressed: () => setState(() => _selectedGender = g),
              );
            }).toList(),
          ),
          const SizedBox(height: 20.0),

          // Language
          const Text('Language', style: AppTextStyles.h2),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: AppData.languages.map((x) {
              return AppPill(
                label: x,
                selected: _selectedLanguage == x,
                onPressed: () => setState(() => _selectedLanguage = x),
              );
            }).toList(),
          ),
          const SizedBox(height: 20.0),

          // City
          AppField(
            label: 'City',
            controller: _cityController,
            placeholder: 'Enter city name (optional)',
          ),
          const SizedBox(height: 16.0),

          // Age Range
          AppField(
            label: 'Age range',
            controller: _ageRangeController,
            placeholder: '18-35',
            keyboardType: TextInputType.text,
            onChanged: _validateAgeRange,
            errorText: !_ageRangeValid ? 'Use a range like 18-35' : null,
          ),
          const SizedBox(height: 16.0),

          // Online Switch card row
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Online now only',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14.0,
                  ),
                ),
                Switch(
                  value: _onlineOnly,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _onlineOnly = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Apply Button
          AppButton(
            title: 'Apply filters',
            disabled: !_ageRangeValid,
            onPressed: _apply,
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}
