import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_icons.dart';
import 'code_syntax_controller.dart';
import 'dry_run_trace_widget.dart';
import 'rich_markdown_controller.dart';
import 'notion_selection_toolbar.dart';
import 'image_block_widget.dart';

class BlockEditorView extends StatefulWidget {
  const BlockEditorView({super.key});

  @override
  State<BlockEditorView> createState() => _BlockEditorViewState();
}

class _BlockEditorViewState extends State<BlockEditorView> {
  final TextEditingController _titleCtrl = TextEditingController();
  String? _lastNoteId;
  final Map<String, GlobalKey> _blockKeys = {};
  String? _highlightedBlockId;

  Widget _buildOutlineButton(BuildContext context, NoteDocument note, StorageService storage, bool isDark) {
    final headings = note.blocks.where((b) =>
      b.type == BlockType.heading1 ||
      b.type == BlockType.heading2 ||
      b.type == BlockType.heading3
    ).toList();

    return PopupMenuButton<String>(
      tooltip: 'Document Outline (Jump to Section)',
      offset: const Offset(0, 28),
      color: AppTheme.surfSec(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.border(isDark)),
      ),
      onSelected: (blockId) => storage.scrollToBlock(blockId),
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              const Icon(Icons.format_list_bulleted_rounded, size: 13, color: AppTheme.accentCyan),
              const SizedBox(width: 6),
              Text(
                'DOCUMENT OUTLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                ),
              ),
            ],
          ),
        ),
        for (final h in headings)
          PopupMenuItem<String>(
            value: h.id,
            child: Padding(
              padding: EdgeInsets.only(
                left: h.type == BlockType.heading1 ? 0 : (h.type == BlockType.heading2 ? 8 : 16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: h.type == BlockType.heading1 ? 13 : (h.type == BlockType.heading2 ? 11.5 : 10),
                    color: h.type == BlockType.heading1
                        ? AppTheme.accentCyan
                        : (h.type == BlockType.heading2 ? AppTheme.accentCyan.withValues(alpha: 0.65) : AppTheme.txtTertiary(isDark)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.content.isNotEmpty ? h.content : 'Section',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: h.type == BlockType.heading1 ? FontWeight.w600 : FontWeight.w400,
                        color: AppTheme.txtPrimary(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: AppTheme.surf(isDark),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border(isDark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_list_bulleted_rounded, size: 13.5, color: AppTheme.accentCyan),
            const SizedBox(width: 5),
            Text(
              'Outline (${headings.length})',
              style: TextStyle(fontSize: 11.5, color: AppTheme.txtSecondary(isDark), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildCoverMenuItem(String value, String label, LinearGradient gradient) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDeleteDocButton(BuildContext context, NoteDocument note, StorageService storage) {
    return Tooltip(
      message: 'Delete this document',
      child: InkWell(
        onTap: () => _confirmDeleteDocument(context, storage, note),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFF87171)),
              SizedBox(width: 4),
              Text(
                'Delete',
                style: TextStyle(fontSize: 11.5, color: Color(0xFFF87171), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteDocument(BuildContext context, StorageService storage, NoteDocument note) {
    final isDark = storage.isDarkMode;
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
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 20),
            const SizedBox(width: 8),
            Text(
              'Delete Document?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(isDark)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"?\nThis document and all its contents will be permanently deleted.',
          style: TextStyle(fontSize: 13, color: AppTheme.txtSecondary(isDark), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.txtSecondary(isDark))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              storage.deleteNote(note.id);
            },
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final note = storage.activeNote;
    final isDark = storage.isDarkMode;

    if (note == null) {
      return Scaffold(
        backgroundColor: AppTheme.bg(isDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_alt_outlined, size: 48, color: AppTheme.txtTertiary(isDark)),
              const SizedBox(height: 14),
              Text(
                'No Document Selected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.txtSecondary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => storage.createNote(icon: 'document'),
                icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.accentCyan),
                label: const Text('Create New Page',
                    style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    if (_lastNoteId != note.id) {
      _lastNoteId = note.id;
      _titleCtrl.text = note.title;
    }

    // Scroll to block target if requested
    final jumpId = storage.jumpTargetBlockId;
    if (jumpId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        storage.clearJumpTarget();
        final key = _blockKeys[jumpId];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
            alignment: 0.08,
          );
          if (mounted) {
            setState(() => _highlightedBlockId = jumpId);
            Future.delayed(const Duration(milliseconds: 1400), () {
              if (mounted) setState(() => _highlightedBlockId = null);
            });
          }
        }
      });
    }

    // Cover Gradient & Theme Glow
    LinearGradient coverGradient;
    Color glowColor;
    switch (note.coverGradient) {
      case 'violet':
        coverGradient = AppTheme.auraVioletGradient;
        glowColor = AppTheme.accentViolet;
        break;
      case 'amber':
        coverGradient = AppTheme.auraAmberGradient;
        glowColor = AppTheme.accentAmber;
        break;
      case 'emerald':
        coverGradient = const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)],
        );
        glowColor = AppTheme.accentEmerald;
        break;
      case 'cyan':
      default:
        coverGradient = AppTheme.auraCyanGradient;
        glowColor = AppTheme.accentCyan;
        break;
    }

    // Breadcrumbs trail
    final breadcrumbs = storage.getBreadcrumbTrail(note.id);
    final codeBlocksCount = note.blocks.where((b) => b.type == BlockType.code).length;
    final dryRunCount = note.blocks.where((b) => b.type == BlockType.dryRunTrace).length;

    return Scaffold(
      backgroundColor: AppTheme.bg(isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Sleek Breadcrumb Navigation Header directly above Document Card (No Navbar Nesting!)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.surfSec(isDark),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppTheme.border(isDark)),
                  ),
                  child: Row(
                    children: [
                      // Workspace Root Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_special_rounded, size: 12, color: AppTheme.accentCyan),
                            const SizedBox(width: 4),
                            Text(
                              'Aura Workspace',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.txtTertiary(isDark)),
                      const SizedBox(width: 6),

                      // Clickable Breadcrumbs Trail
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < breadcrumbs.length; i++) ...[
                                InkWell(
                                  onTap: () => storage.setActiveNote(breadcrumbs[i].id),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppIcons.buildModernIcon(
                                          breadcrumbs[i].icon,
                                          size: 12.5,
                                          color: i == breadcrumbs.length - 1
                                              ? (isDark ? AppTheme.accentCyan : const Color(0xFF0284C7))
                                              : AppTheme.txtTertiary(isDark),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          breadcrumbs[i].title,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: i == breadcrumbs.length - 1
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: i == breadcrumbs.length - 1
                                                ? AppTheme.txtPrimary(isDark)
                                                : AppTheme.txtSecondary(isDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (i < breadcrumbs.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Icon(Icons.chevron_right_rounded,
                                        size: 13, color: AppTheme.txtTertiary(isDark)),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Outline Popup Menu
                      if (note.blocks.any((b) => b.type == BlockType.heading1 || b.type == BlockType.heading2 || b.type == BlockType.heading3)) ...[
                        _buildOutlineButton(context, note, storage, isDark),
                        const SizedBox(width: 6),
                      ],
                      // Delete Document Button
                      _buildDeleteDocButton(context, note, storage),
                    ],
                  ),
                ),

                // 2. Ultra-Modern Premium Hero Card (Layered Specular Sheen & Floating Controls)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 145,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: coverGradient,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: isDark ? 0.32 : 0.22),
                            blurRadius: 32,
                            spreadRadius: -4,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Specular Glass Sheen Overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.26),
                                    Colors.white.withValues(alpha: 0.06),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.18),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),

                          // Top Highlight Horizon
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.7),
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Floating Glassmorphic Pill Controls inside Cover
                          Positioned(
                            top: 10,
                            right: 12,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Block & Engine Stats Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.widgets_outlined, size: 12, color: Colors.white70),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${note.blocks.length} Blocks',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      if (codeBlocksCount > 0) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.code_rounded, size: 12, color: Color(0xFF67E8F9)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$codeBlocksCount Code',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF67E8F9),
                                          ),
                                        ),
                                      ],
                                      if (dryRunCount > 0) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.account_tree_rounded, size: 12, color: Color(0xFFFDE047)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$dryRunCount Dry-Run',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFFDE047),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Cover Palette Selector Pill
                                PopupMenuButton<String>(
                                  tooltip: 'Change Cover Theme',
                                  offset: const Offset(0, 32),
                                  color: AppTheme.surfSec(isDark),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: AppTheme.border(isDark)),
                                  ),
                                  icon: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.palette_rounded, size: 13, color: Colors.white),
                                        SizedBox(width: 5),
                                        Text(
                                          'Cover',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onSelected: (val) {
                                    note.coverGradient = val;
                                    storage.updateNote(note, immediate: true);
                                  },
                                  itemBuilder: (ctx) => [
                                    _buildCoverMenuItem('cyan', 'Electric Cyan', AppTheme.auraCyanGradient),
                                    _buildCoverMenuItem('violet', 'Aura Violet', AppTheme.auraVioletGradient),
                                    _buildCoverMenuItem('amber', 'Sunset Amber', AppTheme.auraAmberGradient),
                                    _buildCoverMenuItem('emerald', 'Emerald Matrix', const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Floating Premium 54x54 Glassmorphic Icon Badge
                    Positioned(
                      bottom: -22,
                      left: 20,
                      child: PopupMenuButton<String>(
                        tooltip: 'Change Document Icon',
                        offset: const Offset(0, 58),
                        color: AppTheme.surfSec(isDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.border(isDark)),
                        ),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF141822) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.1),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AppIcons.buildModernIcon(
                              note.icon,
                              size: 26,
                              color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        onSelected: (key) {
                          note.icon = key;
                          storage.updateNote(note, immediate: true);
                        },
                        itemBuilder: (ctx) => [
                          {'key': 'document', 'label': 'Document', 'icon': AppIcons.document},
                          {'key': 'code', 'label': 'Algorithm / Code', 'icon': AppIcons.code},
                          {'key': 'terminal', 'label': 'Terminal / CLI', 'icon': AppIcons.terminal},
                          {'key': 'tree', 'label': 'Data Structures', 'icon': AppIcons.tree},
                          {'key': 'database', 'label': 'Database / SQL', 'icon': AppIcons.database},
                          {'key': 'architecture', 'label': 'System Architecture', 'icon': AppIcons.architecture},
                          {'key': 'target', 'label': 'Interview Sheet', 'icon': AppIcons.target},
                          {'key': 'book', 'label': 'Reference / Book', 'icon': AppIcons.book},
                        ].map((item) => PopupMenuItem(
                          value: item['key'] as String,
                          child: Row(
                            children: [
                              Icon(item['icon'] as IconData, size: 16, color: AppTheme.accentCyan),
                              const SizedBox(width: 10),
                              Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.txtPrimary(isDark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 38),

                // 3. Document Title
                TextField(
                  controller: _titleCtrl,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppTheme.txtPrimary(isDark),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Untitled...',
                    hintStyle: TextStyle(color: AppTheme.txtTertiary(isDark)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) {
                    note.title = val.isNotEmpty ? val : 'Untitled';
                    storage.updateNote(note, immediate: false, notify: true);
                  },
                ),

                const SizedBox(height: 16),

                // 4. Notion Blocks
                for (int i = 0; i < note.blocks.length; i++)
                  _NotionBlockRow(
                    key: _blockKeys.putIfAbsent(note.blocks[i].id, () => GlobalKey()),
                    block: note.blocks[i],
                    noteId: note.id,
                    isHighlighted: _highlightedBlockId == note.blocks[i].id,
                    onChanged: () => storage.updateNote(note, immediate: false, notify: false),
                    onDelete: () {
                      final blockId = note.blocks[i].id;
                      setState(() {
                        note.blocks.removeWhere((b) => b.id == blockId);
                      });
                      storage.updateNote(note, immediate: true);
                    },
                    onInsertAfter: (type) {
                      setState(() {
                        if (type == BlockType.subpage) {
                          final child = storage.createNote(
                            parentId: note.id,
                            title: 'Untitled Sub-Page',
                            icon: 'document',
                          );
                          note.blocks.insert(
                            i + 1,
                            BlockItem(
                              id: 'b_sub_${DateTime.now().millisecondsSinceEpoch}',
                              type: BlockType.subpage,
                              content: child.title,
                              subpageId: child.id,
                            ),
                          );
                        } else if (type == BlockType.dryRunTrace) {
                          note.blocks.insert(
                            i + 1,
                            BlockItem(
                              id: 'b_dry_${DateTime.now().millisecondsSinceEpoch}',
                              type: BlockType.dryRunTrace,
                              content: '1, 3, 4, 7, 8, 12',
                              tableData: [
                                ['Step', 'left', 'right', 'mid', 'nums[mid]', 'target', 'Action'],
                                ['1', '0', '5', '2', '4', '7', 'left = mid + 1'],
                                ['2', '3', '5', '4', '8', '7', 'right = mid - 1'],
                                ['3', '3', '3', '3', '7', '7', 'nums[mid] == target (Found at index 3!)'],
                              ],
                            ),
                          );
                        } else {
                          note.blocks.insert(
                            i + 1,
                            BlockItem(
                              id: 'b_${DateTime.now().millisecondsSinceEpoch}',
                              type: type,
                              content: '',
                              language: type == BlockType.code ? 'java' : 'dart',
                            ),
                          );
                        }
                      });
                      storage.updateNote(note, immediate: true);
                    },
                  ),

                // "+ Add a block below" at the end
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<BlockType>(
                    tooltip: 'Add block',
                    offset: const Offset(0, 24),
                    color: AppTheme.surfSec(isDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppTheme.border(isDark)),
                    ),
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: AppTheme.txtTertiary(isDark)),
                        const SizedBox(width: 4),
                        Text(
                          'Add a block below',
                          style: TextStyle(fontSize: 12, color: AppTheme.txtTertiary(isDark)),
                        ),
                      ],
                    ),
                    onSelected: (type) {
                      setState(() {
                        if (type == BlockType.subpage) {
                          final child = storage.createNote(
                            parentId: note.id,
                            title: 'Untitled Sub-Page',
                            icon: 'document',
                          );
                          note.blocks.add(
                            BlockItem(
                              id: 'b_sub_${DateTime.now().millisecondsSinceEpoch}',
                              type: BlockType.subpage,
                              content: child.title,
                              subpageId: child.id,
                            ),
                          );
                        } else if (type == BlockType.dryRunTrace) {
                          note.blocks.add(
                            BlockItem(
                              id: 'b_dry_${DateTime.now().millisecondsSinceEpoch}',
                              type: BlockType.dryRunTrace,
                              content: '1, 3, 4, 7, 8, 12',
                              tableData: [
                                ['Step', 'left', 'right', 'mid', 'nums[mid]', 'target', 'Action'],
                                ['1', '0', '5', '2', '4', '7', 'left = mid + 1'],
                                ['2', '3', '5', '4', '8', '7', 'right = mid - 1'],
                                ['3', '3', '3', '3', '7', '7', 'nums[mid] == target (Found at index 3!)'],
                              ],
                            ),
                          );
                        } else {
                          note.blocks.add(
                            BlockItem(
                              id: 'b_${DateTime.now().millisecondsSinceEpoch}',
                              type: type,
                              content: '',
                              language: type == BlockType.code ? 'java' : 'dart',
                            ),
                          );
                        }
                      });
                      storage.updateNote(note, immediate: true);
                    },
                    itemBuilder: (ctx) => _buildBlockTypeMenuItems(),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<PopupMenuEntry<BlockType>> _buildBlockTypeMenuItems() {
    return [
      const PopupMenuItem(
        value: BlockType.paragraph,
        child: _MenuItemRow(icon: Icons.text_fields_rounded, label: 'Text (Paragraph)'),
      ),
      const PopupMenuItem(
        value: BlockType.heading1,
        child: _MenuItemRow(icon: Icons.title_rounded, label: 'Heading 1'),
      ),
      const PopupMenuItem(
        value: BlockType.heading2,
        child: _MenuItemRow(icon: Icons.format_size_rounded, label: 'Heading 2'),
      ),
      const PopupMenuItem(
        value: BlockType.heading3,
        child: _MenuItemRow(icon: Icons.short_text_rounded, label: 'Heading 3'),
      ),
      const PopupMenuItem(
        value: BlockType.todo,
        child: _MenuItemRow(icon: Icons.check_box_outlined, label: 'To-do List'),
      ),
      const PopupMenuItem(
        value: BlockType.subpage,
        child: _MenuItemRow(
          icon: Icons.note_add_outlined,
          label: 'Sub-Page (Nested Document)',
          highlight: true,
        ),
      ),
      const PopupMenuItem(
        value: BlockType.code,
        child: _MenuItemRow(icon: Icons.code_rounded, label: 'Code Block (Syntax Highlighted)'),
      ),
      const PopupMenuItem(
        value: BlockType.image,
        child: _MenuItemRow(
          icon: Icons.image_outlined,
          label: 'Photo / Image (PC & URL)',
          highlight: true,
        ),
      ),
      const PopupMenuItem(
        value: BlockType.dryRunTrace,
        child: _MenuItemRow(
          icon: Icons.account_tree_rounded,
          label: 'Algorithm Dry-Run Trace (Visual)',
          highlight: true,
        ),
      ),
      const PopupMenuItem(
        value: BlockType.quote,
        child: _MenuItemRow(icon: Icons.format_quote_rounded, label: 'Quote'),
      ),
      const PopupMenuItem(
        value: BlockType.callout,
        child: _MenuItemRow(icon: Icons.lightbulb_outline_rounded, label: 'Callout Banner'),
      ),
      const PopupMenuItem(
        value: BlockType.bullet,
        child: _MenuItemRow(icon: Icons.format_list_bulleted_rounded, label: 'Bulleted List'),
      ),
      const PopupMenuItem(
        value: BlockType.divider,
        child: _MenuItemRow(icon: Icons.horizontal_rule_rounded, label: 'Divider'),
      ),
    ];
  }
}

class _MenuItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _MenuItemRow({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: highlight ? AppTheme.accentCyan : AppTheme.textSecondary,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
            color: highlight ? AppTheme.accentCyan : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _NotionBlockRow extends StatefulWidget {
  final BlockItem block;
  final String noteId;
  final bool isHighlighted;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final ValueChanged<BlockType> onInsertAfter;

  const _NotionBlockRow({
    super.key,
    required this.block,
    required this.noteId,
    this.isHighlighted = false,
    required this.onChanged,
    required this.onDelete,
    required this.onInsertAfter,
  });

  @override
  State<_NotionBlockRow> createState() => _NotionBlockRowState();
}

class _NotionBlockRowState extends State<_NotionBlockRow> {
  late TextEditingController _ctrl;
  bool _isHovered = false;
  bool _copied = false;
  bool _hasSelection = false;

  TextStyle _getBaseTextStyle(BlockType type, bool isDark) {
    switch (type) {
      case BlockType.heading1:
        return TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppTheme.txtPrimary(isDark),
          letterSpacing: -0.3,
        );
      case BlockType.heading2:
        return TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          letterSpacing: -0.2,
        );
      case BlockType.heading3:
        return TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
        );
      case BlockType.quote:
        return TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          height: 1.5,
        );
      case BlockType.callout:
        return TextStyle(
          fontSize: 13.5,
          color: AppTheme.txtPrimary(isDark),
          height: 1.45,
        );
      case BlockType.bullet:
      case BlockType.todo:
      case BlockType.paragraph:
      default:
        return TextStyle(
          fontSize: 14.5,
          color: AppTheme.txtPrimary(isDark),
          height: 1.55,
        );
    }
  }

  void _handleSelectionChange() {
    final hasSel = !_ctrl.selection.isCollapsed && _ctrl.selection.isValid;
    if (hasSel != _hasSelection) {
      setState(() {
        _hasSelection = hasSel;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.block.type == BlockType.code) {
      _ctrl = CodeSyntaxTextController(
        text: widget.block.content,
        language: widget.block.language.isNotEmpty ? widget.block.language : 'java',
      );
    } else {
      _ctrl = RichMarkdownTextController(
        text: widget.block.content,
        baseStyle: _getBaseTextStyle(widget.block.type, true),
        isDark: true,
      );
      _ctrl.addListener(_handleSelectionChange);
    }
  }

  @override
  void didUpdateWidget(covariant _NotionBlockRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.type == BlockType.code && _ctrl is CodeSyntaxTextController) {
      (_ctrl as CodeSyntaxTextController).updateLanguage(widget.block.language);
    }
    if (widget.block.type != BlockType.code && _ctrl is RichMarkdownTextController) {
      final isDark = context.read<StorageService>().isDarkMode;
      (_ctrl as RichMarkdownTextController).updateTheme(
        newBaseStyle: _getBaseTextStyle(widget.block.type, isDark),
        newIsDark: isDark,
      );
    }
    if (oldWidget.block.content != widget.block.content && _ctrl.text != widget.block.content) {
      _ctrl.text = widget.block.content;
    }
  }

  @override
  void dispose() {
    if (_ctrl is RichMarkdownTextController) {
      _ctrl.removeListener(_handleSelectionChange);
    }
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextStyle style,
    required String hintText,
    bool maxLinesNull = true,
    required bool isDark,
  }) {
    return TextField(
      controller: _ctrl,
      maxLines: maxLinesNull ? null : 1,
      style: style,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppTheme.txtTertiary(isDark)),
        border: InputBorder.none,
        isDense: true,
      ),
      onChanged: (val) {
        widget.block.content = val;
        widget.onChanged();
      },
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
              label: 'Bold (**)',
              onPressed: () {
                if (_ctrl is RichMarkdownTextController) {
                  (_ctrl as RichMarkdownTextController).toggleBold();
                  widget.block.content = _ctrl.text;
                  widget.onChanged();
                }
              },
            ),
            ContextMenuButtonItem(
              label: 'Italic (*)',
              onPressed: () {
                if (_ctrl is RichMarkdownTextController) {
                  (_ctrl as RichMarkdownTextController).toggleItalic();
                  widget.block.content = _ctrl.text;
                  widget.onChanged();
                }
              },
            ),
            ContextMenuButtonItem(
              label: 'Code (`)',
              onPressed: () {
                if (_ctrl is RichMarkdownTextController) {
                  (_ctrl as RichMarkdownTextController).toggleCode();
                  widget.block.content = _ctrl.text;
                  widget.onChanged();
                }
              },
            ),
            ...editableTextState.contextMenuButtonItems,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final storage = context.watch<StorageService>();
    final isDark = storage.isDarkMode;

    Widget contentWidget;

    switch (block.type) {
      case BlockType.heading1:
        contentWidget = _buildTextField(
          style: _getBaseTextStyle(BlockType.heading1, isDark),
          hintText: 'Heading 1',
          isDark: isDark,
        );
        break;

      case BlockType.heading2:
        contentWidget = _buildTextField(
          style: _getBaseTextStyle(BlockType.heading2, isDark),
          hintText: 'Heading 2',
          isDark: isDark,
        );
        break;

      case BlockType.heading3:
        contentWidget = _buildTextField(
          style: _getBaseTextStyle(BlockType.heading3, isDark),
          hintText: 'Heading 3',
          isDark: isDark,
        );
        break;

      case BlockType.todo:
        contentWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: block.isCompleted,
              activeColor: AppTheme.accentCyan,
              checkColor: Colors.black,
              side: BorderSide(color: AppTheme.txtTertiary(isDark), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) {
                block.isCompleted = val ?? false;
                widget.onChanged();
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTextField(
                style: TextStyle(
                  fontSize: 14,
                  decoration: block.isCompleted ? TextDecoration.lineThrough : null,
                  color: block.isCompleted ? AppTheme.txtTertiary(isDark) : AppTheme.txtPrimary(isDark),
                ),
                hintText: 'To-do item...',
                isDark: isDark,
              ),
            ),
          ],
        );
        break;

      case BlockType.image:
        contentWidget = ImageBlockWidget(
          block: block,
          isDark: isDark,
          onChanged: widget.onChanged,
          onDelete: widget.onDelete,
        );
        break;

      // Sub-page nested block
      case BlockType.subpage:
        contentWidget = InkWell(
          onTap: () {
            if (block.subpageId != null) {
              storage.setActiveNote(block.subpageId!);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfSec(isDark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border(isDark), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, size: 18, color: AppTheme.accentCyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.content.isNotEmpty ? block.content : 'Untitled Sub-Page',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.txtPrimary(isDark),
                        ),
                      ),
                      Text(
                        'Nested document • Click to open',
                        style: TextStyle(fontSize: 11, color: AppTheme.txtTertiary(isDark)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.txtTertiary(isDark)),
              ],
            ),
          ),
        );
        break;

      // Code Block with Vibrant Syntax Highlighting, Line Numbers, Mac Dots & Copy
      case BlockType.code:
        final lines = block.content.split('\n');
        final lineCount = lines.isEmpty ? 1 : lines.length;

        contentWidget = Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF21262D)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Mac Traffic Dots, Language selector and Copy button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFF161B22),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(9),
                    topRight: Radius.circular(9),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF21262D), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Mac Traffic Dots
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                    const SizedBox(width: 14),

                    // Language Selector Dropdown
                    PopupMenuButton<String>(
                      tooltip: 'Select Language',
                      offset: const Offset(0, 24),
                      color: AppTheme.surfSec(isDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.border(isDark)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.code_rounded, size: 12, color: AppTheme.accentCyan),
                            const SizedBox(width: 5),
                            Text(
                              block.language.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentCyan,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, size: 14, color: AppTheme.accentCyan),
                          ],
                        ),
                      ),
                      onSelected: (lang) {
                        block.language = lang;
                        if (_ctrl is CodeSyntaxTextController) {
                          (_ctrl as CodeSyntaxTextController).updateLanguage(lang);
                        }
                        widget.onChanged();
                      },
                      itemBuilder: (ctx) => [
                        'java', 'python', 'c++', 'javascript', 'typescript', 'dart', 'sql', 'bash', 'go', 'rust', 'html', 'css', 'json'
                      ]
                          .map((l) => PopupMenuItem(value: l, child: Text(l.toUpperCase(), style: const TextStyle(fontSize: 11))))
                          .toList(),
                    ),

                    const Spacer(),

                    // Copy Code Button with Feedback
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: block.content));
                        setState(() => _copied = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _copied = false);
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              _copied ? Icons.check_rounded : Icons.copy_rounded,
                              size: 12,
                              color: _copied ? AppTheme.accentEmerald : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _copied ? 'Copied' : 'Copy',
                              style: TextStyle(
                                fontSize: 11,
                                color: _copied ? AppTheme.accentEmerald : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Code Body with Line Number Gutter + High-Contrast Syntax Highlighting
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line numbers column
                    Container(
                      padding: const EdgeInsets.only(left: 10, right: 8, top: 2),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Color(0xFF21262D), width: 1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int i = 1; i <= lineCount; i++)
                            Text(
                              '$i',
                              style: const TextStyle(
                                fontFamily: 'Consolas',
                                fontSize: 12,
                                height: 1.5,
                                color: Color(0xFF484F58),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // High-contrast syntax highlighted text field
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        maxLines: null,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 12.5,
                          height: 1.5,
                          color: Color(0xFFE2E8F0),
                        ),
                        decoration: InputDecoration(
                          hintText: '// Paste or write code snippet...',
                          hintStyle: TextStyle(color: AppTheme.txtTertiary(isDark)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(top: 2, bottom: 2, right: 12),
                        ),
                        onChanged: (val) {
                          block.content = val;
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case BlockType.quote:
        contentWidget = Container(
          padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppTheme.accentCyan, width: 2.5)),
          ),
          child: _buildTextField(
            style: _getBaseTextStyle(BlockType.quote, isDark),
            hintText: 'Quote...',
            isDark: isDark,
          ),
        );
        break;

      case BlockType.callout:
        contentWidget = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfSec(isDark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcons.buildModernIcon(block.calloutEmoji, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  style: _getBaseTextStyle(BlockType.callout, isDark),
                  hintText: 'Callout text...',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );
        break;

      case BlockType.divider:
        contentWidget = Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(height: 1, color: AppTheme.border(isDark), thickness: 1),
        );
        break;

      case BlockType.bullet:
        contentWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, right: 10, left: 4),
              child: Icon(Icons.circle, size: 5, color: AppTheme.accentCyan),
            ),
            Expanded(
              child: _buildTextField(
                style: _getBaseTextStyle(BlockType.bullet, isDark),
                hintText: 'List item...',
                isDark: isDark,
              ),
            ),
          ],
        );
        break;

      case BlockType.dryRunTrace:
        contentWidget = DryRunTraceWidget(
          block: block,
          onChanged: widget.onChanged,
        );
        break;

      case BlockType.paragraph:
      default:
        contentWidget = _buildTextField(
          style: _getBaseTextStyle(BlockType.paragraph, isDark),
          hintText: 'Type something, or / for block...',
          isDark: isDark,
        );
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left gutter with 54px width for +, direct trash, and options
            SizedBox(
              width: 54,
              child: IgnorePointer(
                ignoring: !_isHovered,
                child: AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 120),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // + Add block below
                      PopupMenuButton<BlockType>(
                        tooltip: 'Add block below',
                        padding: EdgeInsets.zero,
                        splashRadius: 10,
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        offset: const Offset(0, 20),
                        color: AppTheme.surfSec(isDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppTheme.border(isDark)),
                        ),
                        onSelected: widget.onInsertAfter,
                        itemBuilder: (ctx) => _BlockEditorViewState._buildBlockTypeMenuItems(),
                        child: Container(
                          width: 16,
                          height: 20,
                          alignment: Alignment.center,
                          child: Icon(Icons.add_rounded, size: 14, color: AppTheme.txtTertiary(isDark)),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Direct 1-Click Delete block
                      Tooltip(
                        message: 'Delete block',
                        child: InkWell(
                          onTap: widget.onDelete,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 16,
                            height: 20,
                            alignment: Alignment.center,
                            child: const Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFF87171)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // ⋮⋮ Turn into / delete
                      PopupMenuButton<String>(
                        tooltip: 'Block options',
                        padding: EdgeInsets.zero,
                        splashRadius: 10,
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        offset: const Offset(0, 20),
                        color: AppTheme.surfSec(isDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppTheme.border(isDark)),
                        ),
                        onSelected: (val) {
                          if (val == 'delete') {
                            widget.onDelete();
                          } else if (val == 'h1') {
                            block.type = BlockType.heading1;
                            widget.onChanged();
                          } else if (val == 'h2') {
                            block.type = BlockType.heading2;
                            widget.onChanged();
                          } else if (val == 'todo') {
                            block.type = BlockType.todo;
                            widget.onChanged();
                          } else if (val == 'code') {
                            block.type = BlockType.code;
                            widget.onChanged();
                          } else if (val == 'dry') {
                            block.type = BlockType.dryRunTrace;
                            if (block.tableData.isEmpty || block.tableData.length < 2) {
                              block.tableData = [
                                ['Step', 'left', 'right', 'mid', 'nums[mid]', 'target', 'Action'],
                                ['1', '0', '5', '2', '4', '7', 'left = mid + 1'],
                                ['2', '3', '5', '4', '8', '7', 'right = mid - 1'],
                                ['3', '3', '3', '3', '7', '7', 'nums[mid] == target (Found at index 3!)'],
                              ];
                            }
                            widget.onChanged();
                          } else if (val == 'quote') {
                            block.type = BlockType.quote;
                            widget.onChanged();
                          } else if (val == 'callout') {
                            block.type = BlockType.callout;
                            widget.onChanged();
                          } else if (val == 'image') {
                            block.type = BlockType.image;
                            widget.onChanged();
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'h1', child: Text('Turn into Heading 1', style: TextStyle(fontSize: 12))),
                          const PopupMenuItem(value: 'h2', child: Text('Turn into Heading 2', style: TextStyle(fontSize: 12))),
                          const PopupMenuItem(value: 'todo', child: Text('Turn into Todo item', style: TextStyle(fontSize: 12))),
                          const PopupMenuItem(value: 'image', child: Text('Turn into Photo / Image', style: TextStyle(fontSize: 12))),
                          const PopupMenuItem(value: 'code', child: Text('Turn into Code block', style: TextStyle(fontSize: 12))),
                          const PopupMenuItem(value: 'dry', child: Text('Turn into Dry-Run Trace', style: TextStyle(fontSize: 12, color: AppTheme.accentCyan))),
                          const PopupMenuItem(value: 'quote', child: Text('Turn into Quote', style: TextStyle(fontSize: 12))),
                          const PopupMenuItem(value: 'callout', child: Text('Turn into Callout', style: TextStyle(fontSize: 12))),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'delete', child: Text('Delete Block', style: TextStyle(fontSize: 12, color: Color(0xFFF87171)))),
                        ],
                        child: Container(
                          width: 16,
                          height: 20,
                          alignment: Alignment.center,
                          child: const Icon(Icons.drag_indicator_rounded, size: 14, color: AppTheme.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: widget.isHighlighted
                    ? BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.7), width: 1.5),
                      )
                    : null,
                padding: widget.isHighlighted
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasSelection && _ctrl is RichMarkdownTextController)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: NotionSelectionToolbar(
                          controller: _ctrl as RichMarkdownTextController,
                          block: block,
                          isDark: isDark,
                          onChanged: () {
                            block.content = _ctrl.text;
                            widget.onChanged();
                          },
                          onTurnInto: (newType) {
                            setState(() {
                              block.type = newType;
                              if (newType == BlockType.dryRunTrace &&
                                  (block.tableData.isEmpty || block.tableData.length < 2)) {
                                block.tableData = [
                                  ['Step', 'left', 'right', 'mid', 'nums[mid]', 'target', 'Action'],
                                  ['1', '0', '5', '2', '4', '7', 'left = mid + 1'],
                                  ['2', '3', '5', '4', '8', '7', 'right = mid - 1'],
                                  ['3', '3', '3', '3', '7', '7', 'nums[mid] == target (Found at index 3!)'],
                                ];
                              }
                            });
                            widget.onChanged();
                          },
                          onInsertImage: () {
                            widget.onInsertAfter(BlockType.image);
                          },
                          onDeleteBlock: widget.onDelete,
                        ),
                      ),
                    contentWidget,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
