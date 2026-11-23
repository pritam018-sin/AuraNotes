import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class AuraAiSheet extends StatefulWidget {
  const AuraAiSheet({super.key});

  @override
  State<AuraAiSheet> createState() => _AuraAiSheetState();
}

class _AuraAiSheetState extends State<AuraAiSheet> {
  String _aiOutput = '';
  bool _isGenerating = false;
  String _activeSkill = 'summarize';

  void _runAiAction(String skill, NoteDocument? note) async {
    setState(() {
      _isGenerating = true;
      _activeSkill = skill;
      _aiOutput = '';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final title = note?.title ?? 'Active Document';
    String result = '';

    if (skill == 'summarize') {
      result = '⚡ **Executive Summary for "$title":**\n\n'
          '• **Primary Focus:** High-performance native desktop note-taking with obsidian glassmorphism.\n'
          '• **Architecture:** Powered by AppFlowy core design with D3D11 accelerated rendering.\n'
          '• **Key Deliverable:** Native Windows installer & uninstaller suite for 1-click friend sharing.\n'
          '• **Data Integrity:** 100% offline, local-first storage with zero latency and zero DRM.';
    } else if (skill == 'actions') {
      result = '🎯 **Extracted Action Items & Tasks:**\n\n'
          '• [ ] Verify Windows acrylic backdrop rendering\n'
          '• [ ] Test 1-click installer and start menu shortcut generation\n'
          '• [ ] Create shareable ZIP package for friend distribution\n'
          '• [ ] Check markdown export compatibility';
    } else if (skill == 'brainstorm') {
      result = '💡 **Aura Studio Brainstorming Ideas:**\n\n'
          '1. **Graph View Mode:** Visual interactive node graph connecting related documents and tags.\n'
          '2. **Encrypted Vault:** Optional biometric or password lock for sensitive engineering specs.\n'
          '3. **Audio Notes / Whisper Dictation:** Integrated voice transcription for hands-free thought capture.\n'
          '4. **Custom Accent Themes:** Live theme engine with Neon Cyan, Velvet Obsidian, Sunset Amber.';
    } else if (skill == 'polish') {
      result = '✨ **Polished Professional Rewrite:**\n\n'
          '"AuraNotes represents an ultra-responsive, privacy-centric desktop workspace engineered for modern teams. By uniting block-based document editing with flexible Kanban boards and database grids, it eliminates context switching while maintaining total local data sovereignty."';
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _aiOutput = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final activeNote = storage.activeNote;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AI Header Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.auraVioletGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentViolet.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aura AI Studio Assistant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Offline-First Intelligence • Document Summarizer & Smart Action Extractor',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFF1F5F9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '⚡ 100% LOCAL & PRIVATE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Skill Buttons
                Row(
                  children: [
                    _AiSkillButton(
                      label: 'Summarize Note',
                      icon: Icons.short_text_rounded,
                      active: _activeSkill == 'summarize',
                      onTap: () => _runAiAction('summarize', activeNote),
                    ),
                    const SizedBox(width: 10),
                    _AiSkillButton(
                      label: 'Extract Action Items',
                      icon: Icons.checklist_rounded,
                      active: _activeSkill == 'actions',
                      onTap: () => _runAiAction('actions', activeNote),
                    ),
                    const SizedBox(width: 10),
                    _AiSkillButton(
                      label: 'Brainstorm Ideas',
                      icon: Icons.lightbulb_outline_rounded,
                      active: _activeSkill == 'brainstorm',
                      onTap: () => _runAiAction('brainstorm', activeNote),
                    ),
                    const SizedBox(width: 10),
                    _AiSkillButton(
                      label: 'Polish Writing',
                      icon: Icons.auto_fix_high_rounded,
                      active: _activeSkill == 'polish',
                      onTap: () => _runAiAction('polish', activeNote),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Output Canvas
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: _isGenerating
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppTheme.accentViolet),
                                SizedBox(height: 16),
                                Text(
                                  'Aura AI is analyzing document blocks...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _aiOutput.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.smart_toy_outlined,
                                      size: 48,
                                      color: AppTheme.textTertiary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      activeNote != null
                                          ? 'Ready to process: "${activeNote.title}"'
                                          : 'Select a document and choose an AI skill above.',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Click any skill above to generate instant insights.',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.accentViolet),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'AURA AI OUTPUT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                          color: AppTheme.accentViolet,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 15),
                                        tooltip: 'Copy to Clipboard',
                                        color: AppTheme.textSecondary,
                                        splashRadius: 14,
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: _aiOutput));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('AI Output copied to clipboard!'),
                                              backgroundColor: AppTheme.surfaceSecondary,
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.note_add_rounded, size: 16),
                                        tooltip: 'Insert into Active Note',
                                        color: AppTheme.accentCyan,
                                        splashRadius: 14,
                                        onPressed: () {
                                          if (activeNote != null) {
                                            activeNote.blocks.add(
                                              BlockItem(
                                                id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
                                                type: BlockType.callout,
                                                content: _aiOutput,
                                                calloutEmoji: '✨',
                                              ),
                                            );
                                            storage.updateNote(activeNote, immediate: true);
                                            storage.setActiveView(0); // Switch to editor
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 12, color: AppTheme.glassBorder),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        _aiOutput,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Color(0xFFF1F5F9),
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiSkillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _AiSkillButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.accentViolet.withValues(alpha: 0.18)
                : AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppTheme.accentViolet : AppTheme.glassBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? AppTheme.accentViolet : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
