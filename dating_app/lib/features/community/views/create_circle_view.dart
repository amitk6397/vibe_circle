import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class CreateCircleView extends StatefulWidget {
  const CreateCircleView({super.key});

  @override
  State<CreateCircleView> createState() => _CreateCircleViewState();
}

class _CreateCircleViewState extends State<CreateCircleView> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _limitCtrl = TextEditingController(text: '12');
  bool _creating = false;

  bool get _limitValid {
    final v = int.tryParse(_limitCtrl.text);
    return v != null && v >= 2 && v <= 50;
  }

  bool get _canCreate =>
      _nameCtrl.text.trim().length >= 3 && _descCtrl.text.trim().length >= 10 && _limitValid;

  Future<void> _create() async {
    setState(() => _creating = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _creating = false);
    Get.back(result: {'created': true});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
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
            Text('Create private circle', style: AppTextStyles.title),
            Text(
              'A small invite-only space for people you trust.',
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
            _FormField(label: 'Circle name', controller: _nameCtrl, hint: 'Close friends', onChanged: (_) => setState(() {})),
            const SizedBox(height: 14),
            _FormField(label: 'Description', controller: _descCtrl, hint: 'What will your circle share?', maxLines: 3, onChanged: (_) => setState(() {})),
            const SizedBox(height: 14),
            _FormField(
              label: 'Member limit',
              controller: _limitCtrl,
              hint: '12',
              keyboardType: TextInputType.number,
              error: !_limitValid ? 'Choose 2 to 50 members' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Privacy info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite-only privacy', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(
                          'Only invited members can find, open or join this circle.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canCreate && !_creating ? _create : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _creating
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create circle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final String? error;
  final Function(String) onChanged;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            errorText: error,
            errorStyle: const TextStyle(color: AppColors.danger),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
