import 'package:flutter/material.dart';

/// Professional Notion-style Rich Markdown Text Controller for AuraNotes.
/// Provides real-time visual formatting for **bold**, *italic*, `code`, ~~strike~~, and [links],
/// along with one-click toggles (bold <-> normal vice versa, italic, code, link, delete).
class RichMarkdownTextController extends TextEditingController {
  TextStyle baseStyle;
  bool isDark;

  RichMarkdownTextController({
    super.text,
    required this.baseStyle,
    required this.isDark,
  });

  void updateTheme({required TextStyle newBaseStyle, required bool newIsDark}) {
    if (baseStyle != newBaseStyle || isDark != newIsDark) {
      baseStyle = newBaseStyle;
      isDark = newIsDark;
      notifyListeners();
    }
  }

  // Regex pattern matching Markdown inline styles
  static final RegExp _markdownRegex = RegExp(
    r'(\*\*(.*?)\*\*)' // 1: **bold** (group 2: inner)
    r'|(\*(.*?)\*)'     // 3: *italic* (group 4: inner)
    r'|(`(.*?)`)'       // 5: `inline code` (group 6: inner)
    r'|(~~(.*?)~~)'     // 7: ~~strike~~ (group 8: inner)
    r'|(\[(.*?)\]\((.*?)\))', // 9: [text](url) (group 10: text, 11: url)
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveBase = style ?? baseStyle;
    final List<TextSpan> children = [];
    final textVal = text;

    if (textVal.isEmpty) {
      return TextSpan(style: effectiveBase, text: textVal);
    }

    int lastMatchEnd = 0;
    final matches = _markdownRegex.allMatches(textVal);

    final syntaxMarkerStyle = TextStyle(
      color: isDark ? Colors.white.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.25),
      fontWeight: FontWeight.w400,
      fontSize: (effectiveBase.fontSize ?? 14) * 0.88,
    );

    for (final match in matches) {
      // 1. Text before match
      if (match.start > lastMatchEnd) {
        children.add(
          TextSpan(
            text: textVal.substring(lastMatchEnd, match.start),
            style: effectiveBase,
          ),
        );
      }

      final fullMatch = match.group(0)!;

      // 2. Bold: **text**
      if (fullMatch.startsWith('**') && fullMatch.endsWith('**') && fullMatch.length >= 4) {
        final inner = fullMatch.substring(2, fullMatch.length - 2);
        children.add(TextSpan(text: '**', style: syntaxMarkerStyle));
        children.add(
          TextSpan(
            text: inner,
            style: effectiveBase.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.1,
            ),
          ),
        );
        children.add(TextSpan(text: '**', style: syntaxMarkerStyle));
      }
      // 3. Italic: *text*
      else if (fullMatch.startsWith('*') && fullMatch.endsWith('*') && fullMatch.length >= 2) {
        final inner = fullMatch.substring(1, fullMatch.length - 1);
        children.add(TextSpan(text: '*', style: syntaxMarkerStyle));
        children.add(
          TextSpan(
            text: inner,
            style: effectiveBase.copyWith(fontStyle: FontStyle.italic),
          ),
        );
        children.add(TextSpan(text: '*', style: syntaxMarkerStyle));
      }
      // 4. Inline Code: `text`
      else if (fullMatch.startsWith('`') && fullMatch.endsWith('`') && fullMatch.length >= 2) {
        final inner = fullMatch.substring(1, fullMatch.length - 1);
        children.add(TextSpan(text: '`', style: syntaxMarkerStyle));
        children.add(
          TextSpan(
            text: inner,
            style: effectiveBase.copyWith(
              fontFamily: 'Consolas',
              fontSize: (effectiveBase.fontSize ?? 14) * 0.92,
              color: const Color(0xFF00E5FF),
              backgroundColor: isDark
                  ? const Color(0x3300E5FF)
                  : const Color(0x1F0284C7),
            ),
          ),
        );
        children.add(TextSpan(text: '`', style: syntaxMarkerStyle));
      }
      // 5. Strikethrough: ~~text~~
      else if (fullMatch.startsWith('~~') && fullMatch.endsWith('~~') && fullMatch.length >= 4) {
        final inner = fullMatch.substring(2, fullMatch.length - 2);
        children.add(TextSpan(text: '~~', style: syntaxMarkerStyle));
        children.add(
          TextSpan(
            text: inner,
            style: effectiveBase.copyWith(
              decoration: TextDecoration.lineThrough,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        );
        children.add(TextSpan(text: '~~', style: syntaxMarkerStyle));
      }
      // 6. Link: [text](url)
      else if (fullMatch.startsWith('[') && fullMatch.contains('](') && fullMatch.endsWith(')')) {
        final labelEnd = fullMatch.indexOf('](');
        final label = fullMatch.substring(1, labelEnd);
        final url = fullMatch.substring(labelEnd + 2, fullMatch.length - 1);
        children.add(TextSpan(text: '[', style: syntaxMarkerStyle));
        children.add(
          TextSpan(
            text: label,
            style: effectiveBase.copyWith(
              color: const Color(0xFF00E5FF),
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        children.add(TextSpan(text: ']($url)', style: syntaxMarkerStyle));
      } else {
        children.add(TextSpan(text: fullMatch, style: effectiveBase));
      }

      lastMatchEnd = match.end;
    }

    // 7. Trailing text after last match
    if (lastMatchEnd < textVal.length) {
      children.add(
        TextSpan(
          text: textVal.substring(lastMatchEnd),
          style: effectiveBase,
        ),
      );
    }

    return TextSpan(style: effectiveBase, children: children);
  }

  // --- Notion Formatting Toggles (Bold <-> Normal vice versa) ---

  void toggleBold() {
    if (!selection.isValid || selection.isCollapsed) return;
    final fullText = text;
    final selectedText = selection.textInside(fullText);
    if (selectedText.isEmpty) return;

    // 1. If selection itself is wrapped in **
    if (selectedText.startsWith('**') && selectedText.endsWith('**') && selectedText.length >= 4) {
      final unwrapped = selectedText.substring(2, selectedText.length - 2);
      final newText = selection.textBefore(fullText) + unwrapped + selection.textAfter(fullText);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + unwrapped.length,
        ),
      );
      return;
    }

    // 2. If outer surrounding characters are **
    final before = selection.textBefore(fullText);
    final after = selection.textAfter(fullText);
    if (before.endsWith('**') && after.startsWith('**')) {
      final newText = before.substring(0, before.length - 2) + selectedText + after.substring(2);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start - 2,
          extentOffset: selection.start - 2 + selectedText.length,
        ),
      );
      return;
    }

