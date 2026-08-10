import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NoteEditor extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const NoteEditor({
    super.key,
    required this.controller,
    required this.label,
  });

  void _insertText(String prefix, [String suffix = '']) {
    final text = controller.text;
    final selection = controller.selection;
    
    int start = selection.start;
    int end = selection.end;

    // If there is no active selection, default to the end of the text
    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    final selectedText = text.substring(start, end);
    final replacement = '$prefix$selectedText$suffix';

    controller.text = text.replaceRange(start, end, replacement);
    
    // Position cursor after the inserted text or inside the tags
    final newCursorPos = start + prefix.length + selectedText.length;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Mendukung Markdown',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Formatting Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppConstants.borderRadius),
              topRight: Radius.circular(AppConstants.borderRadius),
            ),
            border: Border(
              top: BorderSide(color: AppColors.border),
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              _buildToolbarButton(
                icon: Icons.format_bold_rounded,
                tooltip: 'Tebal (Bold)',
                onPressed: () => _insertText('**', '**'),
              ),
              _buildToolbarButton(
                icon: Icons.format_italic_rounded,
                tooltip: 'Miring (Italic)',
                onPressed: () => _insertText('*', '*'),
              ),
              _buildToolbarButton(
                icon: Icons.format_list_bulleted_rounded,
                tooltip: 'Daftar Bullet (Bullet List)',
                onPressed: () => _insertText('\n- '),
              ),
              _buildToolbarButton(
                icon: Icons.playlist_add_check_rounded,
                tooltip: 'Checklist',
                onPressed: () => _insertText('\n- [ ] '),
              ),
            ],
          ),
        ),

        // Text Area
        TextFormField(
          controller: controller,
          maxLines: 8,
          style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Tulis alasan entry, analisa market, atau emosi saat trading di sini...',
            fillColor: AppColors.surface,
            filled: true,
            contentPadding: EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.borderRadius),
                bottomRight: Radius.circular(AppConstants.borderRadius),
              ),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.borderRadius),
                bottomRight: Radius.circular(AppConstants.borderRadius),
              ),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.borderRadius),
                bottomRight: Radius.circular(AppConstants.borderRadius),
              ),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: AppColors.textSecondary),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
