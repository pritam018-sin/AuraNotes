import 'package:flutter/material.dart';

/// Professional syntax highlighting controller for AuraNotes code editor.
/// Implements a high-contrast One Dark / Tokyo Night developer theme.
class CodeSyntaxTextController extends TextEditingController {
  String language;

  CodeSyntaxTextController({
    super.text,
    this.language = 'java',
  });

  void updateLanguage(String newLang) {
    if (language != newLang) {
      language = newLang;
      notifyListeners();
    }
  }

  // Token Regex
  static final RegExp _tokenizerRegex = RegExp(
    r'("(?:\\.|[^"\\])*"|' r"'(?:\\.|[^'\\])*'|`" r"(?:\\.|[^`\\])*`)" // 1: String
    r'|(//[^\n]*|/\*[\s\S]*?\*/|#[^\n]*)'                                // 2: Comment
    r'|(@[a-zA-Z_]\w*)'                                                  // 3: Annotation
    r'|\b(0x[0-9a-fA-F]+|\d+(?:\.\d+)?(?:[fFLl])?)\b'                    // 4: Number
    r'|\b([a-zA-Z_]\w*)(?=\s*\()'                                        // 5: Function / Method call
    r'|\b([a-zA-Z_]\w*)\b'                                               // 6: Identifier / Word
    r'|([{}()\[\],;])'                                                    // 7: Bracket / Delimiter
    r'|([+\-*/%!=<>|&^~?:])'                                             // 8: Operator
  );

  static final Set<String> _keywords = {
    // Java & C++ & C#
    'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 'class', 'const',
    'continue', 'default', 'do', 'double', 'else', 'enum', 'extends', 'final', 'finally',
    'float', 'for', 'goto', 'if', 'implements', 'import', 'instanceof', 'int', 'interface',
    'long', 'native', 'new', 'package', 'private', 'protected', 'public', 'return', 'short',
    'static', 'strictfp', 'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
    'transient', 'try', 'void', 'volatile', 'while', 'var', 'record', 'sealed', 'permits',
    'yield', 'override', 'virtual', 'explicit', 'friend', 'inline', 'mutable', 'operator',
    // Python & JavaScript & TypeScript & Dart
    'def', 'lambda', 'async', 'await', 'function', 'let', 'typeof', 'export', 'from',
    'pass', 'elif', 'with', 'as', 'raise', 'except', 'global', 'nonlocal', 'is', 'in',
    'debugger', 'delete',
    // Rust & Go
    'fn', 'mut', 'impl', 'trait', 'pub', 'struct', 'type', 'chan', 'defer', 'go', 'select',
    // SQL
    'SELECT', 'FROM', 'WHERE', 'INSERT', 'UPDATE', 'DELETE', 'JOIN', 'LEFT', 'RIGHT', 'INNER',
    'OUTER', 'GROUP', 'ORDER', 'BY', 'HAVING', 'LIMIT', 'CREATE', 'TABLE', 'ALTER', 'DROP',
    'INDEX', 'VIEW', 'UNION', 'ALL', 'DISTINCT', 'COUNT', 'SUM', 'AVG', 'MIN', 'MAX',
  };

  static final Set<String> _types = {
    // Java Types & Collections
    'String', 'Integer', 'Long', 'Double', 'Float', 'Boolean', 'Character', 'Byte', 'Short',
    'Object', 'List', 'ArrayList', 'LinkedList', 'Map', 'HashMap', 'TreeMap', 'LinkedHashMap',
    'Set', 'HashSet', 'TreeSet', 'LinkedHashSet', 'Queue', 'Deque', 'ArrayDeque', 'PriorityQueue',
    'Stack', 'Vector', 'Arrays', 'Collections', 'Math', 'System', 'Scanner', 'StringBuilder',
    'StringBuffer', 'Comparable', 'Comparator', 'Iterator', 'Iterable', 'Optional',
    // DSA Data Structures
    'TreeNode', 'ListNode', 'Node', 'Graph', 'Trie', 'TrieNode', 'Pair', 'Tuple', 'Point',
    // C++
    'vector', 'pair', 'unordered_map', 'unordered_set', 'multimap', 'multiset', 'string',
    'size_t', 'bool', 'void', 'int8_t', 'int16_t', 'int32_t', 'int64_t', 'uint32_t', 'uint64_t',
    // Python & JS
    'str', 'dict', 'set', 'tuple', 'list', 'int', 'float', 'bytes', 'any', 'number',
    'Promise', 'Observable', 'Future', 'Stream', 'Array', 'Record'
  };

  static final Set<String> _constants = {
    'true', 'false', 'null', 'nil', 'None', 'undefined', 'NaN', 'Infinity', 'TRUE', 'FALSE', 'NULL'
  };

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = value.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in _tokenizerRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        // Plain whitespace or indentation
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: style,
        ));
      }

      final matchedText = match.group(0)!;

      if (match.group(1) != null) {
        // 1. Strings -> One Dark Emerald #98C379
        spans.add(TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: const Color(0xFF98C379),
            fontWeight: FontWeight.w400,
          ),
        ));
      } else if (match.group(2) != null) {
        // 2. Comments -> Slate Gray #5C6370 with italic
        spans.add(TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: const Color(0xFF6A737D),
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(3) != null) {
        // 3. Annotation (@Override) -> Gold #E5C07B
        spans.add(TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: const Color(0xFFE5C07B),
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(4) != null) {
        // 4. Numbers -> Warm Amber #D19A66
        spans.add(TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: const Color(0xFFD19A66),
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (match.group(5) != null) {
        // 5. Method calls -> Electric Blue #61AFEF
        spans.add(TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: const Color(0xFF61AFEF),
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (match.group(6) != null) {
        // 6. Keywords, Types, Constants or Identifiers
        if (_keywords.contains(matchedText)) {
          // Vivid Orchid Purple #C678DD
          spans.add(TextSpan(
            text: matchedText,
            style: style?.copyWith(
              color: const Color(0xFFC678DD),
              fontWeight: FontWeight.w600,
            ),
          ));
        } else if (_types.contains(matchedText) || RegExp(r'^[A-Z][a-zA-Z0-9_]*$').hasMatch(matchedText)) {
          // Types & PascalCase Classes -> Vivid Cyan #56B6C2
          spans.add(TextSpan(
            text: matchedText,
            style: style?.copyWith(
              color: const Color(0xFF56B6C2),
              fontWeight: FontWeight.w600,
            ),
          ));
        } else if (_constants.contains(matchedText)) {
          // Constants & Booleans -> Coral #E06C75
          spans.add(TextSpan(
            text: matchedText,
            style: style?.copyWith(
              color: const Color(0xFFE06C75),
              fontWeight: FontWeight.w600,
            ),
          ));
        } else {
          // Standard Identifier -> Crisp Light Gray #E2E8F0
          spans.add(TextSpan(
            text: matchedText,
            style: style?.copyWith(
              color: const Color(0xFFE2E8F0),
            ),
          ));
        }
      } else if (match.group(7) != null) {
        // Delimiters {} () [] -> Slate #94A3B8
        spans.add(TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: const Color(0xFF94A3B8),
          ),
        ));
      } else if (match.group(8) != null) {
        // Operators -> Teal #56B6C2
        spans.add(TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: const Color(0xFF56B6C2),
          ),
        ));
      } else {
        spans.add(TextSpan(text: matchedText, style: style));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: style,
      ));
    }

    return TextSpan(children: spans, style: style);
  }
}
