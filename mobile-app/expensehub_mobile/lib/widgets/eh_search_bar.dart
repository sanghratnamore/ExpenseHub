import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EhSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const EhSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  State<EhSearchBar> createState() => _EhSearchBarState();
}

class _EhSearchBarState extends State<EhSearchBar> {
  final FocusNode focusNode = FocusNode();

  bool hasText = false;

  @override
  void initState() {
    super.initState();

    widget.controller?.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleTextChange);
    focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final value = widget.controller?.text ?? '';

    if (hasText != value.isNotEmpty) {
      setState(() {
        hasText = value.isNotEmpty;
      });
    }
  }

  void clearSearch() {
    widget.controller?.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();

    setState(() {
      hasText = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused
              ? AppColors.primary.withValues(alpha: 0.55)
              : Colors.grey.shade300,
          width: isFocused ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? AppColors.primary.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isFocused ? 22 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: focusNode,
        onChanged: widget.onChanged,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: clearSearch,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}