import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ConnectSetupView extends StatefulWidget {
  const ConnectSetupView({super.key});

  @override
  State<ConnectSetupView> createState() => _ConnectSetupViewState();
}

class _ConnectSetupViewState extends State<ConnectSetupView> {
  static const List<Map<String, String>> _purposes = [
    {'name': 'Vent', 'color': '#E65100'},
    {'name': 'Listen', 'color': '#4F46E5'},
    {'name': 'Learn', 'color': '#0891B2'},
    {'name': 'Advice', 'color': '#7C3AED'},
    {'name': 'Friends', 'color': '#047857'},
    {'name': 'Support', 'color': '#BE185D'},
    {'name': 'Chat', 'color': '#B45309'},
  ];

  static const List<String> _languages = ['English', 'Hindi', 'Spanish', 'French', 'German'];

  String _purpose = 'Chat';
  String _language = 'English';
  String _ageRange = '18-35';
  bool _anonymous = false;
  int _sessionMinutes = 10;
  String? _ageError;

  bool _validateAge(String value) {
    final regex = RegExp(r'^\s*(1[89]|[2-9]\d)\s*-\s*(1[89]|[2-9]\d)\s*$');
    return regex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set up your connection', style: AppTextStyles.title),
            Text(
              'Choose what feels right today.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('I want to...', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _purposes.map((p) {
                final selected = _purpose == p['name'];
                return GestureDetector(
                  onTap: () => setState(() => _purpose = p['name']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      p['name']!,
                      style: AppTextStyles.body.copyWith(
                        color: selected ? Colors.white : AppColors.muted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Conversation language', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((lang) {
                final selected = _language == lang;
                return GestureDetector(
                  onTap: () => setState(() => _language = lang),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      lang,
                      style: AppTextStyles.body.copyWith(
                        color: selected ? Colors.white : AppColors.muted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Preferred age range', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: _ageRange,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: '18-35',
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                errorText: _ageError,
              ),
              onChanged: (value) {
                setState(() {
                  _ageRange = value;
                  _ageError = _validateAge(value) ? null : 'Use a range like 18-35';
                });
              },
            ),
            const SizedBox(height: 16),
            // Anonymous mode
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Anonymous mode', style: AppTextStyles.title),
                        Text(
                          'Hide your social profile during this conversation.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _anonymous,
                    onChanged: (v) => setState(() => _anonymous = v),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Conversation length', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [10, 20].map((min) {
                final selected = _sessionMinutes == min;
                return GestureDetector(
                  onTap: () => setState(() => _sessionMinutes = min),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      min == 10 ? '10-minute Connect' : '20 minutes',
                      style: AppTextStyles.body.copyWith(
                        color: selected ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'A focused session ends automatically. You can follow each other afterwards.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _ageError != null ? null : () {
                  Get.toNamed('/searching-match', arguments: {
                    'purpose': _purpose,
                    'anonymous': _anonymous,
                    'language': _language,
                    'ageRange': _ageRange,
                    'sessionMinutes': _sessionMinutes,
                  });
                },
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text('Find someone to talk with', style: AppTextStyles.buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
