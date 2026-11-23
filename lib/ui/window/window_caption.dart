import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../dialogs/command_palette.dart';
import '../dialogs/export_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/template_dialog.dart';

class AuraWindowCaption extends StatelessWidget {
  const AuraWindowCaption({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isDark = storage.isDarkMode;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surf(isDark),
        border: Border(
          bottom: BorderSide(color: AppTheme.border(isDark), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left: App Logo & Brand + Drag Region (Zero breadcrumbs here - placed above document card)
          Expanded(
            flex: 3,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: () async {
                final isMax = await windowManager.isMaximized();
                if (isMax) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  // App Icon (Official Desktop Brand Logo)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentViolet.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AuraNotes',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: -0.3,
                      color: AppTheme.txtPrimary(isDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'STUDIO',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: Clean View Switcher Pills (Documents, Board, Grid)
          // Center: Clean View Switcher Pills (Documents, Board, Grid)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.surfSec(isDark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border(isDark)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewPill(
                  context,
                  index: 0,
                  label: 'Document',
                  icon: Icons.article_rounded,
                  active: storage.activeViewIndex == 0,
                  isDark: isDark,
                ),
                const SizedBox(width: 2),
                _buildViewPill(
                  context,
                  index: 1,
                  label: 'Board',
                  icon: Icons.view_kanban_rounded,
                  active: storage.activeViewIndex == 1,
                  isDark: isDark,
                ),
                const SizedBox(width: 2),
                _buildViewPill(
                  context,
                  index: 2,
                  label: 'Grid Table',
                  icon: Icons.table_chart_rounded,
                  active: storage.activeViewIndex == 2,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Right: Action Buttons & Window Controls
          Expanded(
            flex: 3,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Search & Command Palette (Ctrl+K)
                  Tooltip(
                    message: 'Search Notes & Blocks (Ctrl + K)',
                    child: InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const CommandPaletteDialog(),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfSec(isDark),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border(isDark)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 14, color: AppTheme.txtSecondary(isDark)),
                            const SizedBox(width: 6),
                            Text(
                              'Search',
                              style: TextStyle(fontSize: 12, color: AppTheme.txtSecondary(isDark)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ctrl K',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.txtTertiary(isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Import Notes / Documents
                  Tooltip(
                    message: 'Import Document from Markdown / Text',
                    child: IconButton(
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      splashRadius: 16,
                      color: AppTheme.txtSecondary(isDark),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const ImportDialog(),
                      ),
                    ),
                  ),

                  // Template Gallery
                  Tooltip(
                    message: 'Templates',
                    child: IconButton(
                      icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
                      splashRadius: 16,
                      color: AppTheme.txtSecondary(isDark),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const TemplateDialog(),
                      ),
                    ),
                  ),

                  // Export Note
                  Tooltip(
                    message: 'Export Note',
                    child: IconButton(
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      splashRadius: 16,
                      color: AppTheme.txtSecondary(isDark),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const ExportDialog(),
                      ),
                    ),
                  ),

                  // Settings
                  Tooltip(
                    message: 'Settings',
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      splashRadius: 16,
                      color: AppTheme.txtSecondary(isDark),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                    ),
                  ),

                  // Dark / Light Mode Switch
                  Tooltip(
                    message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    child: IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 16,
                      ),
                      splashRadius: 16,
                      color: isDark ? const Color(0xFFFFD166) : const Color(0xFF6366F1),
                      onPressed: () => storage.toggleTheme(),
                    ),
                  ),

                  const SizedBox(width: 4),
                  VerticalDivider(width: 1, indent: 12, endIndent: 12, color: AppTheme.border(isDark)),
                  const SizedBox(width: 4),

                  // Windows Controls
                  _WindowButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Minimize',
                    isDark: isDark,
                    onTap: () => windowManager.minimize(),
                  ),
                  _WindowButton(
                    icon: Icons.crop_square_rounded,
                    tooltip: 'Maximize',
                    isDark: isDark,
                    onTap: () async {
                      final isMax = await windowManager.isMaximized();
                      if (isMax) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                  ),
                  _WindowButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    isClose: true,
                    isDark: isDark,
                    onTap: () => windowManager.close(),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewPill(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
    required bool active,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => context.read<StorageService>().setActiveView(index),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: active ? AppTheme.auraCyanGradient : null,
          color: active ? null : Colors.transparent,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppTheme.accentCyan.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.black : AppTheme.txtSecondary(isDark),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.black : AppTheme.txtSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;
  final bool isDark;

  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        hoverColor: isClose
            ? const Color(0xFFEF4444).withValues(alpha: 0.8)
            : (isDark ? const Color(0x1AFFFFFF) : const Color(0x12000000)),
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Icon(
              icon,
              size: 14,
              color: isClose ? const Color(0xFFF87171) : AppTheme.txtSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}
