import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppSearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final TextEditingController? controller;

  const AppSearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Search people, communities and posts',
    this.controller,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      alignment: Alignment.center,
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 20.0,
            color: AppColors.muted,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15.0,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15.0,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}
