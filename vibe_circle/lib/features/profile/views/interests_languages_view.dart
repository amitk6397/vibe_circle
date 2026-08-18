import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class InterestsLanguagesView extends StatefulWidget {
  const InterestsLanguagesView({super.key});

  @override
  State<InterestsLanguagesView> createState() => _InterestsLanguagesViewState();
}

class _InterestsLanguagesViewState extends State<InterestsLanguagesView> {
  static const List<String> _interests = [
    'Music', 'Art', 'Technology', 'Sports', 'Gaming', 'Travel', 'Food',
    'Fitness', 'Photography', 'Movies', 'Books', 'Science', 'Fashion',
    'Nature', 'Cooking', 'Dance', 'Meditation', 'Volunteering', 'Pets', 'Comedy',
  ];

  static const List<String> _languages = [
    'English', 'Hindi', 'Spanish', 'French', 'German', 'Portuguese',
    'Italian', 'Japanese', 'Korean', 'Arabic', 'Russian', 'Chinese',
  ];

  List<String> _selectedInterests = [];
  List<String> _selectedLanguages = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _selectedInterests = List<String>.from(args['interests'] ?? []);
      _selectedLanguages = List<String>.from(args['languages'] ?? []);
    }
  }

  void _toggle(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _saving = false);
    Get.back(result: {
      'interests': _selectedInterests,
      'languages': _selectedLanguages,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interests & Languages', style: AppTextStyles.titleMedium),
            Text(
              'Used for recommendations and relevant connections.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interests', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interests.map((interest) {
                      final selected = _selectedInterests.contains(interest);
                      return _PillChip(
                        label: interest,
                        selected: selected,
                        onTap: () => _toggle(_selectedInterests, interest),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Languages', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _languages.map((lang) {
                      final selected = _selectedLanguages.contains(lang);
                      return _PillChip(
                        label: lang,
                        selected: selected,
                        onTap: () => _toggle(_selectedLanguages, lang),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Save preferences', style: AppTextStyles.button),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
