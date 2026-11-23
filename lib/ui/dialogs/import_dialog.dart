import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  int _activeTab = 0; // 0: Local Folder / Vault, 1: Markdown Files, 2: Paste Markdown
  bool _isImporting = false;
  String _importStatus = '';

  // Tab 0: Folder Import
  final TextEditingController _folderPathCtrl = TextEditingController();
  final TextEditingController _folderTitleCtrl = TextEditingController();
  String? _folderParentId;

  // Tab 1: File Import
  final List<String> _selectedFiles = [];
  String? _filesParentId;

  // Tab 2: Manual Paste
  final TextEditingController _pasteTitleCtrl = TextEditingController(text: 'Imported Document');
  final TextEditingController _pasteContentCtrl = TextEditingController();
  String? _pasteParentId;

  @override
  void initState() {
    super.initState();
    // Check if ./Master-Notes exists in the workspace as a convenient default suggestion
    final localMaster = Directory('Master-Notes');
    if (localMaster.existsSync()) {
      _folderPathCtrl.text = localMaster.absolute.path;
      _folderTitleCtrl.text = 'Master Notes Vault';
    } else {
      final fallback = Directory(r'c:\Users\DELL\WebDevPractice\chrome\Master-Notes');
      if (fallback.existsSync()) {
        _folderPathCtrl.text = fallback.path;
        _folderTitleCtrl.text = 'Master Notes Vault';
      }
    }
  }

  @override
  void dispose() {
    _folderPathCtrl.dispose();
    _folderTitleCtrl.dispose();
    _pasteTitleCtrl.dispose();
    _pasteContentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Notes Folder or Vault from PC',
      );

      if (selectedDirectory != null) {
        setState(() {
          _folderPathCtrl.text = selectedDirectory;
          final dirName = Directory(selectedDirectory).uri.pathSegments.where((s) => s.isNotEmpty).last;
          final cleanTitle = dirName
              .replaceAll(RegExp(r'^\d+[\.\-_ ]*'), '')
              .replaceAll('-', ' ')
              .trim();
          _folderTitleCtrl.text = cleanTitle.isNotEmpty ? cleanTitle : 'My Coding Vault';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open folder picker: $e'),
            backgroundColor: AppTheme.surfaceSecondary,
          ),
        );
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Select Markdown or Text Files to Import',
        type: FileType.custom,
        allowedExtensions: ['md', 'txt', 'json'],
      );

      if (files.isNotEmpty) {
        setState(() {
          _selectedFiles.clear();
          _selectedFiles.addAll(files.map((f) => f.path).whereType<String>());
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file picker: $e'),
            backgroundColor: AppTheme.surfaceSecondary,
          ),
        );
      }
    }
  }

  Future<void> _startFolderImport(BuildContext context, StorageService storage) async {
    final path = _folderPathCtrl.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a valid folder path.'),
          backgroundColor: AppTheme.surfaceSecondary,
        ),
      );
      return;
    }

    final dir = Directory(path);
    if (!dir.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The specified directory does not exist on your PC.'),
          backgroundColor: AppTheme.surfaceSecondary,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importStatus = 'Scanning folder and building hierarchy...';
    });

    try {
      final count = await storage.importFolderRecursive(
        folderPath: path,
        customTitle: _folderTitleCtrl.text.trim().isNotEmpty ? _folderTitleCtrl.text.trim() : null,
        parentId: _folderParentId,
        onProgress: (status) {
          if (mounted) setState(() => _importStatus = status);
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Successfully imported $count notes with syntax-highlighted code & outline hierarchy!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.surfaceSecondary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importStatus = 'Import Error: $e';
        });
      }
    }
  }

  Future<void> _startFilesImport(BuildContext context, StorageService storage) async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file to import.'),
          backgroundColor: AppTheme.surfaceSecondary,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importStatus = 'Importing selected files...';
    });

    try {
      final count = await storage.importFiles(
        filePaths: _selectedFiles,
        parentId: _filesParentId,
        onProgress: (status) {
          if (mounted) setState(() => _importStatus = status);
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Imported $count files into your workspace.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.surfaceSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importStatus = 'Import Error: $e';
        });
      }
    }
  }

  Future<void> _startPasteImport(BuildContext context, StorageService storage) async {
    final title = _pasteTitleCtrl.text.trim();
    final content = _pasteContentCtrl.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Markdown content cannot be empty.'),
          backgroundColor: AppTheme.surfaceSecondary,
        ),
      );
      return;
    }

    final note = storage.importDocument(
      title: title.isNotEmpty ? title : 'Imported Document',
      content: content,
      parentId: _pasteParentId,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 20),
            const SizedBox(width: 10),
            Text(
              'Imported "${note.title}" with ${note.blocks.length} blocks.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final notes = storage.notes;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 740,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorderActive),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.85),
              blurRadius: 36,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (Zero Emojis)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.drive_folder_upload_rounded, color: AppTheme.accentCyan, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Notes & Knowledge Vault',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Universal local folder and file scanner for any PC or project directory.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    splashRadius: 16,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      index: 0,
                      icon: Icons.folder_open_rounded,
                      label: 'Import Local Folder / Vault',
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      index: 1,
                      icon: Icons.upload_file_rounded,
                      label: 'Import Markdown File(s)',
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      index: 2,
                      icon: Icons.content_paste_rounded,
                      label: 'Paste Raw Markdown',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.glassBorder),

            // Tab Content
            if (_isImporting)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.accentCyan),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _importStatus,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Parsing markdown headings, building outlines, and applying syntax highlighting...',
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              )
            else if (_activeTab == 0)
              _buildFolderImportTab(context, storage, notes)
            else if (_activeTab == 1)
              _buildFilesImportTab(context, storage, notes)
            else
              _buildPasteTab(context, storage, notes),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 0: Local Folder Import
  Widget _buildFolderImportTab(BuildContext context, StorageService storage, List<dynamic> notes) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Folder Path Input with Browse Button
          const Text(
            'LOCAL FOLDER PATH ON PC',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _folderPathCtrl,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'Consolas'),
                  decoration: InputDecoration(
                    hintText: 'C:\\Users\\...\\MyNotesFolder',
                    hintStyle: const TextStyle(color: AppTheme.textTertiary, fontFamily: 'Consolas'),
                    filled: true,
                    fillColor: AppTheme.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.accentCyan),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _pickFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Browse PC...'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceSecondary,
                  foregroundColor: AppTheme.accentCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.accentCyan),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Workspace Section Title
          const Text(
            'WORKSPACE CATEGORY NAME (OPTIONAL)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _folderTitleCtrl,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Master DSA Notes, System Design, or Algorithms',
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.accentCyan),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Destination Parent Selector
          const Text(
            'DESTINATION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _folderParentId,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceSecondary,
                hint: const Text('Root Workspace (Top Level)', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('📁 Root Workspace (Top Level)', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                  ),
                  for (final n in notes)
                    DropdownMenuItem<String?>(
                      value: n.id,
                      child: Text('📄 ${n.title}', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                    ),
                ],
                onChanged: (val) => setState(() => _folderParentId = val),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Import Button
          ElevatedButton.icon(
            onPressed: () => _startFolderImport(context, storage),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Scan & Import Directory Recursively', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: Local Files Import
  Widget _buildFilesImportTab(BuildContext context, StorageService storage, List<dynamic> notes) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SELECTED FILES (${_selectedFiles.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppTheme.textTertiary),
              ),
              ElevatedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Choose Files...'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceSecondary,
                  foregroundColor: AppTheme.accentCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: AppTheme.accentCyan),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Files list preview box
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: _selectedFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.upload_file_rounded, size: 32, color: AppTheme.textTertiary),
                        SizedBox(height: 8),
                        Text(
                          'No files selected yet. Click "Choose Files..." above.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textTertiary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedFiles.length,
                    itemBuilder: (ctx, idx) {
                      final filePath = _selectedFiles[idx];
                      final fileName = filePath.split(RegExp(r'[\\/]')).last;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.description_outlined, size: 16, color: AppTheme.accentCyan),
                        title: Text(fileName, style: const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary)),
                        subtitle: Text(filePath, style: const TextStyle(fontSize: 10.5, color: AppTheme.textTertiary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textTertiary),
                          onPressed: () => setState(() => _selectedFiles.removeAt(idx)),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 14),

          // Target Folder
          const Text(
            'IMPORT INTO FOLDER / DOCUMENT',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _filesParentId,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceSecondary,
                hint: const Text('Root Workspace (Top Level)', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('📁 Root Workspace (Top Level)', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                  ),
                  for (final n in notes)
                    DropdownMenuItem<String?>(
                      value: n.id,
                      child: Text('📄 ${n.title}', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                    ),
                ],
                onChanged: (val) => setState(() => _filesParentId = val),
              ),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _selectedFiles.isEmpty ? null : () => _startFilesImport(context, storage),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('Import ${_selectedFiles.length} File(s)', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppTheme.surfaceSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Custom Paste Tab
  Widget _buildPasteTab(BuildContext context, StorageService storage, List<dynamic> notes) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'DOCUMENT TITLE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _pasteTitleCtrl,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Graph Algorithms Note',
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.glassBorder)),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'PASTE MARKDOWN OR CODE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 6),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: TextField(
              controller: _pasteContentCtrl,
              maxLines: null,
              style: const TextStyle(fontSize: 12.5, fontFamily: 'Consolas', color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '# Title\n\nExplanation...\n\n```java\npublic class Solution {\n    // code\n}\n```',
                hintStyle: TextStyle(color: AppTheme.textTertiary, fontFamily: 'Consolas'),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () => _startPasteImport(context, storage),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Import Markdown as Notion Blocks', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
