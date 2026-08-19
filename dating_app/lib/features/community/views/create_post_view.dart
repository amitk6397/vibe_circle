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
import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';

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
  String? _communityId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _communityId = args?['communityId'];
  }

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
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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
      List<String> mediaUrls = [];
      if (_postType == 'Image' && _imageFile != null) {
        final File file = File(_imageFile!.path);
        final response = await NetworkApiService.instance.uploadFile(ApiUrls.uploads, file);
        if (response.data != null && response.data['url'] != null) {
          mediaUrls.add(response.data['url'].toString());
        }
      }

      final payload = {
        'content': text,
        'anonymous': _anonymous,
        'post_type': _postType,
        'visibility': _visibility,
        if (_communityId != null) 'community_id': _communityId,
        if (_postType == 'Poll')
          'poll_options': _pollOptionControllers.map((c) => c.text.trim()).toList(),
        if (_postType == 'Question' && _bountyController.text.isNotEmpty)
          'bounty_amount': int.tryParse(_bountyController.text),
        if (_visibility == 'private' && _priceController.text.isNotEmpty)
          'coin_price': int.tryParse(_priceController.text),
        if (mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
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
    final community = _communityId != null
        ? _communityController.communities.firstWhereOrNull((c) => c.id == _communityId)
        : null;

    return AppScreen(
      header: AppHeader(
        title: 'Create post',
        subtitle: community != null ? 'Posting in ${community.name}' : 'Share something useful or start a conversation.',
        onBack: () => Get.back(),
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Linear Gradient Hero
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A1F3D), Color(0xFF1E2540)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.create_outlined, color: Colors.white, size: 18.0),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create something meaningful',
                          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          'Choose a format, write your post and control who can view it.',
                          style: TextStyle(color: AppColors.muted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Composer Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        name: _anonymous ? 'Anonymous' : myName,
                        size: 42.0,
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
                            Text(community != null ? community.name : 'Public feed', style: const TextStyle(color: AppColors.muted, fontSize: 11.0)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'DRAFT',
                          style: TextStyle(color: AppColors.primary, fontSize: 9.0, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Be useful, kind and authentic', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                      Text('${_bodyController.text.length}/1200', style: const TextStyle(color: AppColors.muted, fontSize: 11.0)),
                    ],
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
                final IconData icon = type == 'Text'
                    ? Icons.description_outlined
                    : type == 'Question'
                        ? Icons.help_outline
                        : type == 'Poll'
                            ? Icons.analytics_outlined
                            : Icons.image_outlined;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: AppButton(
                      title: type,
                      tone: isSelected ? AppButtonTone.primary : AppButtonTone.secondary,
                      icon: icon,
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
            const SizedBox(height: 16.0),

            // Question Bounty Input
            if (_postType == 'Question') ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attach a coin bounty (Ask & Earn) 🏆', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14.0)),
                    const SizedBox(height: 4.0),
                    const Text('Give incentive for detailed, helpful answers. Best answer receives the bounty!', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
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
              const SizedBox(height: 16.0),
            ],

            // Poll Options Input
            if (_postType == 'Poll') ...[
              AppField(label: 'Option 1', placeholder: 'Option 1', controller: _pollOptionControllers[0]),
              const SizedBox(height: 8.0),
              AppField(label: 'Option 2', placeholder: 'Option 2', controller: _pollOptionControllers[1]),
              const SizedBox(height: 16.0),
            ],

            // Image Preview Card
            if (_postType == 'Image' && _imageFile != null) ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_imageFile!.path),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: const Text(
                            'Tap to change image',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],

            // Anonymous Switch Row
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Post anonymously', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2.0),
                        Text('Your identity remains private to other members.', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _anonymous,
                    onChanged: (val) => setState(() => _anonymous = val),
                    activeColor: AppColors.primary,
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

            if (_visibility == 'private') ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Set unlock price (Tiered Pricing) 🪙', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14.0)),
                    const SizedBox(height: 4.0),
                    const Text('Set the price in coins users must pay to unlock. Allowed range: 5 to 500 coins.', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                    const SizedBox(height: 8.0),
                    AppField(
                      label: 'Unlock Price (Coins)',
                      placeholder: 'Default is 5 coins',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
            ],

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