    // 3. Otherwise wrap in ** (Bold)
    final wrapped = '**$selectedText**';
    final newText = before + wrapped + after;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + wrapped.length,
      ),
    );
  }

  void toggleItalic() {
    if (!selection.isValid || selection.isCollapsed) return;
    final fullText = text;
    final selectedText = selection.textInside(fullText);
    if (selectedText.isEmpty) return;

    if (selectedText.startsWith('*') && selectedText.endsWith('*') && selectedText.length >= 2 && !selectedText.startsWith('**')) {
      final unwrapped = selectedText.substring(1, selectedText.length - 1);
      final newText = selection.textBefore(fullText) + unwrapped + selection.textAfter(fullText);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + unwrapped.length,
        ),
      );
      return;
    }

    final before = selection.textBefore(fullText);
    final after = selection.textAfter(fullText);
    if (before.endsWith('*') && after.startsWith('*') && !before.endsWith('**')) {
      final newText = before.substring(0, before.length - 1) + selectedText + after.substring(1);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start - 1,
          extentOffset: selection.start - 1 + selectedText.length,
        ),
      );
      return;
    }

    final wrapped = '*$selectedText*';
    final newText = before + wrapped + after;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + wrapped.length,
      ),
    );
  }

  void toggleCode() {
    if (!selection.isValid || selection.isCollapsed) return;
    final fullText = text;
    final selectedText = selection.textInside(fullText);
    if (selectedText.isEmpty) return;

    if (selectedText.startsWith('`') && selectedText.endsWith('`') && selectedText.length >= 2) {
      final unwrapped = selectedText.substring(1, selectedText.length - 1);
      final newText = selection.textBefore(fullText) + unwrapped + selection.textAfter(fullText);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + unwrapped.length,
        ),
      );
      return;
    }

    final before = selection.textBefore(fullText);
    final after = selection.textAfter(fullText);
    if (before.endsWith('`') && after.startsWith('`')) {
      final newText = before.substring(0, before.length - 1) + selectedText + after.substring(1);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start - 1,
          extentOffset: selection.start - 1 + selectedText.length,
        ),
      );
      return;
    }

    final wrapped = '`$selectedText`';
    final newText = before + wrapped + after;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + wrapped.length,
      ),
    );
  }

  void toggleStrikethrough() {
    if (!selection.isValid || selection.isCollapsed) return;
    final fullText = text;
    final selectedText = selection.textInside(fullText);
    if (selectedText.isEmpty) return;

    if (selectedText.startsWith('~~') && selectedText.endsWith('~~') && selectedText.length >= 4) {
      final unwrapped = selectedText.substring(2, selectedText.length - 2);
      final newText = selection.textBefore(fullText) + unwrapped + selection.textAfter(fullText);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + unwrapped.length,
        ),
      );
      return;
    }

    final before = selection.textBefore(fullText);
    final after = selection.textAfter(fullText);
    final wrapped = '~~$selectedText~~';
    final newText = before + wrapped + after;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + wrapped.length,
      ),
    );
  }

  void insertLink(String url) {
    if (!selection.isValid || selection.isCollapsed) return;
    final fullText = text;
    final selectedText = selection.textInside(fullText);
    final before = selection.textBefore(fullText);
    final after = selection.textAfter(fullText);

    final cleanUrl = url.trim().isNotEmpty ? url.trim() : 'https://';
    final linkMarkdown = '[$selectedText]($cleanUrl)';
    final newText = before + linkMarkdown + after;

    value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + linkMarkdown.length,
      ),
    );
  }

  void deleteSelection() {
    if (!selection.isValid || selection.isCollapsed) return;
    final fullText = text;
    final before = selection.textBefore(fullText);
    final after = selection.textAfter(fullText);
    value = TextEditingValue(
      text: before + after,
      selection: TextSelection.collapsed(offset: before.length),
    );
  }

  /// 1-Click Cleaner: Strips surrounding ** or redundant asterisks from this block content
  void cleanAsterisks() {
    var str = text.trim();
    while ((str.startsWith('**') && str.endsWith('**') && str.length >= 4) ||
           (str.startsWith('__') && str.endsWith('__') && str.length >= 4)) {
      str = str.substring(2, str.length - 2).trim();
    }
    value = TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
