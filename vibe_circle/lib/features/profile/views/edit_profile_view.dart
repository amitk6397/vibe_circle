import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
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
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _avatarFile = file);
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

      final updatedProfile = currentProfile.copyWith(
        name: name,
        username: username,
        bio: bio,
        city: _cityController.text.trim(),
        avatarUrl: _avatarFile != null ? _avatarFile!.path : currentProfile.avatarUrl,
      );

      // Save via API
      await _userRepo.updateProfile(updatedProfile.toJson());

      // Update local state
      _authController.updateProfile(updatedProfile);
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
                  else
                    AppAvatar(
                      name: _nameController.text,
                      avatarUrl: _authController.profile.value?.avatarUrl,
                      size: 90.0,
                    ),
                  const SizedBox(height: 10.0),
                  AppButton(
                    title: 'Change photo',
                    compact: true,
                    tone: AppButtonTone.secondary,
                    onPressed: _pickAvatar,
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
            const SizedBox(height: 12.0),
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

