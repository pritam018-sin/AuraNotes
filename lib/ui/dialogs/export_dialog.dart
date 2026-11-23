import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _copied = false;
  bool _isExporting = false;

  Future<void> _printOrSaveAsPdf(BuildContext context, StorageService storage) async {
    final note = storage.activeNote;
    if (note == null) return;

    setState(() => _isExporting = true);
    try {
      final html = storage.exportActiveNoteAsHtml();
      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final printFile = File('${tempDir.path}\\AuraNotes_Print_${sanitizedTitle}.html');
      await printFile.writeAsString(html);

      // Open in system default browser which auto-triggers the print dialog (Save as PDF)
      await Process.run('cmd', ['/c', 'start', '', printFile.path]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.print_rounded, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Opening print preview! In the browser, choose "Save as PDF" to download.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.surfaceSecondary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open print preview: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveAsMarkdownFile(BuildContext context, StorageService storage) async {
    final note = storage.activeNote;
    if (note == null) return;

    setState(() => _isExporting = true);
    try {
      final markdown = storage.exportActiveNoteAsMarkdown();
      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {
        targetDir = null;
      }
      targetDir ??= await getApplicationDocumentsDirectory();

      final vaultDir = Directory('${targetDir.path}\\AuraNotes_Vault');
      if (!vaultDir.existsSync()) {
        vaultDir.createSync(recursive: true);
      }

      final sanitizedTitle = note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final exportFile = File('${vaultDir.path}\\${sanitizedTitle}.md');
      await exportFile.writeAsString(markdown);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved note to: ${exportFile.path}'),
            backgroundColor: AppTheme.surfaceSecondary,
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: AppTheme.accentCyan,
              onPressed: () {
                Process.run('explorer.exe', ['/select,', exportFile.path]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save file: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _openMasterNotesFolder(BuildContext context) {
    const masterNotesPath = r'c:\Users\DELL\WebDevPractice\chrome\Master-Notes';
    Process.run('explorer.exe', [masterNotesPath]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opened Master-Notes folder in File Explorer!'),
        backgroundColor: AppTheme.surfaceSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final activeNote = storage.activeNote;
    final markdownContent = storage.exportActiveNoteAsMarkdown();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 680,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorderActive),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.85),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.file_upload_outlined,
                      color: AppTheme.accentCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export & Notion Master Prep',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeNote != null
                            ? 'Selected: ${activeNote.icon} ${activeNote.title}'
                            : 'No note selected',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.glassBorder),

            // Preview Box
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Markdown Preview (.md)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _openMasterNotesFolder(context),
                        icon: const Icon(Icons.folder_special_rounded, size: 14, color: AppTheme.accentCyan),
                        label: const Text(
                          'Open Master-Notes Folder',
                          style: TextStyle(fontSize: 12, color: AppTheme.accentCyan, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        markdownContent.isNotEmpty
                            ? markdownContent
                            : '# Select a note to export',
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 12,
                          color: Color(0xFFE2E8F0),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons Row 1: Print / PDF & Download File
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : () => _printOrSaveAsPdf(context, storage),
                          icon: const Icon(Icons.print_rounded, size: 16, color: Colors.black),
                          label: const Text(
                            'Print / Convert to PDF',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentCyan,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting ? null : () => _saveAsMarkdownFile(context, storage),
                          icon: const Icon(Icons.download_rounded, size: 16, color: AppTheme.accentEmerald),
                          label: const Text(
                            'Save to File (.md)',
                            style: TextStyle(
                              color: AppTheme.accentEmerald,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.accentEmerald),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Action Buttons Row 2: Copy Markdown & Close
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: markdownContent));
                            setState(() => _copied = true);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) setState(() => _copied = false);
                            });
                          },
                          icon: Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                            size: 15,
                            color: _copied ? AppTheme.accentEmerald : AppTheme.textSecondary,
                          ),
                          label: Text(
                            _copied ? 'Copied Markdown!' : 'Copy Markdown Text',
                            style: TextStyle(
                              color: _copied ? AppTheme.accentEmerald : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _copied ? AppTheme.accentEmerald : AppTheme.glassBorder,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
