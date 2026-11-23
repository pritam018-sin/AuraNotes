import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'import_dialog.dart';

class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({super.key});

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final query = _searchCtrl.text.toLowerCase().trim();

    // Collect search items
    final List<_PaletteItem> items = [];

    // 1. Actions
    items.add(_PaletteItem(
      title: 'New Blank Note',
      category: 'Action',
      icon: Icons.note_add_rounded,
      onSelect: () {
        storage.createNote();
        Navigator.of(context).pop();
      },
    ));

    items.add(_PaletteItem(
      title: 'Open Kanban Board',
      category: 'View',
      icon: Icons.view_kanban_rounded,
      onSelect: () {
        storage.setActiveView(1);
        Navigator.of(context).pop();
      },
    ));

    items.add(_PaletteItem(
      title: 'Open Grid Table Database',
      category: 'View',
      icon: Icons.table_chart_rounded,
      onSelect: () {
        storage.setActiveView(2);
        Navigator.of(context).pop();
      },
    ));

    items.add(_PaletteItem(
      title: 'Import Notes / Documents',
      category: 'Import',
      icon: Icons.file_download_outlined,
      onSelect: () {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (_) => const ImportDialog(),
        );
      },
    ));

    // 2. Notes
    for (final note in storage.notes) {
      if (query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          note.blocks.any((b) => b.content.toLowerCase().contains(query))) {
        items.add(_PaletteItem(
          title: '${note.icon} ${note.title}',
          category: 'Document',
          icon: Icons.article_rounded,
          onSelect: () {
            storage.setActiveNote(note.id);
            Navigator.of(context).pop();
          },
        ));
      }
    }

    // 3. Kanban Cards
    for (final col in storage.kanbanColumns) {
      for (final card in col.cards) {
        if (query.isEmpty ||
            card.title.toLowerCase().contains(query) ||
            card.description.toLowerCase().contains(query)) {
          items.add(_PaletteItem(
            title: '${card.title} (${col.title})',
            category: 'Board Card',
            icon: Icons.check_circle_outline_rounded,
            onSelect: () {
              storage.setActiveView(1);
              Navigator.of(context).pop();
            },
          ));
        }
      }
    }

    final filtered = items.where((it) {
      if (query.isEmpty) return true;
      return it.title.toLowerCase().contains(query) ||
          it.category.toLowerCase().contains(query);
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 40, right: 40),
      child: Container(
        width: 620,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorderActive),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentCyan.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.glassBorder),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.accentCyan, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type to search notes, tasks, or commands...',
                        hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() => _selectedIndex = 0),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: const Text(
                      'ESC to close',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No matching notes or actions found.',
                        style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final item = filtered[idx];
                        final isSelected = idx == _selectedIndex;

                        return InkWell(
                          onTap: item.onSelect,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentCyan.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.accentCyan.withValues(alpha: 0.4))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 16,
                                  color: isSelected
                                      ? AppTheme.accentCyan
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.glassBorder),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteItem {
  final String title;
  final String category;
  final IconData icon;
  final VoidCallback onSelect;

  _PaletteItem({
    required this.title,
    required this.category,
    required this.icon,
    required this.onSelect,
  });
}
