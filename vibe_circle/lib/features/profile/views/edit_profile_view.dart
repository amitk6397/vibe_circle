import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_urls.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/user_repository.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final AuthController _authController = Get.find<AuthController>();
  final UserRepository _userRepo = UserRepository();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;

  XFile? _avatarFile;
  bool _removeAvatar = false;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final profile = _authController.profile.value;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
  }

  void _pickAvatar() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _avatarFile = file;
        _removeAvatar = false;
      });
    }
  }

  void _save() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      setState(() => _error = 'Name and username are required.');
      return;
    }

    if (bio.length > 240) {
      setState(() => _error = 'Bio must be 240 characters or less.');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      final currentProfile = _authController.profile.value;
      if (currentProfile == null) return;

      String? avatarUrl = _removeAvatar ? null : currentProfile.avatarUrl;

      // 1. Upload photo to server if a new one was picked
      if (_avatarFile != null) {
        final uploadResp = await NetworkApiService.instance.uploadFile(
          ApiUrls.uploads,
          File(_avatarFile!.path),
        );
        if (uploadResp.data != null && uploadResp.data['url'] != null) {
          avatarUrl = uploadResp.data['url'] as String;
        }
      }

      // 2. Build clean payload matching backend ProfileUpdate schema
      final Map<String, dynamic> payload = {
        'name': name,
        'username': username,
        'bio': bio,
        'city': _cityController.text.trim(),
        'avatar_url': avatarUrl,
      };

      // 3. Save via API
      final updatedUser = await _userRepo.updateProfile(payload);

      // 4. Update local state
      _authController.updateProfile(updatedUser);

      Get.back();
      Get.snackbar(
        'Profile updated 🎉',
        'Your profile changes have been saved.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Edit profile',
        subtitle: 'Email remains private.',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar picker
            Center(
              child: Column(
                children: [
                  if (_avatarFile != null)
                    CircleAvatar(
                      radius: 45.0,
                      backgroundImage: FileImage(File(_avatarFile!.path)),
                    )
                  else if (_removeAvatar)
                    AppAvatar(
                      name: _nameController.text.isNotEmpty ? _nameController.text : 'User',
                      size: 90.0,
                    )
                  else
                    AppAvatar(
                      name: _nameController.text.isNotEmpty ? _nameController.text : 'User',
                      avatarUrl: _authController.profile.value?.avatarUrl,
                      size: 90.0,
                    ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppButton(
                        title: 'Change photo',
                        compact: true,
                        tone: AppButtonTone.secondary,
                        onPressed: _pickAvatar,
                      ),
                      if (_avatarFile != null || (!_removeAvatar && _authController.profile.value?.avatarUrl != null && _authController.profile.value!.avatarUrl!.isNotEmpty)) ...[
                        const SizedBox(width: 8.0),
                        AppButton(
                          title: 'Remove photo',
                          compact: true,
                          tone: AppButtonTone.ghost,
                          onPressed: () {
                            setState(() {
                              _avatarFile = null;
                              _removeAvatar = true;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            AppField(
              label: 'Name',
              controller: _nameController,
            ),
            const SizedBox(height: 12.0),
            AppField(
              label: 'Username',
              controller: _usernameController,
            ),
            const SizedBox(height: 12.0),
            AppField(
              label: 'Bio',
              controller: _bioController,
              multiline: true,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text(
                '${_bioController.text.length}/240 characters',
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
            ),
            AppField(
              label: 'City (optional)',
              controller: _cityController,
            ),
            const SizedBox(height: 16.0),

            if (_error.isNotEmpty) ...[
              Text(_error, style: const TextStyle(color: AppColors.danger, fontSize: 12.0)),
              const SizedBox(height: 12.0),
            ],

            AppButton(
              title: _saving ? 'Saving changes...' : 'Save changes',
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}

