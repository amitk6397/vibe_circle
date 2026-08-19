import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/community_controller.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';
import '../../../routes/app_routes.dart';

class CreateCommunityView extends StatefulWidget {
  const CreateCommunityView({super.key});

  @override
  State<CreateCommunityView> createState() => _CreateCommunityViewState();
}

class _CreateCommunityViewState extends State<CreateCommunityView> {
  final CommunityController _communityController = Get.find<CommunityController>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController(text: 'Be kind. Stay on topic. No spam.');
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _langController = TextEditingController(text: 'English');

  String _privacy = 'Public';
  String _themeColor = '#5B5CE2';
  bool _creating = false;
  File? _logoFile;
  File? _coverFile;

  final List<String> _colorOptions = ['#5B5CE2', '#2FA89A', '#F06A6A', '#E79B32', '#2878D4'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _rulesController.dispose();
    _tagsController.dispose();
    _locationController.dispose();
    _langController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      setState(() => _logoFile = File(file.path));
    }
  }

  Future<void> _pickCover() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      setState(() => _coverFile = File(file.path));
    }
  }

  void _create() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final cat = _categoryController.text.trim();

    if (name.isEmpty || desc.isEmpty || cat.isEmpty) {
      Get.snackbar('Input Error', 'Please fill in name, description, and category.');
      return;
    }

    setState(() => _creating = true);

    try {
      String? logoUrl;
      String? coverUrl;

      if (_logoFile != null) {
        final res = await NetworkApiService.instance.uploadFile(ApiUrls.uploads, _logoFile!);
        logoUrl = res.data['url'] as String?;
      }
      if (_coverFile != null) {
        final res = await NetworkApiService.instance.uploadFile(ApiUrls.uploads, _coverFile!);
        coverUrl = res.data['url'] as String?;
      }

      final payload = {
        'name': name,
        'description': desc,
        'category': cat,
        'privacy': _privacy == 'Private' ? 'private' : 'public',
        'premium_price': 0,
        'rules': _rulesController.text.split(RegExp(r'[.\n]')).map((x) => x.trim()).where((x) => x.isNotEmpty).toList(),
        'tags': _tagsController.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList(),
        'location': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        'language': _langController.text.trim().isNotEmpty ? _langController.text.trim() : null,
        'color': _themeColor,
        'logo_url': logoUrl,
        'cover_url': coverUrl,
      };

      final newComm = await _communityController.createCommunity(payload);

      Get.offNamed(AppRoutes.COMMUNITY_DETAILS, arguments: {'communityId': newComm.id});
      Get.snackbar(
        'Community created 🎉',
        '$name is ready for its first members.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Could not create community', e.toString());
    } finally {
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Create community',
        subtitle: 'Build a welcoming space with clear rules.',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppField(
              label: 'Community name',
              placeholder: 'A memorable name',
              controller: _nameController,
            ),
            const SizedBox(height: 12.0),
            AppField(
              label: 'Description',
              placeholder: 'What will members do here?',
              controller: _descController,
              multiline: true,
            ),
            const SizedBox(height: 12.0),
            AppField(
              label: 'Category',
              placeholder: 'For example: Technology',
              controller: _categoryController,
            ),
            const SizedBox(height: 16.0),

            const Text('Privacy', style: AppTextStyles.h2),
            const SizedBox(height: 8.0),
            Row(
              children: ['Public', 'Private'].map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: AppPill(
                    label: p,
                    selected: _privacy == p,
                    onPressed: () => setState(() => _privacy = p),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12.0),
            AppField(
              label: 'Community rules',
              placeholder: 'Be kind. Stay on topic. No spam.',
              controller: _rulesController,
              multiline: true,
            ),
            const SizedBox(height: 16.0),

            const Text('Community theme color', style: AppTextStyles.h2),
            const SizedBox(height: 8.0),
            Row(
              children: _colorOptions.map((hex) {
                final int colorInt = int.parse(hex.replaceFirst('#', 'FF'), radix: 16);
                final bool isSelected = _themeColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _themeColor = hex),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10.0),
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      color: Color(colorInt),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3.0) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),

            const Text('Community Assets', style: AppTextStyles.h2),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: _logoFile != null ? 'Logo Selected 🖼️' : 'Choose logo',
                    tone: AppButtonTone.secondary,
                    onPressed: _pickLogo,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: AppButton(
                    title: _coverFile != null ? 'Cover Selected 🖼️' : 'Choose cover',
                    tone: AppButtonTone.secondary,
                    onPressed: _pickCover,
                  ),
                ),
              ],
            ),
            if (_coverFile != null) ...[
              const SizedBox(height: 12.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.file(_coverFile!, height: 150.0, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 16.0),

            AppField(
              label: 'Tags',
              placeholder: 'technology, learning, local',
              controller: _tagsController,
            ),
            const SizedBox(height: 12.0),

            AppField(
              label: 'Location (optional)',
              placeholder: 'Delhi, India',
              controller: _locationController,
            ),
            const SizedBox(height: 12.0),

            AppField(
              label: 'Primary language',
              placeholder: 'Hindi',
              controller: _langController,
            ),
            const SizedBox(height: 20.0),

            AppButton(
              title: 'Create community',
              loading: _creating,
              onPressed: _create,
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
