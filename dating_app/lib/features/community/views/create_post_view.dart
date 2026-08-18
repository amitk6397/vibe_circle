import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/community_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final CommunityController _communityController = Get.find<CommunityController>();
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _bountyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _postType = 'Text'; // 'Text' | 'Question' | 'Poll' | 'Image'
  bool _anonymous = false;
  String _visibility = 'public'; // 'public' | 'private'
  XFile? _imageFile;
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _publishing = false;

  @override
  void dispose() {
    _bodyController.dispose();
    _bountyController.dispose();
    _priceController.dispose();
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _imageFile = file;
        _postType = 'Image';
      });
    }
  }

  void _publish() async {
    final text = _bodyController.text.trim();
    if (text.length < 3) {
      Get.snackbar('Input Error', 'Post content must be at least 3 characters.');
      return;
    }

    setState(() => _publishing = true);

    try {
      final payload = {
        'content': text,
        'anonymous': _anonymous,
        'post_type': _postType,
        'visibility': _visibility,
        if (_postType == 'Poll')
          'poll_options': _pollOptionControllers.map((c) => c.text.trim()).toList(),
        if (_postType == 'Question' && _bountyController.text.isNotEmpty)
          'bounty_amount': int.tryParse(_bountyController.text),
        if (_visibility == 'private' && _priceController.text.isNotEmpty)
          'coin_price': int.tryParse(_priceController.text),
        if (_imageFile != null)
          'media_urls': [_imageFile!.path],
      };

      await _communityController.createPost(payload);

      Get.back();
      Get.snackbar(
        'Success 🎉',
        'Your post has been published.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Publish Failed', e.toString());
    } finally {
      setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String myName = _authController.profile.value?.name ?? 'User';

    return AppScreen(
      header: AppHeader(
        title: 'Create post',
        subtitle: 'Share something useful or start a conversation.',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Composer Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        name: _anonymous ? 'Anonymous' : myName,
                        size: 40.0,
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _anonymous ? 'Posting anonymously' : myName,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Public feed', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: _bodyController,
                    maxLines: 5,
                    maxLength: 1200,
                    style: const TextStyle(color: AppColors.text, fontSize: 14.0),
                    decoration: const InputDecoration(
                      hintText: 'Share an idea, question or experience...',
                      hintStyle: TextStyle(color: AppColors.muted),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Format Selection
            const Text('Choose format', style: AppTextStyles.h2),
            const SizedBox(height: 8.0),
            Row(
              children: ['Text', 'Question', 'Poll', 'Image'].map((type) {
                final bool isSelected = _postType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: AppButton(
                      title: type,
                      tone: isSelected ? AppButtonTone.primary : AppButtonTone.secondary,
                      onPressed: () {
                        if (type == 'Image') {
                          _pickImage();
                        } else {
                          setState(() => _postType = type);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12.0),

            // Question Bounty Input
            if (_postType == 'Question')
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attach a coin bounty 🏆', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4.0),
                    const Text('Give incentive for detailed, helpful answers.', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                    const SizedBox(height: 8.0),
                    AppField(
                      label: 'Bounty Amount',
                      placeholder: 'Min 10 coins (Optional)',
                      controller: _bountyController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

            // Poll Options Input
            if (_postType == 'Poll') ...[
              AppField(label: 'Option 1', placeholder: 'Option 1', controller: _pollOptionControllers[0]),
              const SizedBox(height: 8.0),
              AppField(label: 'Option 2', placeholder: 'Option 2', controller: _pollOptionControllers[1]),
              const SizedBox(height: 12.0),
            ],

            // Image Preview Card
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Image.file(
                  File(_imageFile!.path),
                  height: 180.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12.0),
            ],

            // Anonymous Switch Row
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Post anonymously', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                      Text('Your identity remains private to other members.', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                    ],
                  ),
                  Switch(
                    value: _anonymous,
                    onChanged: (val) => setState(() => _anonymous = val),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Visibility Permission Selector
            const Text('Who can view?', style: AppTextStyles.h2),
            const SizedBox(height: 8.0),
            Row(
              children: [
                AppPill(
                  label: 'Public',
                  selected: _visibility == 'public',
                  onPressed: () => setState(() => _visibility = 'public'),
                ),
                const SizedBox(width: 8.0),
                AppPill(
                  label: 'Private · paid',
                  selected: _visibility == 'private',
                  onPressed: () => setState(() => _visibility = 'private'),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            if (_visibility == 'private')
              AppField(
                label: 'Set unlock price (Coins)',
                placeholder: 'Default 5 coins',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 20.0),

            // Submit Button
            AppButton(
              title: 'Publish post',
              loading: _publishing,
              onPressed: _publish,
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
