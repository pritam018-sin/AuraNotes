import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_icons.dart';
import '../dialogs/import_dialog.dart';
import '../dialogs/settings_dialog.dart';

class AuraSidebar extends StatefulWidget {
  const AuraSidebar({super.key});

  @override
  State<AuraSidebar> createState() => _AuraSidebarState();
}

class _AuraSidebarState extends State<AuraSidebar> {
  bool _allExpanded = false; // By default COLLAPSED!
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final allRootNotes = storage.rootNotes;

    // Filter notes if search query entered
    final rootNotes = _searchFilter.isEmpty
        ? allRootNotes
        : allRootNotes.where((n) {
            final matchesSelf = n.title.toLowerCase().contains(_searchFilter);
            final children = storage.getChildNotes(n.id);
            final matchesChildren = children.any((c) => c.title.toLowerCase().contains(_searchFilter));
            return matchesSelf || matchesChildren;
          }).toList();

    final isDark = storage.isDarkMode;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.sidebarBackground : const Color(0xFFF8FAFC),
        border: Border(
          right: BorderSide(color: AppTheme.border(isDark), width: 1),
        ),
      ),
      child: Column(
        children: [
          // 1. Sleek Modern Header (Zero Emojis)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.border(isDark), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentViolet.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 26,
                      height: 26,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aura Workspace',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppTheme.txtPrimary(isDark),
                      ),
                    ),
                    Text(
                      'Developer Notes Engine',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.txtTertiary(isDark),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Import Vault / Folder Button
                Tooltip(
                  message: 'Import Local Folder or Files',
                  child: InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const ImportDialog(),
                    ),
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(Icons.file_download_outlined, size: 15, color: AppTheme.accentCyan),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // New Root Note Button
                Tooltip(
                  message: 'New Document',
                  child: InkWell(
                    onTap: () => storage.createNote(icon: 'document'),
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.add_rounded, size: 17, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Navigation & Views
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                // Views
                _SidebarNavTile(
                  icon: Icons.article_outlined,
                  label: 'Documents',
                  active: storage.activeViewIndex == 0,
                  onTap: () => storage.setActiveView(0),
                ),
                _SidebarNavTile(
                  icon: Icons.view_kanban_outlined,
                  label: 'Kanban Board',
                  badge: '${storage.kanbanColumns.fold<int>(0, (sum, c) => sum + c.cards.length)}',
                  active: storage.activeViewIndex == 1,
                  onTap: () => storage.setActiveView(1),
                ),
                _SidebarNavTile(
                  icon: Icons.table_chart_outlined,
                  label: 'Database Grid',
                  badge: '${storage.gridRows.length}',
                  active: storage.activeViewIndex == 2,
                  onTap: () => storage.setActiveView(2),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.glassBorder),
                const SizedBox(height: 8),

                // Quick Filter Search Input
                Container(
                  height: 32,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfSec(isDark),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border(isDark)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 14, color: AppTheme.txtTertiary(isDark)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(fontSize: 11.5, color: AppTheme.txtPrimary(isDark)),
                          decoration: InputDecoration(
                            hintText: 'Filter notes (e.g. DP, Array)...',
                            hintStyle: TextStyle(fontSize: 11.5, color: AppTheme.txtTertiary(isDark)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) => setState(() => _searchFilter = val.trim().toLowerCase()),
                        ),
                      ),
                      if (_searchFilter.isNotEmpty)
                        InkWell(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchFilter = '');
                          },
                          child: Icon(Icons.close_rounded, size: 13, color: AppTheme.txtTertiary(isDark)),
                        ),
                    ],
                  ),
                ),

                // Documents Tree Header with Collapse Toggle
                Row(
                  children: [
                    const SizedBox(width: 6),
                    Text(
                      'PAGES & OUTLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.txtTertiary(isDark),
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: _allExpanded ? 'Collapse All' : 'Expand All',
                      child: InkWell(
                        onTap: () => setState(() => _allExpanded = !_allExpanded),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Icon(
                            _allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                            size: 13,
                            color: AppTheme.txtTertiary(isDark),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Add Document',
                      child: InkWell(
                        onTap: () => storage.createNote(icon: 'document'),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Icon(Icons.add_rounded, size: 14, color: AppTheme.txtTertiary(isDark)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Recursive Document Hierarchy Tree
                if (rootNotes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 28, color: AppTheme.textTertiary),
                          const SizedBox(height: 8),
                          const Text(
                            'No documents yet',
                            style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => const ImportDialog(),
                            ),
                            child: const Text(
                              'Import Folder / Vault',
                              style: TextStyle(fontSize: 11.5, color: AppTheme.accentCyan, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final note in rootNotes)
                    _HierarchicalNoteTile(
                      key: ValueKey('${note.id}_$_allExpanded'),
                      note: note,
                      depth: 0,
                      initiallyExpanded: _allExpanded,
                    ),
              ],
            ),
          ),

          // 3. Clean Minimal Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.border(isDark), width: 1),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const SettingsDialog(),
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 14, color: AppTheme.txtTertiary(isDark)),
                        const SizedBox(width: 6),
                        Text(
                          'Settings',
                          style: TextStyle(fontSize: 11, color: AppTheme.txtSecondary(isDark)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'AuraNotes Pro',
                  style: TextStyle(fontSize: 10, color: AppTheme.txtTertiary(isDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool active;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    this.badge,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isDark = storage.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.accentCyan.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active
              ? Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? AppTheme.accentCyan : AppTheme.txtSecondary(isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.txtPrimary(isDark) : AppTheme.txtSecondary(isDark),
                ),
              ),
            ),
            if (badge != null)
              Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.txtTertiary(isDark),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HierarchicalNoteTile extends StatefulWidget {
  final NoteDocument note;
  final int depth;
  final bool initiallyExpanded;

  const _HierarchicalNoteTile({
    super.key,
    required this.note,
    required this.depth,
    this.initiallyExpanded = false, // Collapsed by default!
  });

  @override
  State<_HierarchicalNoteTile> createState() => _HierarchicalNoteTileState();
}

class _HierarchicalNoteTileState extends State<_HierarchicalNoteTile> {
  bool? _userToggledExpanded;
  bool _isHovered = false;

  @override
  void didUpdateWidget(covariant _HierarchicalNoteTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _userToggledExpanded = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final children = storage.getChildNotes(widget.note.id);
    final headings = storage.getHeadingsForNote(widget.note.id);
    final hasChildren = children.isNotEmpty;
    final hasHeadings = headings.isNotEmpty;
    final canExpand = hasChildren || hasHeadings;
    final isSelected = storage.activeNoteId == widget.note.id && storage.activeViewIndex == 0;

    // Smart auto-expand: Expand ONLY if this folder is an ancestor of the active note
    final isAncestorOfActive = storage.activeNoteId != null &&
        storage.getBreadcrumbTrail(storage.activeNoteId!).any((n) => n.id == widget.note.id);

    final isDark = storage.isDarkMode;
    final isExpanded = _userToggledExpanded ?? (widget.initiallyExpanded || isAncestorOfActive);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: () => storage.setActiveNote(widget.note.id),
            onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, storage, widget.note),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 1),
              padding: EdgeInsets.only(
                left: 6 + (widget.depth * 13.0),
                right: 6,
                top: 4.5,
                bottom: 4.5,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentCyan.withValues(alpha: 0.12)
                    : (_isHovered ? (isDark ? const Color(0x0CFFFFFF) : const Color(0x0C000000)) : Colors.transparent),
                borderRadius: BorderRadius.circular(6),
                border: isSelected
                    ? Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.35))
                    : null,
              ),
              child: Row(
                children: [
                  // Modern Collapsing Arrow
                  if (canExpand)
                    InkWell(
                      onTap: () => setState(() => _userToggledExpanded = !isExpanded),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.chevron_right_rounded,
                          size: 14,
                          color: isSelected ? AppTheme.accentCyan : AppTheme.txtTertiary(isDark),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 14),

                  // Modern Developer Icon (Zero Emojis!)
                  AppIcons.buildModernIcon(
                    widget.note.icon,
                    isFolder: hasChildren,
                    isExpanded: isExpanded,
                    size: 13.5,
                    color: isSelected
                        ? AppTheme.accentCyan
                        : (hasChildren ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                  ),
                  const SizedBox(width: 7),

                  // Title
                  Expanded(
                    child: Text(
                      widget.note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppTheme.txtPrimary(isDark) : AppTheme.txtSecondary(isDark),
                      ),
                    ),
                  ),

                  // Outline Section Count Badge
                  if (hasHeadings && !_isHovered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentCyan.withValues(alpha: 0.18)
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${headings.length}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.accentCyan : AppTheme.txtTertiary(isDark),
                        ),
                      ),
                    ),

                  // Hover Actions: + Subpage, Delete Document
                  if (_isHovered) ...[
                    Tooltip(
                      message: 'Add sub-page inside',
                      child: InkWell(
                        onTap: () {
                          storage.createNote(
                            parentId: widget.note.id,
                            title: 'Untitled Sub-Page',
                            icon: 'document',
                          );
                          setState(() => _userToggledExpanded = true);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.add_rounded, size: 14, color: AppTheme.txtSecondary(isDark)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Tooltip(
                      message: 'Delete document',
                      child: InkWell(
                        onTap: () => _confirmDeleteNote(context, storage, widget.note),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.delete_outline_rounded, size: 13.5, color: Color(0xFFF87171)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // 1. Render Children Notes Recursively
        if (hasChildren && isExpanded)
          for (final child in children)
            _HierarchicalNoteTile(
              note: child,
              depth: widget.depth + 1,
              initiallyExpanded: widget.initiallyExpanded,
            ),

        // 2. Render Document Headings Outline with Modern Arrow Nesting (Zero # Hashtags!)
        if (hasHeadings && (isExpanded || isSelected))
          _NoteHeadingsList(
            headings: headings,
            depth: widget.depth + 1,
            noteId: widget.note.id,
          ),
      ],
    );
  }

  void _confirmDeleteNote(BuildContext context, StorageService storage, NoteDocument note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.glassBorderActive),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 20),
            SizedBox(width: 8),
            Text(
              'Delete Document?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"?\nAll nested sub-pages and blocks inside will be permanently deleted.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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

  void _showContextMenu(BuildContext context, Offset position, StorageService storage, NoteDocument note) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: AppTheme.surfaceSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.glassBorderActive),
      ),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          onTap: () {
            storage.createNote(
              parentId: note.id,
              title: 'Untitled Sub-Page',
              icon: 'document',
            );
            setState(() => _userToggledExpanded = true);
          },
          child: const Row(
            children: [
              Icon(Icons.add_rounded, size: 15, color: AppTheme.accentCyan),
              SizedBox(width: 8),
              Text('Add Sub-Page', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => storage.toggleFavorite(note.id),
          child: Row(
            children: [
              Icon(
                note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 15,
                color: note.isFavorite ? const Color(0xFFFBBF24) : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(note.isFavorite ? 'Remove Favorite' : 'Mark Favorite', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          onTap: () {
            if (mounted) {
              Future.microtask(() {
                if (context.mounted) _confirmDeleteNote(context, storage, note);
              });
            }
          },
          child: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFF87171)),
              SizedBox(width: 8),
              Text('Delete Document', style: TextStyle(fontSize: 12, color: Color(0xFFF87171))),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteHeadingsList extends StatelessWidget {
  final List<BlockItem> headings;
  final int depth;
  final String noteId;

  const _NoteHeadingsList({
    required this.headings,
    required this.depth,
    required this.noteId,
  });

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final h in headings)
          _HeadingNavTile(
            heading: h,
            depth: depth,
            onTap: () {
              storage.setActiveNote(noteId);
              storage.scrollToBlock(h.id);
            },
          ),
      ],
    );
  }
}

class _HeadingNavTile extends StatefulWidget {
  final BlockItem heading;
  final int depth;
  final VoidCallback onTap;

  const _HeadingNavTile({
    required this.heading,
    required this.depth,
    required this.onTap,
  });

  @override
  State<_HeadingNavTile> createState() => _HeadingNavTileState();
}

class _HeadingNavTileState extends State<_HeadingNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isDark = storage.isDarkMode;
    final h = widget.heading;
    final level = h.type == BlockType.heading1 ? 1 : (h.type == BlockType.heading2 ? 2 : 3);
    final indent = (widget.depth * 13.0) + ((level - 1) * 7.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 0.8),
          padding: EdgeInsets.only(
            left: 12 + indent,
            right: 8,
            top: 3,
            bottom: 3,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.accentCyan.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Sleek nesting chevron arrow (Zero Hashtags!)
              Icon(
                Icons.subdirectory_arrow_right_rounded,
                size: level == 1 ? 12.5 : (level == 2 ? 11.0 : 10.0),
                color: level == 1
                    ? AppTheme.accentCyan
                    : (level == 2
                        ? AppTheme.accentCyan.withValues(alpha: 0.65)
                        : AppTheme.txtTertiary(isDark)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  h.content.trim().isNotEmpty ? h.content.trim() : 'Section',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: level == 1 ? FontWeight.w600 : FontWeight.w400,
                    color: _isHovered
                        ? AppTheme.accentCyan
                        : (level == 1 ? AppTheme.txtSecondary(isDark) : AppTheme.txtTertiary(isDark)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
