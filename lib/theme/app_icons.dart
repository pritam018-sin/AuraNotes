import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Centralized modern developer icon system.
/// Zero cartoon emojis. Clean VS Code / Cursor / Linear developer aesthetics.
class AppIcons {
  static const IconData folder = Icons.folder_outlined;
  static const IconData folderOpen = Icons.folder_open_rounded;
  static const IconData document = Icons.description_outlined;
  static const IconData code = Icons.code_rounded;
  static const IconData terminal = Icons.terminal_rounded;
  static const IconData tree = Icons.account_tree_outlined;
  static const IconData database = Icons.storage_rounded;
  static const IconData architecture = Icons.layers_outlined;
  static const IconData target = Icons.crisis_alert_rounded;
  static const IconData book = Icons.menu_book_rounded;
  static const IconData bolt = Icons.bolt_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData arrowNest = Icons.subdirectory_arrow_right_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData chevronDown = Icons.keyboard_arrow_down_rounded;

  /// Resolves any string or legacy emoji key into a modern developer IconData.
  static IconData resolveIconData(String? iconKey, {bool isFolder = false, bool isExpanded = false}) {
    if (isFolder) {
      return isExpanded ? folderOpen : folder;
    }

    if (iconKey == null || iconKey.isEmpty) {
      return document;
    }

    switch (iconKey.toLowerCase().trim()) {
      case 'code':
      case 'java':
      case 'cpp':
      case 'c++':
      case 'python':
      case 'js':
      case 'javascript':
      case 'ts':
      case 'typescript':
      case '💻':
      case '🔥':
        return code;

      case 'terminal':
      case 'bash':
      case 'shell':
      case 'cli':
      case '⚡':
      case '🚀':
        return terminal;

      case 'tree':
      case 'algorithm':
      case 'dsa':
      case 'graph':
      case 'dp':
      case 'array':
      case 'recursion':
      case '🧠':
        return tree;

      case 'database':
      case 'sql':
      case 'db':
      case 'nosql':
      case 'redis':
      case '📊':
        return database;

      case 'architecture':
      case 'system':
      case 'design':
      case 'hlld':
      case 'lld':
      case 'hld':
      case '🏗️':
        return architecture;

      case 'target':
      case 'core':
      case 'interview':
      case 'sde':
      case '🎯':
        return target;

      case 'book':
      case 'notes':
      case 'archive':
      case 'library':
      case '📚':
        return book;

      case 'folder':
      case '📁':
      case '📂':
        return isExpanded ? folderOpen : folder;

      case 'document':
      case 'doc':
      case 'page':
      case 'post':
      case 'markdown':
      case 'md':
      case '📄':
      case '📝':
      case '💡':
      default:
        return document;
    }
  }

  /// Builds a rendered modern icon widget with sleek styling.
  static Widget buildModernIcon(
    String? iconKey, {
    double size = 15,
    Color? color,
    bool isFolder = false,
    bool isExpanded = false,
  }) {
    final iconData = resolveIconData(iconKey, isFolder: isFolder, isExpanded: isExpanded);
    return Icon(
      iconData,
      size: size,
      color: color ?? AppTheme.accentCyan,
    );
  }
}
