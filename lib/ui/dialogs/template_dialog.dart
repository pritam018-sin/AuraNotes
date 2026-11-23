import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class TemplateDialog extends StatelessWidget {
  const TemplateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 720,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
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
                      color: AppTheme.accentViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentViolet.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_rounded,
                      color: AppTheme.accentViolet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1-Click Notion & AppFlowy Templates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select a proven structure to jumpstart your workflow instantly.',
                        style: TextStyle(
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

            // Templates Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _TemplateCard(
                    title: 'Sprint Planning & Tech Spec',
                    icon: 'terminal',
                    badge: 'Engineering',
                    badgeColor: AppTheme.accentViolet,
                    description:
                        'Architecture goals, task checklist, native code snippets, and quote blocks for product teams.',
                    onApply: () {
                      context.read<StorageService>().applyTemplate('sprint');
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 12),
                  _TemplateCard(
                    title: 'Daily Journal & Habit Tracker',
                    icon: 'document',
                    badge: 'Mindset',
                    badgeColor: AppTheme.accentAmber,
                    description:
                        'Morning reflection, top 3 priorities, daily habit checklist, and end-of-day wins.',
                    onApply: () {
                      context.read<StorageService>().applyTemplate('journal');
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 12),
                  _TemplateCard(
                    title: 'Second Brain & Knowledge Hub',
                    icon: 'tree',
                    badge: 'Personal Wiki',
                    badgeColor: AppTheme.accentEmerald,
                    description:
                        'Central repository for engineering concepts, embedded tables, and cross-domain notes.',
                    onApply: () {
                      context.read<StorageService>().applyTemplate('wiki');
                      Navigator.of(context).pop();
                    },
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

class _TemplateCard extends StatelessWidget {
  final String title;
  final String icon;
  final String badge;
  final Color badgeColor;
  final String description;
  final VoidCallback onApply;

  const _TemplateCard({
    required this.title,
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.description,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Icon(
                icon == 'terminal'
                    ? Icons.terminal_rounded
                    : (icon == 'tree' ? Icons.account_tree_outlined : Icons.description_outlined),
                size: 20,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.black),
            label: const Text(
              'Use Template',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
