import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/note_model.dart';
import '../../theme/app_theme.dart';

/// Professional Notion-style Image & Photo Block for AuraNotes.
/// Supports local PC photo upload, Web URLs, captions, and replacement.
class ImageBlockWidget extends StatefulWidget {
  final BlockItem block;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const ImageBlockWidget({
    super.key,
    required this.block,
    required this.isDark,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends State<ImageBlockWidget> {
  final TextEditingController _urlCtrl = TextEditingController();
  late TextEditingController _captionCtrl;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.block.caption ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromPC() async {
    try {
      final res = await FilePicker.pickFiles(
        dialogTitle: 'Select Photo or Image from PC',
        type: FileType.image,
      );

      if (res.isNotEmpty && res.first.path != null) {
        setState(() {
          widget.block.content = res.first.path!;
        });
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  void _setImageUrl() {
    final url = _urlCtrl.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        widget.block.content = url;
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final path = widget.block.content.trim();

    // 1. Empty State: Notion Upload Card
    if (path.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfSec(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_outlined, size: 20, color: AppTheme.accentCyan),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Photo or Image',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.txtPrimary(isDark),
                      ),
                    ),
                    Text(
                      'Upload from your PC or paste web image link',
                      style: TextStyle(fontSize: 11, color: AppTheme.txtTertiary(isDark)),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _pickImageFromPC,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  ),
                  icon: const Icon(Icons.file_upload_outlined, size: 15),
                  label: const Text('Choose File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // URL Input row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surf(isDark),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border(isDark)),
                    ),
                    child: TextField(
                      controller: _urlCtrl,
                      style: TextStyle(fontSize: 12, color: AppTheme.txtPrimary(isDark)),
                      decoration: InputDecoration(
                        hintText: 'https://example.com/diagram.png',
                        hintStyle: TextStyle(fontSize: 12, color: AppTheme.txtTertiary(isDark)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.only(top: 8),
                      ),
                      onSubmitted: (_) => _setImageUrl(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _setImageUrl,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border(isDark)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Embed URL',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.txtPrimary(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Rendered Image Display with Hover Controls & Caption
    final isLocalFile = File(path).existsSync() || (!path.startsWith('http://') && !path.startsWith('https://'));

    Widget imageWidget;
    if (isLocalFile && File(path).existsSync()) {
      imageWidget = Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => _buildErrorBox(isDark),
      );
    } else {
      imageWidget = Image.network(
        path,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentCyan),
          );
        },
        errorBuilder: (ctx, err, stack) => _buildErrorBox(isDark),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 520),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F1117) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border(isDark)),
                    ),
                    child: Center(child: imageWidget),
                  ),
                ),

                // Floating Action Controls on Hover
                if (_isHovered)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Replace Photo',
                            child: InkWell(
                              onTap: _pickImageFromPC,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.sync_rounded, size: 15, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Delete Photo Block',
                            child: InkWell(
                              onTap: widget.onDelete,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFF87171)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Optional Caption Input
            TextField(
              controller: _captionCtrl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.txtTertiary(isDark),
                fontStyle: FontStyle.italic,
              ),
              decoration: InputDecoration(
                hintText: 'Add an optional image caption...',
                hintStyle: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.txtTertiary(isDark).withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                widget.block.caption = val;
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox(bool isDark) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFFF87171)),
          const SizedBox(height: 8),
          Text(
            'Unable to load photo',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.txtPrimary(isDark)),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: _pickImageFromPC,
            child: const Text(
              'Click to choose another photo from PC',
              style: TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
