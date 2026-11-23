import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class KanbanBoardView extends StatelessWidget {
  const KanbanBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final columns = storage.kanbanColumns;

    final isDark = storage.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.bg(isDark),
      body: Column(
        children: [
          // Board Subheader
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surf(isDark),
              border: Border(bottom: BorderSide(color: AppTheme.border(isDark), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.view_kanban_rounded, size: 20, color: AppTheme.accentCyan),
                const SizedBox(width: 10),
                Text(
                  'AppFlowy Kanban Board',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.txtPrimary(isDark),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${columns.length} Columns  •  ${columns.fold<int>(0, (sum, c) => sum + c.cards.length)} Cards',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddColumnDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                  label: const Text(
                    'Add Column',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Columns Scroll
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              scrollDirection: Axis.horizontal,
              itemCount: columns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (ctx, colIdx) {
                final col = columns[colIdx];
                return _KanbanColumnWidget(
                  column: col,
                  columnIndex: colIdx,
                  totalColumns: columns.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddColumnDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add Kanban Column', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Column Title (e.g. Backlog, Testing)...',
            hintStyle: TextStyle(color: AppTheme.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                context.read<StorageService>().addKanbanColumn(
                      titleCtrl.text.trim(),
                      '#8B5CF6',
                    );
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan),
            child: const Text('Create Column', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumnWidget extends StatelessWidget {
  final KanbanColumn column;
  final int columnIndex;
  final int totalColumns;

  const _KanbanColumnWidget({
    required this.column,
    required this.columnIndex,
    required this.totalColumns,
  });

  @override
  Widget build(BuildContext context) {
    Color colColor = AppTheme.accentCyan;
    if (column.colorHex.contains('8B') || column.colorHex.contains('violet')) {
      colColor = AppTheme.accentViolet;
    } else if (column.colorHex.contains('F5') || column.colorHex.contains('amber')) {
      colColor = AppTheme.accentAmber;
    } else if (column.colorHex.contains('10') || column.colorHex.contains('emerald')) {
      colColor = AppTheme.accentEmerald;
    }

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  column.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${column.cards.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colColor,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  color: AppTheme.textSecondary,
                  splashRadius: 14,
                  onPressed: () => _showAddCardDialog(context, column.id),
                ),
              ],
            ),
          ),

          // Cards List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: column.cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, cardIdx) {
                final card = column.cards[cardIdx];
                return _KanbanCardWidget(
                  card: card,
                  columnId: column.id,
                  columnIndex: columnIndex,
                  totalColumns: totalColumns,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, String colId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Add Task Card', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Card title...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Description or checklist details...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Priority: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  DropdownButton<String>(
                    value: priority,
                    dropdownColor: AppTheme.surfaceSecondary,
                    items: ['High', 'Medium', 'Low']
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => priority = val);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  context.read<StorageService>().addKanbanCard(
                        colId,
                        KanbanCard(
                          id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          priority: priority,
                        ),
                      );
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan),
              child: const Text('Add Card', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanCardWidget extends StatelessWidget {
  final KanbanCard card;
  final String columnId;
  final int columnIndex;
  final int totalColumns;

  const _KanbanCardWidget({
    required this.card,
    required this.columnId,
    required this.columnIndex,
    required this.totalColumns,
  });

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();

    Color priorityColor = AppTheme.accentCyan;
    if (card.priority == 'High') priorityColor = AppTheme.accentRose;
    if (card.priority == 'Medium') priorityColor = AppTheme.accentAmber;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority & Tags
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  card.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: priorityColor,
                  ),
                ),
              ),
              const Spacer(),
              // Delete Button
              InkWell(
                onTap: () => storage.deleteKanbanCard(columnId, card.id),
                child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textTertiary),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),

          if (card.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
            ),
          ],

          const SizedBox(height: 10),

          // Bottom Bar: Checklists & Move Actions
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 12, color: AppTheme.accentEmerald),
              const SizedBox(width: 4),
              Text(
                '${card.checklistDone}/${card.checklistTotal}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              // Move Left Button
              if (columnIndex > 0)
                InkWell(
                  onTap: () {
                    final targetCol = storage.kanbanColumns[columnIndex - 1];
                    storage.moveKanbanCard(card.id, columnId, targetCol.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, size: 14, color: AppTheme.textSecondary),
                  ),
                ),
              const SizedBox(width: 4),
              // Move Right Button
              if (columnIndex < totalColumns - 1)
                InkWell(
                  onTap: () {
                    final targetCol = storage.kanbanColumns[columnIndex + 1];
                    storage.moveKanbanCard(card.id, columnId, targetCol.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.accentCyan),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
