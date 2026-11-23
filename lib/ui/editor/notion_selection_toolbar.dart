import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../theme/app_theme.dart';
import 'rich_markdown_controller.dart';

/// Floating Glassmorphic Contextual Text Toolbar (Notion-Style).
/// Appears when any word/text is selected in the block editor.
class NotionSelectionToolbar extends StatelessWidget {
  final RichMarkdownTextController controller;
  final BlockItem block;
  final bool isDark;
  final VoidCallback onChanged;
  final ValueChanged<BlockType> onTurnInto;
  final VoidCallback onInsertImage;
  final VoidCallback onDeleteBlock;

  const NotionSelectionToolbar({
    super.key,
    required this.controller,
    required this.block,
    required this.isDark,
    required this.onChanged,
    required this.onTurnInto,
    required this.onInsertImage,
    required this.onDeleteBlock,
  });

  void _showLinkDialog(BuildContext context) {
    final linkCtrl = TextEditingController(text: 'https://');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfSec(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.border(isDark)),
        ),
        title: Row(
          children: [
            const Icon(Icons.link_rounded, color: AppTheme.accentCyan, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Web Link',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(isDark)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter web destination URL for selected text:',
              style: TextStyle(fontSize: 12, color: AppTheme.txtSecondary(isDark)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: linkCtrl,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: AppTheme.txtPrimary(isDark)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surf(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.border(isDark)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.txtSecondary(isDark))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.insertLink(linkCtrl.text);
              onChanged();
            },
            child: const Text('Insert Link', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xF2141824) : const Color(0xF7FFFFFF),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Turn Into Block Selector
            PopupMenuButton<BlockType>(
              tooltip: 'Turn into Block',
              offset: const Offset(0, 26),
              color: AppTheme.surfSec(isDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.border(isDark)),
              ),
              onSelected: onTurnInto,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getBlockTypeLabel(block.type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down_rounded, size: 14, color: AppTheme.txtTertiary(isDark)),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [
                _buildTurnIntoItem(BlockType.heading1, 'Heading 1', Icons.title_rounded),
                _buildTurnIntoItem(BlockType.heading2, 'Heading 2', Icons.format_size_rounded),
                _buildTurnIntoItem(BlockType.heading3, 'Heading 3', Icons.short_text_rounded),
                _buildTurnIntoItem(BlockType.paragraph, 'Text (Paragraph)', Icons.text_fields_rounded),
                _buildTurnIntoItem(BlockType.todo, 'To-do item', Icons.check_box_outlined),
                _buildTurnIntoItem(BlockType.bullet, 'Bulleted list', Icons.format_list_bulleted_rounded),
                _buildTurnIntoItem(BlockType.code, 'Code block', Icons.code_rounded),
                _buildTurnIntoItem(BlockType.dryRunTrace, 'Dry-Run Trace', Icons.account_tree_rounded),
                _buildTurnIntoItem(BlockType.callout, 'Callout Banner', Icons.lightbulb_outline_rounded),
                _buildTurnIntoItem(BlockType.quote, 'Quote', Icons.format_quote_rounded),
              ],
            ),

            _buildVerticalDivider(),

            // Bold (B) Toggle
            _buildToolbarBtn(
              tooltip: 'Bold (Toggle **)',
              child: const Text('B', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
              onTap: () {
                controller.toggleBold();
                onChanged();
              },
            ),

            // Italic (I) Toggle
            _buildToolbarBtn(
              tooltip: 'Italic (Toggle *)',
              child: const Text('I', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700)),
              onTap: () {
                controller.toggleItalic();
                onChanged();
              },
            ),

            // Strikethrough (S) Toggle
            _buildToolbarBtn(
              tooltip: 'Strikethrough (Toggle ~~)',
              child: const Icon(Icons.format_strikethrough_rounded, size: 14),
              onTap: () {
                controller.toggleStrikethrough();
                onChanged();
              },
            ),

            // Inline Code (<>) Toggle
            _buildToolbarBtn(
              tooltip: 'Inline Code (Toggle `)',
              child: const Icon(Icons.code_rounded, size: 14),
              onTap: () {
                controller.toggleCode();
                onChanged();
              },
            ),

            // Link Adding Feature
            _buildToolbarBtn(
              tooltip: 'Add Link (URL)',
              child: const Icon(Icons.link_rounded, size: 14),
              onTap: () => _showLinkDialog(context),
            ),

            // Photo / Image Adding Feature
            _buildToolbarBtn(
              tooltip: 'Insert Photo / Image',
              child: const Icon(Icons.image_outlined, size: 14, color: AppTheme.accentCyan),
              onTap: onInsertImage,
            ),

            _buildVerticalDivider(),

            // Delete Selection
            _buildToolbarBtn(
              tooltip: 'Delete Selection',
              child: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFF87171)),
              onTap: () {
                controller.deleteSelection();
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarBtn({
    required String tooltip,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: child,
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
    );
  }

  String _getBlockTypeLabel(BlockType type) {
    switch (type) {
      case BlockType.heading1:
        return 'Heading 1';
      case BlockType.heading2:
        return 'Heading 2';
      case BlockType.heading3:
        return 'Heading 3';
      case BlockType.todo:
        return 'To-do';
      case BlockType.bullet:
        return 'Bullet List';
      case BlockType.code:
        return 'Code';
      case BlockType.dryRunTrace:
        return 'Dry-Run';
      case BlockType.callout:
        return 'Callout';
      case BlockType.quote:
        return 'Quote';
      case BlockType.paragraph:
      default:
        return 'Text';
    }
  }

  PopupMenuItem<BlockType> _buildTurnIntoItem(BlockType type, String label, IconData icon) {
    return PopupMenuItem<BlockType>(
      value: type,
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.accentCyan),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
