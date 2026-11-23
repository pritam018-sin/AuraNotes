import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'ui/board/kanban_board_view.dart';
import 'ui/database/grid_table_view.dart';
import 'ui/dialogs/command_palette.dart';
import 'ui/dialogs/import_dialog.dart';
import 'ui/editor/block_editor_view.dart';
import 'ui/sidebar/aura_sidebar.dart';
import 'ui/window/window_caption.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Windows Acrylic/Mica Effect (Matching AuraStudio & AuraPlayer)
  if (Platform.isWindows) {
    try {
      await Window.initialize();
      // Mica gives silky-smooth 60-120 FPS hardware acceleration on Windows without DWM compositor stalls
      await Window.setEffect(
        effect: WindowEffect.mica,
        color: const Color(0xCC090B10),
      );
    } catch (_) {
      try {
        await Window.setEffect(
          effect: WindowEffect.acrylic,
          color: const Color(0xCC090B10),
        );
      } catch (_) {}
    }
  }

  // 2. Initialize WindowManager for frameless window
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1320, 820),
    minimumSize: Size(920, 560),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 3. Initialize Storage Service
  final storageService = await StorageService.init();

  // Handle CLI argument (e.g. double clicked a .md or .note file)
  if (args.isNotEmpty) {
    final filePath = args.first;
    final file = File(filePath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final fileName = filePath.split(RegExp(r'[/\\]')).last;
        storageService.importDocument(
          title: fileName,
          content: content,
        );
      } catch (_) {}
    }
  }

  runApp(
    ChangeNotifierProvider.value(
      value: storageService,
      child: const AuraNotesApp(),
    ),
  );
}

class AuraNotesApp extends StatelessWidget {
  const AuraNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<StorageService, bool>((s) => s.isDarkMode);
    return MaterialApp(
      title: 'AuraNotes — Developer Notes & Algorithm Workspace',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuraNotesShell(),
    );
  }
}

class AuraNotesShell extends StatefulWidget {
  const AuraNotesShell({super.key});

  @override
  State<AuraNotesShell> createState() => _AuraNotesShellState();
}

class _AuraNotesShellState extends State<AuraNotesShell> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<StorageService, bool>((s) => s.isDarkMode);
    final activeViewIndex = context.select<StorageService, int>((s) => s.activeViewIndex);
    final storage = context.read<StorageService>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          showDialog(
            context: context,
            builder: (_) => const CommandPaletteDialog(),
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () {
          showDialog(
            context: context,
            builder: (_) => const ImportDialog(),
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          storage.createNote();
        },
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () {
          storage.setActiveView(0);
        },
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () {
          storage.setActiveView(1);
        },
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () {
          storage.setActiveView(2);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: AppTheme.bg(isDarkMode),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border(isDarkMode), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                children: [
                  // Top Titlebar & Caption
                  const AuraWindowCaption(),

                  // Main App Workspace Body
                  Expanded(
                    child: Row(
                      children: [
                        // Left Sidebar
                        const AuraSidebar(),

                        // Right Primary Workspace View
                        Expanded(
                          child: IndexedStack(
                            index: activeViewIndex,
                            children: const [
                              BlockEditorView(),
                              KanbanBoardView(),
                              GridTableView(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
