import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class GridTableView extends StatefulWidget {
  const GridTableView({super.key});

  @override
  State<GridTableView> createState() => _GridTableViewState();
}

class _GridTableViewState extends State<GridTableView> {
  final TextEditingController _filterCtrl = TextEditingController();
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final rows = storage.gridRows;
    final query = _filterCtrl.text.toLowerCase().trim();

    final filtered = rows.where((r) {
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.category.toLowerCase().contains(query) ||
          r.assignee.toLowerCase().contains(query);
      final matchesStatus = _selectedStatus == 'All' || r.status == _selectedStatus;
      return matchesQuery && matchesStatus;
    }).toList();

    final isDark = storage.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.bg(isDark),
      body: Column(
        children: [
          // Database Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surf(isDark),
              border: Border(bottom: BorderSide(color: AppTheme.border(isDark), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_rounded, size: 20, color: AppTheme.accentCyan),
                const SizedBox(width: 10),
                Text(
                  'AppFlowy Database Grid',
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
                    '${rows.length} Records',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Search Input
                SizedBox(
                  width: 220,
                  height: 32,
                  child: TextField(
                    controller: _filterCtrl,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Filter records...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      prefixIcon: const Icon(Icons.search_rounded, size: 14, color: AppTheme.textTertiary),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: AppTheme.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddRowDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                  label: const Text(
                    'New Record',
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

          // Table Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Column(
                  children: [
                    // Table Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0x18FFFFFF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _HeaderCell('Item / Task Name')),
                          Expanded(flex: 2, child: _HeaderCell('Status')),
                          Expanded(flex: 2, child: _HeaderCell('Priority')),
                          Expanded(flex: 2, child: _HeaderCell('Category')),
                          Expanded(flex: 2, child: _HeaderCell('Assignee')),
                          Expanded(flex: 2, child: _HeaderCell('Date')),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),

                    // Table Body Rows
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No records match your filter criteria.',
                          style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                        ),
                      )
                    else
                      for (final item in filtered)
                        _TableRowWidget(
                          row: item,
                          onDelete: () => storage.deleteGridRow(item.id),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRowDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Engineering');
    String status = 'In Progress';
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Add Database Record', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Record Name / Task...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: catCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Category (e.g. Design, Core, DevOps)...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  DropdownButton<String>(
                    value: status,
                    dropdownColor: AppTheme.surfaceSecondary,
                    items: ['Done', 'In Progress', 'Backlog', 'Idea']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => status = val);
                    },
                  ),
                  const Spacer(),
                  const Text('Priority: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  DropdownButton<String>(
                    value: priority,
                    dropdownColor: AppTheme.surfaceSecondary,
                    items: ['High', 'Medium', 'Low']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))))
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
                  context.read<StorageService>().addGridRow(
                        GridRowItem(
                          id: 'grid_${DateTime.now().millisecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          category: catCtrl.text.trim(),
                          status: status,
                          priority: priority,
                        ),
                      );
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan),
              child: const Text('Add Record', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _TableRowWidget extends StatelessWidget {
  final GridRowItem row;
  final VoidCallback onDelete;

  const _TableRowWidget({required this.row, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Status color
    Color statusColor = AppTheme.accentCyan;
    if (row.status == 'Done') statusColor = AppTheme.accentEmerald;
    if (row.status == 'Backlog') statusColor = AppTheme.accentAmber;
    if (row.status == 'Idea') statusColor = AppTheme.accentViolet;

    // Priority color
    Color priorityColor = AppTheme.accentCyan;
    if (row.priority == 'High') priorityColor = AppTheme.accentRose;
    if (row.priority == 'Medium') priorityColor = AppTheme.accentAmber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 0.8)),
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            flex: 3,
            child: Text(
              row.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // Status Pill
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  row.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),
          // Priority Pill
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: priorityColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  row.priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Text(
              row.category,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          // Assignee
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundColor: AppTheme.accentViolet.withValues(alpha: 0.3),
                  child: Text(
                    row.assignee.isNotEmpty ? row.assignee[0] : 'U',
                    style: const TextStyle(fontSize: 9, color: Color(0xFFC4B5FD)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  row.assignee,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              row.date,
              style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            ),
          ),
          // Actions
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textTertiary),
              splashRadius: 12,
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
