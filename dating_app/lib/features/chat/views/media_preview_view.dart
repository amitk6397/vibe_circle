import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';

class MediaPreviewView extends StatefulWidget {
  const MediaPreviewView({super.key});

  @override
  State<MediaPreviewView> createState() => _MediaPreviewViewState();
}

class _MediaPreviewViewState extends State<MediaPreviewView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedFile;
  String _mimeType = 'image/jpeg';
  int _fileSize = 0;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    final file = args?['file'] as XFile?;
    if (file != null) {
      _selectedFile = file;
      _loadDetails(file);
    }
  }

  void _loadDetails(XFile file) async {
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _fileSize = bytes.length;
        _mimeType = file.path.endsWith('.png') ? 'image/png' : 'image/jpeg';
      });
    }
  }

  void _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _selectedFile = file;
        });
        _loadDetails(file);
      }
    } catch (e) {
      Get.snackbar('Picker Error', e.toString());
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Media preview',
        subtitle: 'Review a local image or file',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedFile != null) ...[
              AppCard(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.file(
                        File(_selectedFile!.path),
                        height: 240.0,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      _selectedFile!.name,
                      style: AppTextStyles.h2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '$_mimeType · ${_formatFileSize(_fileSize)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                height: 240.0,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_upload_outlined, size: 64.0, color: AppColors.primary),
                    SizedBox(height: 12.0),
                    Text('Choose media to preview', style: AppTextStyles.h2),
                    SizedBox(height: 6.0),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Images and files stay local in this UI prototype.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20.0),

            AppButton(
              title: _selectedFile != null ? 'Choose another image' : 'Choose an image',
              onPressed: _pickImage,
            ),
            const SizedBox(height: 10.0),
            AppButton(
              title: 'Choose a file',
              tone: AppButtonTone.secondary,
              onPressed: () {
                // Mock mock document pick
                Get.snackbar('Mock pick', 'Documents are mock selected for UI prototype.');
              },
            ),
            const SizedBox(height: 10.0),

            if (_selectedFile != null)
              AppButton(
                title: 'Close preview',
                tone: AppButtonTone.secondary,
                onPressed: () => Get.back(),
              ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
