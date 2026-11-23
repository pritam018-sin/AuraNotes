import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class DryRunTraceWidget extends StatefulWidget {
  final BlockItem block;
  final VoidCallback onChanged;

  const DryRunTraceWidget({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<DryRunTraceWidget> createState() => _DryRunTraceWidgetState();
}

class _DryRunTraceWidgetState extends State<DryRunTraceWidget> {
  int _activeStep = 1; // 1-indexed for rows in block.tableData
  Timer? _playbackTimer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ensureInitialized();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _ensureInitialized() {
    final block = widget.block;
    // If tableData is missing or not a dry-run table, seed with Binary Search default
    if (block.tableData.isEmpty || !block.tableData[0].contains('left') && !block.tableData[0].contains('start')) {
      block.tableData = [
        ['Step', 'left', 'right', 'mid', 'nums[mid]', 'target', 'Action'],
        ['1', '0', '5', '2', '4', '7', 'left = mid + 1'],
        ['2', '3', '5', '4', '8', '7', 'right = mid - 1'],
        ['3', '3', '3', '3', '7', '7', 'nums[mid] == target (Found at index 3!)'],
      ];
    }
    if (block.content.trim().isEmpty) {
      block.content = '1, 3, 4, 7, 8, 12';
    }
  }

  List<String> get _arrayItems {
    final text = widget.block.content.trim();
    if (text.isEmpty) return ['1', '3', '4', '7', '8', '12'];
    return text.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
  }

  void _loadPreset(String preset) {
    setState(() {
      _playbackTimer?.cancel();
      _isPlaying = false;
      _activeStep = 1;

      if (preset == 'binary_search') {
        widget.block.content = '1, 3, 4, 7, 8, 12';
        widget.block.tableData = [
          ['Step', 'left', 'right', 'mid', 'nums[mid]', 'target', 'Action'],
          ['1', '0', '5', '2', '4', '7', 'left = mid + 1'],
          ['2', '3', '5', '4', '8', '7', 'right = mid - 1'],
          ['3', '3', '3', '3', '7', '7', 'nums[mid] == target (Found at index 3!)'],
        ];
      } else if (preset == 'two_pointers') {
        widget.block.content = '2, 7, 11, 15, 19';
        widget.block.tableData = [
          ['Step', 'left', 'right', 'nums[L]', 'nums[R]', 'Sum', 'target', 'Action'],
          ['1', '0', '4', '2', '19', '21', '22', 'Sum < 22 -> left++'],
          ['2', '1', '4', '7', '19', '26', '22', 'Sum > 22 -> right--'],
          ['3', '1', '3', '7', '15', '22', '22', 'Sum == 22 -> Pair Found [7, 15]!'],
        ];
      } else if (preset == 'sliding_window') {
        widget.block.content = '2, 1, 5, 1, 3, 2';
        widget.block.tableData = [
          ['Step', 'start', 'end', 'Window', 'sum', 'target', 'Action'],
          ['1', '0', '2', '[2, 1, 5]', '8', '>=7', 'Valid Window (sum=8), shrink start'],
          ['2', '1', '2', '[1, 5]', '6', '<7', 'Invalid Window (sum<7), expand end'],
          ['3', '1', '3', '[1, 5, 1]', '7', '>=7', 'Valid Window (sum=7), record len'],
          ['4', '2', '4', '[5, 1, 3]', '9', '>=7', 'Valid Window (sum=9), shrink start'],
        ];
      }
    });
    widget.onChanged();
  }

  void _toggleAutoPlay() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 1400), (t) {
        final totalSteps = widget.block.tableData.length - 1;
        if (totalSteps <= 0) return;
        setState(() {
          if (_activeStep >= totalSteps) {
            _activeStep = 1;
          } else {
            _activeStep++;
          }
        });
      });
    }
  }

  void _editArrayDialog() {
    final ctrl = TextEditingController(text: widget.block.content);
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
            Icon(Icons.edit_note_rounded, color: AppTheme.accentCyan, size: 20),
            SizedBox(width: 8),
            Text('Edit Visual Array Elements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter comma or space-separated elements (e.g. 1, 3, 4, 7, 8, 12):',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceTertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              setState(() {
                widget.block.content = ctrl.text.trim();
              });
              widget.onChanged();
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Array', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _editCellDialog(int rowIndex, int colIndex) {
    final currentVal = widget.block.tableData[rowIndex][colIndex];
    final colName = widget.block.tableData[0][colIndex];
    final ctrl = TextEditingController(text: currentVal);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.glassBorderActive),
        ),
        title: Text('Edit $colName (Row $rowIndex)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceTertiary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.glassBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              setState(() {
                widget.block.tableData[rowIndex][colIndex] = ctrl.text.trim();
              });
              widget.onChanged();
              Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _addStep() {
    final headers = widget.block.tableData[0];
    final nextStepNum = widget.block.tableData.length;
    final newRow = List<String>.filled(headers.length, '');
    newRow[0] = '$nextStepNum';
    setState(() {
      widget.block.tableData.add(newRow);
      _activeStep = widget.block.tableData.length - 1;
    });
    widget.onChanged();
  }

  void _removeStep() {
    if (widget.block.tableData.length > 2) {
      setState(() {
        widget.block.tableData.removeLast();
        if (_activeStep >= widget.block.tableData.length) {
          _activeStep = widget.block.tableData.length - 1;
        }
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isDark = storage.isDarkMode;
    final table = widget.block.tableData;
    final headers = table.isNotEmpty ? table[0] : <String>[];
    final totalSteps = table.length > 1 ? table.length - 1 : 0;
    if (_activeStep > totalSteps) _activeStep = totalSteps > 0 ? 1 : 0;

    // Parse current step pointers
    int? leftPtr;
    int? rightPtr;
    int? midPtr;
    int? startPtr;
    int? endPtr;

    if (_activeStep > 0 && _activeStep < table.length) {
      final currentRow = table[_activeStep];
      for (int c = 0; c < headers.length; c++) {
        final h = headers[c].toLowerCase().trim();
        final val = int.tryParse(currentRow[c].trim());
        if (val != null) {
          if (h == 'left' || h == 'l') leftPtr = val;
          if (h == 'right' || h == 'r') rightPtr = val;
          if (h == 'mid' || h == 'm') midPtr = val;
          if (h == 'start') startPtr = val;
          if (h == 'end') endPtr = val;
        }
      }
    }

    final array = _arrayItems;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceSecondary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.accentCyan.withValues(alpha: 0.35) : AppTheme.accentCyan.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentCyan.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Toolbar: Title, Presets, Playback controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceTertiary : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: Border(
                bottom: BorderSide(color: AppTheme.border(isDark), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Electric Dry-Run Emblem
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: AppTheme.auraCyanGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.account_tree_rounded, size: 14, color: Colors.black),
                ),
                const SizedBox(width: 10),
                Text(
                  'Algorithm Dry-Run Logic Trace',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppTheme.txtPrimary(isDark),
                  ),
                ),
                const SizedBox(width: 8),

                // Preset Dropdown
                PopupMenuButton<String>(
                  tooltip: 'Algorithm Templates',
                  offset: const Offset(0, 26),
                  color: AppTheme.surfSec(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppTheme.border(isDark)),
                  ),
                  onSelected: _loadPreset,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'binary_search',
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 14, color: AppTheme.accentCyan),
                          SizedBox(width: 8),
                          Text('Binary Search Template', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'two_pointers',
                      child: Row(
                        children: [
                          Icon(Icons.compare_arrows_rounded, size: 14, color: Color(0xFFC084FC)),
                          SizedBox(width: 8),
                          Text('Two Pointers Template', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sliding_window',
                      child: Row(
                        children: [
                          Icon(Icons.view_column_rounded, size: 14, color: Color(0xFFF59E0B)),
                          SizedBox(width: 8),
                          Text('Sliding Window Template', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceSecondary : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppTheme.border(isDark)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Presets', style: TextStyle(fontSize: 11, color: AppTheme.txtSecondary(isDark), fontWeight: FontWeight.w600)),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_drop_down_rounded, size: 14, color: AppTheme.txtTertiary(isDark)),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Playback Scrubber: Prev, Step badge, Next, Auto-Play
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Prev Button
                    InkWell(
                      onTap: _activeStep > 1 ? () => setState(() => _activeStep--) : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: _activeStep > 1 ? AppTheme.accentCyan : AppTheme.textTertiary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Step Indicator Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        totalSteps > 0 ? 'Step $_activeStep of $totalSteps' : 'No Steps',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Next Button
                    InkWell(
                      onTap: _activeStep < totalSteps ? () => setState(() => _activeStep++) : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _activeStep < totalSteps ? AppTheme.accentCyan : AppTheme.textTertiary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Auto Play / Pause
                    InkWell(
                      onTap: _toggleAutoPlay,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: _isPlaying
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : AppTheme.accentViolet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isPlaying
                                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                : AppTheme.accentViolet.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 13,
                              color: _isPlaying ? const Color(0xFFF87171) : AppTheme.accentViolet,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isPlaying ? 'Pause' : 'Auto Play',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isPlaying ? const Color(0xFFF87171) : AppTheme.accentViolet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Interactive Visual Array Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'VISUAL ARRAY / WINDOW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.txtTertiary(isDark),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _editArrayDialog,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 12, color: AppTheme.accentCyan),
                            SizedBox(width: 4),
                            Text('Edit Array', style: TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Array Boxes with Pointer Markers
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < array.length; i++) ...[
                        _buildArrayCell(
                          index: i,
                          val: array[i],
                          isLeft: leftPtr == i,
                          isRight: rightPtr == i,
                          isMid: midPtr == i,
                          isInWindow: (startPtr != null && endPtr != null && i >= startPtr && i <= endPtr),
                          isDark: isDark,
                        ),
                        if (i < array.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.border(isDark)),

          // 3. Dry-Run Trace Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 34,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 38,
              horizontalMargin: 14,
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(isDark ? AppTheme.surfaceTertiary : const Color(0xFFF1F5F9)),
              columns: [
                for (int c = 0; c < headers.length; c++)
                  DataColumn(
                    label: Text(
                      headers[c].toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
              ],
              rows: [
                for (int r = 1; r < table.length; r++)
                  DataRow(
                    selected: _activeStep == r,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (_activeStep == r) {
                        return AppTheme.accentCyan.withValues(alpha: isDark ? 0.14 : 0.1);
                      }
                      return r % 2 == 0 ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02)) : Colors.transparent;
                    }),
                    onSelectChanged: (_) {
                      setState(() => _activeStep = r);
                    },
                    cells: [
                      for (int c = 0; c < table[r].length; c++)
                        DataCell(
                          InkWell(
                            onDoubleTap: () => _editCellDialog(r, c),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                table[r][c],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: (c > 0 && c < headers.length - 1) ? 'monospace' : null,
                                  fontWeight: _activeStep == r ? FontWeight.w600 : FontWeight.w400,
                                  color: _activeStep == r
                                      ? AppTheme.txtPrimary(isDark)
                                      : (c == 0 ? (isDark ? AppTheme.accentCyan : const Color(0xFF0284C7)) : AppTheme.txtSecondary(isDark)),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // 4. Action Bar: Add Step, Remove Step
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceTertiary.withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: AppTheme.border(isDark), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Add Step
                InkWell(
                  onTap: _addStep,
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: AppTheme.accentCyan),
                        SizedBox(width: 4),
                        Text('Add Step', style: TextStyle(fontSize: 11.5, color: AppTheme.accentCyan, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Remove Step
                if (table.length > 2)
                  InkWell(
                    onTap: _removeStep,
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_rounded, size: 14, color: Color(0xFFF87171)),
                          SizedBox(width: 4),
                          Text('Remove Step', style: TextStyle(fontSize: 11.5, color: Color(0xFFF87171), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),
                const Text(
                  '💡 Double-click any cell to edit',
                  style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),

          // 5. User's Highlighted Benefit Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentViolet.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
              border: Border(
                top: BorderSide(color: AppTheme.accentViolet.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.psychology_rounded, size: 16, color: Color(0xFFC084FC)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Benefit: Algorithms ratna nahi padega; dry-run table se logic crystal clear yaad rahega.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC084FC),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrayCell({
    required int index,
    required String val,
    required bool isLeft,
    required bool isRight,
    required bool isMid,
    required bool isInWindow,
    required bool isDark,
  }) {
    Color borderColor = AppTheme.border(isDark);
    Color bgColor = isDark ? AppTheme.surface : const Color(0xFFF8FAFC);
    List<BoxShadow>? shadows;

    if (isMid) {
      borderColor = const Color(0xFFFFD166);
      bgColor = const Color(0xFFFFD166).withValues(alpha: isDark ? 0.15 : 0.25);
      shadows = [
        BoxShadow(color: const Color(0xFFFFD166).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 2)),
      ];
    } else if (isLeft && isRight) {
      borderColor = AppTheme.accentCyan;
      bgColor = AppTheme.accentCyan.withValues(alpha: isDark ? 0.2 : 0.25);
    } else if (isLeft) {
      borderColor = AppTheme.accentCyan;
      bgColor = AppTheme.accentCyan.withValues(alpha: isDark ? 0.12 : 0.18);
      shadows = [
        BoxShadow(color: AppTheme.accentCyan.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
      ];
    } else if (isRight) {
      borderColor = const Color(0xFFF43F5E);
      bgColor = const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.12 : 0.18);
      shadows = [
        BoxShadow(color: const Color(0xFFF43F5E).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
      ];
    } else if (isInWindow) {
      borderColor = AppTheme.accentCyan.withValues(alpha: 0.5);
      bgColor = AppTheme.accentCyan.withValues(alpha: isDark ? 0.08 : 0.12);
    }

    return Column(
      children: [
        // Pointers tag bar above
        SizedBox(
          height: 18,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeft)
                _buildPointerBadge('L', AppTheme.accentCyan),
              if (isMid)
                _buildPointerBadge('M', const Color(0xFFFFD166)),
              if (isRight)
                _buildPointerBadge('R', const Color(0xFFF43F5E)),
            ],
          ),
        ),
        const SizedBox(height: 2),

        // Array Item Box
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: (isMid || isLeft || isRight) ? 1.8 : 1.0),
            boxShadow: shadows,
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: (isMid || isLeft || isRight) ? (isDark ? AppTheme.textPrimary : const Color(0xFF0F172A)) : AppTheme.txtPrimary(isDark),
            ),
          ),
        ),
        const SizedBox(height: 3),

        // Index Label below
        Text(
          '[$index]',
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: AppTheme.txtTertiary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildPointerBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }
}
