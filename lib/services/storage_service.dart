import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../theme/app_theme.dart';

class StorageService extends ChangeNotifier {
  static const String _keyNotes = 'auranotes_documents_v2';
  static const String _keyKanban = 'auranotes_kanban_v2';
  static const String _keyGrid = 'auranotes_grid_v2';
  static const String _keyActiveNote = 'auranotes_active_note_id';

  final SharedPreferences _prefs;

  List<NoteDocument> _notes = [];
  List<KanbanColumn> _kanbanColumns = [];
  List<GridRowItem> _gridRows = [];
  String? _activeNoteId;
  int _activeViewIndex = 0; // 0: Document Editor, 1: Kanban Board, 2: Database Grid
  Timer? _saveNotesDebounceTimer;

  void flushSave() {
    if (_saveNotesDebounceTimer?.isActive ?? false) {
      _saveNotesDebounceTimer?.cancel();
      _saveNotes();
    }
  }

  @override
  void dispose() {
    flushSave();
    super.dispose();
  }

  StorageService(this._prefs) {
    _loadAll();
  }

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    AppTheme.isDark = _isDarkMode;
    _prefs.setBool('auranotes_is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  // Getters
  List<NoteDocument> get notes => _notes;
  List<KanbanColumn> get kanbanColumns => _kanbanColumns;
  List<GridRowItem> get gridRows => _gridRows;
  String? get activeNoteId => _activeNoteId;
  int get activeViewIndex => _activeViewIndex;

  NoteDocument? get activeNote {
    if (_activeNoteId == null || _notes.isEmpty) return null;
    try {
      return _notes.firstWhere((n) => n.id == _activeNoteId);
    } catch (_) {
      return _notes.isNotEmpty ? _notes.first : null;
    }
  }

  // Hierarchical Queries
  List<NoteDocument> get rootNotes => _notes.where((n) => n.parentId == null).toList();

  List<NoteDocument> getChildNotes(String parentId) =>
      _notes.where((n) => n.parentId == parentId).toList();

  List<NoteDocument> getBreadcrumbTrail(String noteId) {
    final trail = <NoteDocument>[];
    String? currentId = noteId;
    while (currentId != null) {
      final note = _notes.cast<NoteDocument?>().firstWhere(
            (n) => n?.id == currentId,
            orElse: () => null,
          );
      if (note != null) {
        trail.insert(0, note);
        currentId = note.parentId;
      } else {
        break;
      }
    }
    return trail;
  }

  static int _idCounter = 0;
  String? _jumpTargetBlockId;
  String? get jumpTargetBlockId => _jumpTargetBlockId;

  void scrollToBlock(String blockId) {
    _jumpTargetBlockId = blockId;
    _activeViewIndex = 0; // Switch to Editor
    notifyListeners();
  }

  void clearJumpTarget() {
    _jumpTargetBlockId = null;
  }

  List<BlockItem> getHeadingsForNote(String noteId) {
    try {
      final n = _notes.firstWhere((x) => x.id == noteId);
      return n.blocks.where((b) =>
        b.type == BlockType.heading1 ||
        b.type == BlockType.heading2 ||
        b.type == BlockType.heading3
      ).toList();
    } catch (_) {
      return [];
    }
  }

  void setActiveView(int index) {
    _activeViewIndex = index;
    notifyListeners();
  }

  void setActiveNote(String id) {
    flushSave();
    _activeNoteId = id;
    _prefs.setString(_keyActiveNote, id);
    _activeViewIndex = 0; // Switch to Editor
    notifyListeners();
  }

  // Notes CRUD & Sub-pages
  NoteDocument createNote({
    String? parentId,
    String title = 'Untitled Document',
    String icon = '📄',
    String coverGradient = 'cyan',
    List<BlockItem>? initialBlocks,
    bool notify = true,
    bool autoSetActive = true,
  }) {
    flushSave();
    final newId = 'note_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
    final newNote = NoteDocument(
      id: newId,
      parentId: parentId,
      title: title,
      icon: icon,
      coverGradient: coverGradient,
      workspaceId: 'default',
      blocks: initialBlocks ??
          [
            BlockItem(
              id: 'b_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}',
              type: BlockType.heading1,
              content: title,
            ),
            BlockItem(
              id: 'b_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}',
              type: BlockType.paragraph,
              content: 'Type / for commands, or write freely...',
            ),
          ],
    );

    _notes.insert(0, newNote);

    // If it's a child page, link it inside the parent note as a Sub-Page block
    if (parentId != null) {
      final parentIdx = _notes.indexWhere((n) => n.id == parentId);
      if (parentIdx != -1) {
        _notes[parentIdx].blocks.add(
              BlockItem(
                id: 'b_sub_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}',
                type: BlockType.subpage,
                content: title,
                subpageId: newId,
              ),
            );
      }
    }

    if (autoSetActive) {
      _activeNoteId = newNote.id;
      _activeViewIndex = 0;
    }
    if (notify) {
      _saveNotes();
      notifyListeners();
    }
    return newNote;
  }

  void updateNote(NoteDocument note, {bool immediate = false, bool notify = true}) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      note.updatedAt = DateTime.now();
      _notes[index] = note;

      // If this note has a parent, update any Sub-page block in parent referencing it
      if (note.parentId != null) {
        final parentIdx = _notes.indexWhere((n) => n.id == note.parentId);
        if (parentIdx != -1) {
          for (final b in _notes[parentIdx].blocks) {
            if (b.type == BlockType.subpage && b.subpageId == note.id) {
              b.content = note.title;
            }
          }
        }
      }

      if (immediate) {
        _saveNotesDebounceTimer?.cancel();
        _saveNotes();
        if (notify) notifyListeners();
      } else {
        _saveNotesDebounceTimer?.cancel();
        _saveNotesDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          _saveNotes();
          if (notify) notifyListeners();
        });
      }
    }
  }

  void deleteNote(String id) {
    flushSave();
    // Collect note and all its sub-pages recursively
    final toDelete = <String>{id};
    void collectChildren(String pId) {
      final children = _notes.where((n) => n.parentId == pId).map((n) => n.id).toList();
      for (final c in children) {
        toDelete.add(c);
        collectChildren(c);
      }
    }

    collectChildren(id);

    _notes.removeWhere((n) => toDelete.contains(n.id));

    // Remove any subpage blocks from remaining notes
    for (final note in _notes) {
      note.blocks.removeWhere(
        (b) => b.type == BlockType.subpage && toDelete.contains(b.subpageId),
      );
    }

    if (toDelete.contains(_activeNoteId)) {
      _activeNoteId = _notes.isNotEmpty ? _notes.first.id : null;
    }

    _saveNotes();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final note = _notes.firstWhere((n) => n.id == id, orElse: () => _notes.first);
    note.isFavorite = !note.isFavorite;
    _saveNotes();
    notifyListeners();
  }

  void togglePinned(String id) {
    final note = _notes.firstWhere((n) => n.id == id, orElse: () => _notes.first);
    note.isPinned = !note.isPinned;
    _saveNotes();
    notifyListeners();
  }

  static String _cleanHeadingStars(String raw) {
    var s = raw.trim();
    while ((s.startsWith('**') && s.endsWith('**') && s.length >= 4) ||
           (s.startsWith('__') && s.endsWith('__') && s.length >= 4)) {
      s = s.substring(2, s.length - 2).trim();
    }
    return s.trim();
  }

  NoteDocument importDocument({
    required String title,
    required String content,
    String? parentId,
    bool notify = true,
    bool autoSetActive = true,
  }) {
    final lines = content.split(RegExp(r'\r?\n'));
    final blocks = <BlockItem>[];

    bool inCodeBlock = false;
    String codeLang = 'javascript';
    final codeBuffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().startsWith('```')) {
        if (!inCodeBlock) {
          inCodeBlock = true;
          codeLang = line.trim().replaceAll('`', '').trim();
          if (codeLang.isEmpty) codeLang = 'code';
          codeBuffer.clear();
        } else {
          inCodeBlock = false;
          final snippet = codeBuffer.toString().trimRight();
          String finalLang = codeLang.toLowerCase();
          if (finalLang == 'code' || finalLang.isEmpty) {
            if (snippet.contains('public static void') || snippet.contains('class ') || snippet.contains('System.out')) {
              finalLang = 'java';
            } else if (snippet.contains('#include') || snippet.contains('std::')) {
              finalLang = 'c++';
            } else if (snippet.contains('def ') || snippet.contains('import numpy')) {
              finalLang = 'python';
            } else {
              finalLang = 'java';
            }
          }
          blocks.add(
            BlockItem(
              id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
              type: BlockType.code,
              content: snippet,
              language: finalLang,
            ),
          );
        }
        continue;
      }

      if (inCodeBlock) {
        codeBuffer.writeln(line);
        continue;
      }

      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check for Markdown Images: ![alt](url)
      final imageMatch = RegExp(r'^!\[(.*?)\]\((.*?)\)$').firstMatch(trimmed);
      if (imageMatch != null) {
        final alt = imageMatch.group(1)?.trim() ?? '';
        final url = imageMatch.group(2)?.trim() ?? '';
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.image,
            content: url,
            caption: alt.isNotEmpty ? alt : null,
          ),
        );
        continue;
      }

      if (trimmed.startsWith('# ')) {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.heading1,
            content: _cleanHeadingStars(trimmed.substring(2)),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.heading2,
            content: _cleanHeadingStars(trimmed.substring(3)),
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.heading3,
            content: _cleanHeadingStars(trimmed.substring(4)),
          ),
        );
      } else if (trimmed.startsWith('#### ')) {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.heading3,
            content: _cleanHeadingStars(trimmed.substring(5)),
          ),
        );
      } else if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ')) {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.todo,
            content: trimmed.substring(6).trim(),
            isCompleted: trimmed.startsWith('- [x] '),
          ),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.bullet,
            content: trimmed.substring(2).trim(),
          ),
        );
      } else if (trimmed.startsWith('> ')) {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.quote,
            content: trimmed.substring(2).trim(),
          ),
        );
      } else if (trimmed == '---' || trimmed == '***') {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.divider,
            content: '',
          ),
        );
      } else {
        blocks.add(
          BlockItem(
            id: 'b_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: BlockType.paragraph,
            content: trimmed,
          ),
        );
      }
    }

    if (blocks.isEmpty) {
      blocks.add(
        BlockItem(
          id: 'b_imp_0',
          type: BlockType.paragraph,
          content: content,
        ),
      );
    }

    return createNote(
      parentId: parentId,
      title: title.replaceAll(RegExp(r'\.(md|txt|json)$', caseSensitive: false), ''),
      icon: 'document',
      coverGradient: 'violet',
      initialBlocks: blocks,
      notify: notify,
      autoSetActive: autoSetActive,
    );
  }

  /// Clean all markdown stars and asterisks in headings and callouts for a document
  int cleanNoteMarkdownStars(String noteId) {
    final idx = _notes.indexWhere((n) => n.id == noteId);
    if (idx == -1) return 0;
    final note = _notes[idx];
    int cleanedCount = 0;

    for (final b in note.blocks) {
      if (b.type == BlockType.heading1 ||
          b.type == BlockType.heading2 ||
          b.type == BlockType.heading3 ||
          b.type == BlockType.callout) {
        var s = b.content.trim();
        final orig = s;
        while ((s.startsWith('**') && s.endsWith('**') && s.length >= 4) ||
               (s.startsWith('__') && s.endsWith('__') && s.length >= 4)) {
          s = s.substring(2, s.length - 2).trim();
        }
        if (s != orig) {
          b.content = s;
          cleanedCount++;
        }
      }
    }

    if (cleanedCount > 0) {
      _saveNotes();
      notifyListeners();
    }
    return cleanedCount;
  }

  /// Universal recursive folder importer for ANY user PC directory.
  Future<int> importFolderRecursive({
    required String folderPath,
    String? customTitle,
    String? parentId,
    Function(String status)? onProgress,
  }) async {
    final rootDir = Directory(folderPath);
    if (!rootDir.existsSync()) return 0;

    final dirName = customTitle ?? rootDir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final cleanRootTitle = dirName
        .replaceAll(RegExp(r'^\d+[\.\-_ ]*'), '')
        .replaceAll('-', ' ')
        .trim();

    onProgress?.call('Creating workspace category: $cleanRootTitle');

    final rootNote = createNote(
      parentId: parentId,
      title: cleanRootTitle.isNotEmpty ? cleanRootTitle : 'Imported Folder',
      icon: 'folder',
      coverGradient: 'cyan',
      notify: false,
      autoSetActive: false,
      initialBlocks: [
        BlockItem(
          id: 'b_dir_${DateTime.now().microsecondsSinceEpoch}_1',
          type: BlockType.heading1,
          content: cleanRootTitle,
        ),
        BlockItem(
          id: 'b_dir_${DateTime.now().microsecondsSinceEpoch}_2',
          type: BlockType.callout,
          content: 'Imported local vault from $folderPath. Explore nested topics below.',
          calloutEmoji: 'folder',
        ),
      ],
    );

    int totalImported = 0;

    Future<void> scanDirectory(Directory dir, String currentParentId) async {
      final entries = dir.listSync();
      final subDirs = entries.whereType<Directory>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      final files = entries.whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      // 1. Import files in current directory
      for (final file in files) {
        final pathLower = file.path.toLowerCase();
        if (pathLower.endsWith('.md') || pathLower.endsWith('.txt') || pathLower.endsWith('.json')) {
          try {
            final fileName = file.uri.pathSegments.last;
            final cleanTitle = fileName
                .replaceAll(RegExp(r'\.(md|txt|json)$', caseSensitive: false), '')
                .replaceAll(RegExp(r'^\d+[\.\-_ ]*'), '')
                .replaceAll('-', ' ')
                .trim();

            onProgress?.call('Importing note: $cleanTitle');
            final content = file.readAsStringSync();
            importDocument(
              title: cleanTitle.isNotEmpty ? cleanTitle : fileName,
              content: content,
              parentId: currentParentId,
              notify: false,
              autoSetActive: false,
            );
            totalImported++;
          } catch (_) {}
        }
      }

      // 2. Recursively traverse subdirectories
      for (final subDir in subDirs) {
        final subDirName = subDir.uri.pathSegments.where((s) => s.isNotEmpty).last;
        final cleanSubTitle = subDirName
            .replaceAll(RegExp(r'^\d+[\.\-_ ]*'), '')
            .replaceAll('-', ' ')
            .trim();

        final subNote = createNote(
          parentId: currentParentId,
          title: cleanSubTitle.isNotEmpty ? cleanSubTitle : subDirName,
          icon: 'folder',
          coverGradient: 'violet',
          notify: false,
          autoSetActive: false,
          initialBlocks: [
            BlockItem(
              id: 'b_subf_${DateTime.now().microsecondsSinceEpoch}_1',
              type: BlockType.heading1,
              content: cleanSubTitle,
            ),
          ],
        );

        await scanDirectory(subDir, subNote.id);
      }
    }

    await scanDirectory(rootDir, rootNote.id);

    _activeNoteId = rootNote.id;
    _activeViewIndex = 0;
    _saveNotes();
    notifyListeners();
    return totalImported;
  }

  /// Import multiple local files from PC
  Future<int> importFiles({
    required List<String> filePaths,
    String? parentId,
    Function(String status)? onProgress,
  }) async {
    int count = 0;
    String? firstNoteId;
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (!file.existsSync()) continue;
        final fileName = file.uri.pathSegments.last;
        final cleanTitle = fileName
            .replaceAll(RegExp(r'\.(md|txt|json)$', caseSensitive: false), '')
            .replaceAll(RegExp(r'^\d+[\.\-_ ]*'), '')
            .replaceAll('-', ' ')
            .trim();

        onProgress?.call('Importing: $cleanTitle');
        final content = file.readAsStringSync();
        final doc = importDocument(
          title: cleanTitle.isNotEmpty ? cleanTitle : fileName,
          content: content,
          parentId: parentId,
          notify: false,
          autoSetActive: false,
        );
        firstNoteId ??= doc.id;
        count++;
      } catch (_) {}
    }

    if (firstNoteId != null) {
      _activeNoteId = firstNoteId;
      _activeViewIndex = 0;
    }
    _saveNotes();
    notifyListeners();
    return count;
  }

  Future<int> importVaultSection({
    required String folderPath,
    required String sectionTitle,
    required String sectionIcon,
  }) async {
    return importFolderRecursive(
      folderPath: folderPath,
      customTitle: sectionTitle,
    );
  }

  // Kanban CRUD
  void addKanbanCard(String columnId, KanbanCard card) {
    final col = _kanbanColumns.firstWhere((c) => c.id == columnId);
    col.cards.add(card);
    _saveKanban();
    notifyListeners();
  }

  void updateKanbanCard(String columnId, KanbanCard card) {
    final col = _kanbanColumns.firstWhere((c) => c.id == columnId);
    final idx = col.cards.indexWhere((c) => c.id == card.id);
    if (idx != -1) {
      col.cards[idx] = card;
      _saveKanban();
      notifyListeners();
    }
  }

  void moveKanbanCard(String cardId, String fromColId, String toColId) {
    if (fromColId == toColId) return;
    final fromCol = _kanbanColumns.firstWhere((c) => c.id == fromColId);
    final toCol = _kanbanColumns.firstWhere((c) => c.id == toColId);

    final cardIdx = fromCol.cards.indexWhere((c) => c.id == cardId);
    if (cardIdx != -1) {
      final card = fromCol.cards.removeAt(cardIdx);
      toCol.cards.add(card);
      _saveKanban();
      notifyListeners();
    }
  }

  void deleteKanbanCard(String columnId, String cardId) {
    final col = _kanbanColumns.firstWhere((c) => c.id == columnId);
    col.cards.removeWhere((c) => c.id == cardId);
    _saveKanban();
    notifyListeners();
  }

  void addKanbanColumn(String title, String colorHex) {
    _kanbanColumns.add(
      KanbanColumn(
        id: 'col_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        colorHex: colorHex,
        cards: [],
      ),
    );
    _saveKanban();
    notifyListeners();
  }

  // Grid / Table CRUD
  void addGridRow(GridRowItem row) {
    _gridRows.insert(0, row);
    _saveGrid();
    notifyListeners();
  }

  void updateGridRow(GridRowItem row) {
    final idx = _gridRows.indexWhere((r) => r.id == row.id);
    if (idx != -1) {
      _gridRows[idx] = row;
      _saveGrid();
      notifyListeners();
    }
  }

  void deleteGridRow(String id) {
    _gridRows.removeWhere((r) => r.id == id);
    _saveGrid();
    notifyListeners();
  }

  // Templates
  void applyTemplate(String templateName) {
    if (templateName == 'sprint') {
      final parent = createNote(
        title: 'Engineering Core',
        icon: 'terminal',
        coverGradient: 'violet',
        initialBlocks: [
          BlockItem(id: '1', type: BlockType.heading1, content: 'Engineering Core Hub'),
          BlockItem(id: '2', type: BlockType.callout, content: 'Structured knowledge base with nested sub-pages and specs.', calloutEmoji: 'terminal'),
          BlockItem(id: '3', type: BlockType.heading2, content: 'Active Projects'),
        ],
      );
      // Create nested sub-page!
      createNote(
        parentId: parent.id,
        title: 'Sprint 24: Desktop Architecture',
        icon: 'code',
        initialBlocks: [
          BlockItem(id: 's1', type: BlockType.heading1, content: 'Sprint 24 Tasks'),
          BlockItem(id: 's2', type: BlockType.todo, content: 'Native Acrylic & Window Manager', isCompleted: true),
          BlockItem(id: 's3', type: BlockType.todo, content: 'Nested Sub-pages & File Tree', isCompleted: true),
          BlockItem(id: 's4', type: BlockType.code, content: '// Clean code block with macOS traffic lights\nconst note = await db.getNote(id);', language: 'javascript'),
        ],
      );
    } else if (templateName == 'journal') {
      final now = DateTime.now();
      createNote(
        title: 'Daily Journal (${now.day}/${now.month}/${now.year})',
        icon: 'document',
        coverGradient: 'amber',
        initialBlocks: [
          BlockItem(id: '1', type: BlockType.heading1, content: 'Daily Focus & Reflection'),
          BlockItem(id: '2', type: BlockType.callout, content: '3 Top Priorities: Ship clean Notion-grade design, test sub-pages, verify imports.', calloutEmoji: 'target'),
          BlockItem(id: '3', type: BlockType.todo, content: 'Morning design review', isCompleted: true),
          BlockItem(id: '4', type: BlockType.todo, content: 'Code refactor & cleanup', isCompleted: true),
        ],
      );
    }
  }

  // Export to Markdown
  String exportActiveNoteAsMarkdown() {
    final note = activeNote;
    if (note == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('# ${note.icon} ${note.title}');
    buffer.writeln();

    for (final block in note.blocks) {
      switch (block.type) {
        case BlockType.heading1:
          buffer.writeln('# ${block.content}');
          break;
        case BlockType.heading2:
          buffer.writeln('## ${block.content}');
          break;
        case BlockType.heading3:
          buffer.writeln('### ${block.content}');
          break;
        case BlockType.paragraph:
          buffer.writeln(block.content);
          break;
        case BlockType.todo:
          buffer.writeln('- [${block.isCompleted ? "x" : " "}] ${block.content}');
          break;
        case BlockType.bullet:
          buffer.writeln('- ${block.content}');
          break;
        case BlockType.numbered:
          buffer.writeln('1. ${block.content}');
          break;
        case BlockType.code:
          buffer.writeln('```${block.language}');
          buffer.writeln(block.content);
          buffer.writeln('```');
          break;
        case BlockType.quote:
          buffer.writeln('> ${block.content}');
          break;
        case BlockType.callout:
          buffer.writeln('> ${block.calloutEmoji} **Note:** ${block.content}');
          break;
        case BlockType.divider:
          buffer.writeln('---');
          break;
        case BlockType.table:
          for (final row in block.tableData) {
            buffer.writeln('| ${row.join(' | ')} |');
          }
          break;
        case BlockType.dryRunTrace:
          buffer.writeln('### Algorithm Dry-Run Trace');
          for (final row in block.tableData) {
            buffer.writeln('| ${row.join(' | ')} |');
          }
          break;
        case BlockType.subpage:
          buffer.writeln('[Sub-Page: ${block.content}]');
          break;
        case BlockType.image:
          buffer.writeln('![${block.caption ?? "Image"}](${block.content})');
          break;
        case BlockType.bookmark:
          buffer.writeln('[${block.caption ?? "Bookmark"}](${block.content})');
          break;
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String exportActiveNoteAsHtml() {
    final note = activeNote;
    if (note == null) return '<html><body><p>No note selected</p></body></html>';

    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('<title>${_escapeHtml(note.title)}</title>');
    buffer.writeln('''<style>
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');
      
      :root {
        --bg-color: #0d1117;
        --card-bg: #161b22;
        --text-primary: #e6edf3;
        --text-secondary: #8b949e;
        --border-color: #30363d;
        --accent-cyan: #00e5ff;
        --accent-emerald: #10b981;
      }
      
      body {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        background-color: var(--bg-color);
        color: var(--text-primary);
        max-width: 860px;
        margin: 40px auto;
        padding: 0 24px;
        line-height: 1.65;
        font-size: 15px;
      }

      .header {
        border-bottom: 1px solid var(--border-color);
        padding-bottom: 24px;
        margin-bottom: 32px;
      }

      .icon {
        font-size: 42px;
        margin-bottom: 8px;
        display: inline-block;
      }

      h1.title {
        font-size: 32px;
        font-weight: 700;
        margin: 0 0 8px 0;
        color: #ffffff;
      }

      .meta {
        font-size: 13px;
        color: var(--text-secondary);
      }

      h1, h2, h3 {
        color: #ffffff;
        font-weight: 600;
        margin-top: 28px;
        margin-bottom: 12px;
      }
      
      h1 { font-size: 24px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px; }
      h2 { font-size: 20px; }
      h3 { font-size: 16px; }

      p {
        margin: 12px 0;
        color: #c9d1d9;
      }

      .todo-item {
        display: flex;
        align-items: center;
        gap: 10px;
        margin: 8px 0;
      }

      .todo-checkbox {
        width: 18px;
        height: 18px;
        border-radius: 4px;
        border: 2px solid #58a6ff;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
        font-weight: bold;
        color: #58a6ff;
      }

      .todo-completed {
        text-decoration: line-through;
        color: var(--text-secondary);
      }

      ul, ol {
        margin: 10px 0 10px 24px;
        padding: 0;
      }

      li {
        margin: 4px 0;
      }

      .code-container {
        background-color: var(--card-bg);
        border: 1px solid var(--border-color);
        border-radius: 8px;
        margin: 18px 0;
        overflow: hidden;
      }

      .code-header {
        background-color: #21262d;
        padding: 8px 14px;
        font-size: 12px;
        font-family: 'JetBrains Mono', monospace;
        color: var(--text-secondary);
        display: flex;
        align-items: center;
        justify-content: space-between;
        border-bottom: 1px solid var(--border-color);
      }

      .mac-dots {
        display: flex;
        gap: 6px;
      }

      .mac-dot {
        width: 10px;
        height: 10px;
        border-radius: 50%;
      }

      .dot-red { background-color: #ff5f56; }
      .dot-yellow { background-color: #ffbd2e; }
      .dot-green { background-color: #27c93f; }

      pre {
        margin: 0;
        padding: 16px;
        font-family: 'JetBrains Mono', monospace;
        font-size: 13.5px;
        overflow-x: auto;
        color: #f0f6fc;
        line-height: 1.55;
      }

      blockquote {
        border-left: 4px solid var(--accent-cyan);
        margin: 16px 0;
        padding: 8px 16px;
        background-color: rgba(0, 229, 255, 0.05);
        color: #d2a8ff;
        border-radius: 0 8px 8px 0;
      }

      .callout {
        display: flex;
        gap: 12px;
        align-items: flex-start;
        padding: 14px 18px;
        background: rgba(16, 185, 129, 0.08);
        border: 1px solid rgba(16, 185, 129, 0.3);
        border-radius: 8px;
        margin: 16px 0;
      }

      .callout-icon {
        font-size: 20px;
      }

      hr {
        border: 0;
        height: 1px;
        background: var(--border-color);
        margin: 28px 0;
      }

      table {
        width: 100%;
        border-collapse: collapse;
        margin: 18px 0;
      }

      th, td {
        border: 1px solid var(--border-color);
        padding: 10px 14px;
        text-align: left;
      }

      th {
        background-color: #21262d;
        font-weight: 600;
      }

      /* Print Styles */
      @media print {
        body {
          background-color: #ffffff !important;
          color: #1a202c !important;
          max-width: 100% !important;
          margin: 0 !important;
          padding: 12mm !important;
        }

        h1.title, h1, h2, h3 {
          color: #000000 !important;
        }

        p, li, th, td {
          color: #2d3748 !important;
        }

        .code-container {
          background-color: #f7fafc !important;
          border: 1px solid #e2e8f0 !important;
          break-inside: avoid;
        }

        .code-header {
          background-color: #edf2f7 !important;
          color: #4a5568 !important;
          border-bottom: 1px solid #e2e8f0 !important;
        }

        pre {
          color: #1a202c !important;
        }

        blockquote {
          background-color: #f0fdf4 !important;
          border-left: 4px solid #10b981 !important;
          color: #065f46 !important;
        }

        .callout {
          background-color: #f0fdf4 !important;
          border: 1px solid #a7f3d0 !important;
          color: #065f46 !important;
        }

        .todo-checkbox {
          border-color: #4a5568 !important;
        }
      }
    </style>''');
    buffer.writeln('''<script>
      window.addEventListener('DOMContentLoaded', () => {
        setTimeout(() => {
          window.print();
        }, 350);
      });
    </script>''');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    buffer.writeln('<div class="header">');
    buffer.writeln('<div class="icon">${note.icon}</div>');
    buffer.writeln('<h1 class="title">${_escapeHtml(note.title)}</h1>');
    buffer.writeln('<div class="meta">Exported from AuraNotes &bull; ${DateFormat.yMMMd().format(note.updatedAt)}</div>');
    buffer.writeln('</div>');

    for (final block in note.blocks) {
      switch (block.type) {
        case BlockType.heading1:
          buffer.writeln('<h1>${_escapeHtml(block.content)}</h1>');
          break;
        case BlockType.heading2:
          buffer.writeln('<h2>${_escapeHtml(block.content)}</h2>');
          break;
        case BlockType.heading3:
          buffer.writeln('<h3>${_escapeHtml(block.content)}</h3>');
          break;
        case BlockType.paragraph:
          buffer.writeln('<p>${_escapeHtml(block.content)}</p>');
          break;
        case BlockType.todo:
          buffer.writeln('<div class="todo-item">');
          buffer.writeln('<span class="todo-checkbox">${block.isCompleted ? '✓' : ''}</span>');
          buffer.writeln('<span class="${block.isCompleted ? 'todo-completed' : ''}">${_escapeHtml(block.content)}</span>');
          buffer.writeln('</div>');
          break;
        case BlockType.bullet:
          buffer.writeln('<ul><li>${_escapeHtml(block.content)}</li></ul>');
          break;
        case BlockType.numbered:
          buffer.writeln('<ol><li>${_escapeHtml(block.content)}</li></ol>');
          break;
        case BlockType.code:
          buffer.writeln('<div class="code-container">');
          buffer.writeln('<div class="code-header">');
          buffer.writeln('<div class="mac-dots"><div class="mac-dot dot-red"></div><div class="mac-dot dot-yellow"></div><div class="mac-dot dot-green"></div></div>');
          buffer.writeln('<span>${block.language.toUpperCase()}</span>');
          buffer.writeln('</div>');
          buffer.writeln('<pre><code>${_escapeHtml(block.content)}</code></pre>');
          buffer.writeln('</div>');
          break;
        case BlockType.quote:
          buffer.writeln('<blockquote>${_escapeHtml(block.content)}</blockquote>');
          break;
        case BlockType.callout:
          buffer.writeln('<div class="callout">');
          buffer.writeln('<div class="callout-icon">${block.calloutEmoji}</div>');
          buffer.writeln('<div><strong>Note:</strong> ${_escapeHtml(block.content)}</div>');
          buffer.writeln('</div>');
          break;
        case BlockType.divider:
          buffer.writeln('<hr>');
          break;
        case BlockType.table:
          buffer.writeln('<table>');
          for (int i = 0; i < block.tableData.length; i++) {
            final row = block.tableData[i];
            buffer.writeln('<tr>');
            for (final cell in row) {
              if (i == 0) {
                buffer.writeln('<th>${_escapeHtml(cell)}</th>');
              } else {
                buffer.writeln('<td>${_escapeHtml(cell)}</td>');
              }
            }
            buffer.writeln('</tr>');
          }
          buffer.writeln('</table>');
          break;
        case BlockType.dryRunTrace:
          buffer.writeln('<div style="margin: 16px 0; padding: 12px; background: #161b22; border: 1px solid #30363d; border-radius: 8px;">');
          buffer.writeln('<h4 style="margin: 0 0 10px 0; color: #58a6ff;">Algorithm Dry-Run Logic Trace</h4>');
          buffer.writeln('<table>');
          for (int i = 0; i < block.tableData.length; i++) {
            final row = block.tableData[i];
            buffer.writeln('<tr>');
            for (final cell in row) {
              if (i == 0) {
                buffer.writeln('<th>${_escapeHtml(cell)}</th>');
              } else {
                buffer.writeln('<td>${_escapeHtml(cell)}</td>');
              }
            }
            buffer.writeln('</tr>');
          }
          buffer.writeln('</table>');
          buffer.writeln('</div>');
          break;
        case BlockType.subpage:
          buffer.writeln('<p><strong>📄 Sub-Page:</strong> ${_escapeHtml(block.content)}</p>');
          break;
        case BlockType.image:
          buffer.writeln('<div style="margin: 16px 0; text-align: center;"><img src="${_escapeHtml(block.content)}" alt="${_escapeHtml(block.caption ?? "")}" style="max-width: 100%; border-radius: 8px;"/><div style="font-size: 12px; color: #8b949e; margin-top: 4px;">${_escapeHtml(block.caption ?? "")}</div></div>');
          break;
        case BlockType.bookmark:
          buffer.writeln('<p><a href="${_escapeHtml(block.content)}">${_escapeHtml(block.caption ?? block.content)}</a></p>');
          break;
      }
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // Persistence helpers
  void _saveNotes() {
    final jsonList = _notes.map((n) => n.toJson()).toList();
    _prefs.setString(_keyNotes, jsonEncode(jsonList));
  }

  void _saveKanban() {
    final jsonList = _kanbanColumns.map((c) => c.toJson()).toList();
    _prefs.setString(_keyKanban, jsonEncode(jsonList));
  }

  void _saveGrid() {
    final jsonList = _gridRows.map((r) => r.toJson()).toList();
    _prefs.setString(_keyGrid, jsonEncode(jsonList));
  }

  void _loadAll() {
    // 0. Load Theme
    _isDarkMode = _prefs.getBool('auranotes_is_dark_mode') ?? true;
    AppTheme.isDark = _isDarkMode;

    // 1. Load Notes
    final notesRaw = _prefs.getString(_keyNotes);
    if (notesRaw != null && notesRaw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(notesRaw);
        _notes = decoded.map((item) => NoteDocument.fromJson(item)).toList();
      } catch (_) {
        _initDefaultNotes();
      }
    } else {
      _initDefaultNotes();
    }

    // Auto-clean heading stars across all notes silently on load
    bool modifiedHeadings = false;
    for (final note in _notes) {
      for (final b in note.blocks) {
        if (b.type == BlockType.heading1 ||
            b.type == BlockType.heading2 ||
            b.type == BlockType.heading3) {
          var s = b.content.trim();
          final orig = s;
          while ((s.startsWith('**') && s.endsWith('**') && s.length >= 4) ||
                 (s.startsWith('__') && s.endsWith('__') && s.length >= 4)) {
            s = s.substring(2, s.length - 2).trim();
          }
          if (s != orig) {
            b.content = s;
            modifiedHeadings = true;
          }
        }
      }
    }
    if (modifiedHeadings) {
      _saveNotes();
    }

    // 2. Load Kanban
    final kanbanRaw = _prefs.getString(_keyKanban);
    if (kanbanRaw != null && kanbanRaw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(kanbanRaw);
        _kanbanColumns = decoded.map((item) => KanbanColumn.fromJson(item)).toList();
      } catch (_) {
        _initDefaultKanban();
      }
    } else {
      _initDefaultKanban();
    }

    // 3. Load Grid
    final gridRaw = _prefs.getString(_keyGrid);
    if (gridRaw != null && gridRaw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(gridRaw);
        _gridRows = decoded.map((item) => GridRowItem.fromJson(item)).toList();
      } catch (_) {
        _initDefaultGrid();
      }
    } else {
      _initDefaultGrid();
    }

    // Active Note
    _activeNoteId = _prefs.getString(_keyActiveNote);
    if (_activeNoteId == null || !_notes.any((n) => n.id == _activeNoteId)) {
      if (_notes.isNotEmpty) {
        _activeNoteId = _notes.first.id;
      }
    }
  }

  void _initDefaultNotes() {
    final welcomeNote = NoteDocument(
      id: 'note_welcome',
      title: 'Welcome to AuraNotes',
      icon: 'terminal',
      coverGradient: 'cyan',
      workspaceId: 'default',
      isPinned: true,
      blocks: [
        BlockItem(id: '1', type: BlockType.heading1, content: 'AuraNotes Workspace'),
        BlockItem(
          id: '2',
          type: BlockType.callout,
          content: 'Clean Notion-styled workspace with hierarchical nested notes, Kanban boards, and database tables.',
          calloutEmoji: 'terminal',
        ),
        BlockItem(id: '3', type: BlockType.heading2, content: 'Nested Sub-Pages & Structured Notes'),
        BlockItem(
          id: 'sub_demo_1',
          type: BlockType.subpage,
          content: 'Project Roadmap & Technical Spec',
          subpageId: 'note_roadmap',
        ),
        BlockItem(id: '4', type: BlockType.heading2, content: 'Code Snippets with Mac Traffic Lights'),
        BlockItem(
          id: '5',
          type: BlockType.code,
          content: '// Smooth native D3D11 accelerated workspace\nconst aura = new AuraWorkspace({\n  theme: "obsidian-velvet",\n  offlineFirst: true\n});',
          language: 'javascript',
        ),
        BlockItem(id: '6', type: BlockType.heading2, content: 'Interactive Algorithm Visualizer & Dry-Run Trace'),
        BlockItem(
          id: 'dry_demo_1',
          type: BlockType.dryRunTrace,
          content: '1, 3, 4, 7, 8, 12',
          tableData: [
            ['Step', 'left', 'right', 'mid', 'nums[mid]', 'target', 'Action'],
            ['1', '0', '5', '2', '4', '7', 'left = mid + 1'],
            ['2', '3', '5', '4', '8', '7', 'right = mid - 1'],
            ['3', '3', '3', '3', '7', '7', 'nums[mid] == target (Found at index 3!)'],
          ],
        ),
      ],
    );

    final childNote = NoteDocument(
      id: 'note_roadmap',
      parentId: 'note_welcome',
      title: 'Project Roadmap & Technical Spec',
      icon: 'code',
      coverGradient: 'violet',
      workspaceId: 'default',
      blocks: [
        BlockItem(id: 'r1', type: BlockType.heading1, content: 'Architecture Specs & Tasks'),
        BlockItem(id: 'r2', type: BlockType.todo, content: 'Nested sub-page tree hierarchy in sidebar', isCompleted: true),
        BlockItem(id: 'r3', type: BlockType.todo, content: 'Mac traffic lights (🔴 🟡 🟢) on code blocks', isCompleted: true),
        BlockItem(id: 'r4', type: BlockType.todo, content: 'Import notes and documents with 1-click', isCompleted: true),
      ],
    );

    _notes = [welcomeNote, childNote];
    _saveNotes();
  }

  void _initDefaultKanban() {
    _kanbanColumns = [
      KanbanColumn(
        id: 'col_todo',
        title: 'To Do',
        colorHex: '#00E5FF',
        cards: [
          KanbanCard(
            id: 'c1',
            title: 'Hierarchical Sub-Pages',
            description: 'Create nested pages inside notes like Notion',
            priority: 'High',
            dueDate: 'Today',
            checklistTotal: 2,
            checklistDone: 2,
          ),
        ],
      ),
      KanbanColumn(
        id: 'col_progress',
        title: 'In Progress',
        colorHex: '#8B5CF6',
        cards: [
          KanbanCard(
            id: 'c2',
            title: 'Document Import Pipeline',
            description: 'Import Markdown, text files, and JSON notes into workspace',
            priority: 'High',
            dueDate: 'Today',
            checklistTotal: 3,
            checklistDone: 3,
          ),
        ],
      ),
      KanbanColumn(
        id: 'col_done',
        title: 'Done',
        colorHex: '#10B981',
        cards: [
          KanbanCard(
            id: 'c3',
            title: 'Clean Minimalist Notion Canvas',
            description: 'Removed clutter, permanent boxes, and filler stats',
            priority: 'High',
            dueDate: 'Done',
            checklistTotal: 3,
            checklistDone: 3,
          ),
        ],
      ),
    ];
    _saveKanban();
  }

  void _initDefaultGrid() {
    _gridRows = [
      GridRowItem(
        id: 'g1',
        title: 'Nested Document Tree Structure',
        status: 'Done',
        priority: 'High',
        category: 'Workspace',
        date: 'Today',
        assignee: 'Pritam',
      ),
      GridRowItem(
        id: 'g2',
        title: 'Mac Traffic Dots on Code Blocks',
        status: 'Done',
        priority: 'High',
        category: 'UI/UX',
        date: 'Today',
        assignee: 'Pritam',
      ),
      GridRowItem(
        id: 'g3',
        title: '1-Click Document Import',
        status: 'Done',
        priority: 'High',
        category: 'Features',
        date: 'Today',
        assignee: 'Pritam',
      ),
    ];
    _saveGrid();
  }
}
