enum BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  todo,
  bullet,
  numbered,
  code,
  quote,
  callout,
  divider,
  table,
  subpage,
  dryRunTrace,
  image,
  bookmark,
}

class BlockItem {
  String id;
  BlockType type;
  String content;
  bool isCompleted;
  String language;
  String calloutEmoji;
  String? subpageId;
  String? caption;
  List<List<String>> tableData;

  BlockItem({
    required this.id,
    required this.type,
    required this.content,
    this.isCompleted = false,
    this.language = 'dart',
    this.calloutEmoji = '💡',
    this.subpageId,
    this.caption,
    List<List<String>>? tableData,
  }) : tableData = tableData ?? [
          ['Feature', 'Status', 'Owner'],
          ['Aura Editor', 'Ready', 'AuraStudio'],
          ['Nested Pages', 'Active', 'Pritam'],
        ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'isCompleted': isCompleted,
        'language': language,
        'calloutEmoji': calloutEmoji,
        'subpageId': subpageId,
        'caption': caption,
        'tableData': tableData,
      };

  factory BlockItem.fromJson(Map<String, dynamic> json) {
    return BlockItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: BlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BlockType.paragraph,
      ),
      content: json['content'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      language: json['language'] ?? 'dart',
      calloutEmoji: json['calloutEmoji'] ?? '💡',
      subpageId: json['subpageId'],
      caption: json['caption'],
      tableData: (json['tableData'] as List?)
              ?.map((row) => (row as List).map((cell) => cell.toString()).toList())
              .toList() ??
          [
            ['Feature', 'Status', 'Owner'],
            ['Aura Engine', 'Online', 'Pritam'],
          ],
    );
  }
}

class NoteDocument {
  String id;
  String? parentId; // Support for nested sub-pages!
  String title;
  String icon;
  String coverGradient;
  String workspaceId;
  List<BlockItem> blocks;
  bool isPinned;
  bool isFavorite;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;

  NoteDocument({
    required this.id,
    this.parentId,
    required this.title,
    this.icon = '📝',
    this.coverGradient = 'cyan',
    required this.workspaceId,
    required this.blocks,
    this.isPinned = false,
    this.isFavorite = false,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'title': title,
        'icon': icon,
        'coverGradient': coverGradient,
        'workspaceId': workspaceId,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'isPinned': isPinned,
        'isFavorite': isFavorite,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteDocument.fromJson(Map<String, dynamic> json) {
    return NoteDocument(
      id: json['id'] ?? '',
      parentId: json['parentId'],
      title: json['title'] ?? 'Untitled Note',
      icon: json['icon'] ?? '📝',
      coverGradient: json['coverGradient'] ?? 'cyan',
      workspaceId: json['workspaceId'] ?? 'default',
      blocks: (json['blocks'] as List?)
              ?.map((b) => BlockItem.fromJson(b))
              .toList() ??
          [],
      isPinned: json['isPinned'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class KanbanCard {
  String id;
  String title;
  String description;
  String priority; // High, Medium, Low
  String dueDate;
  List<String> tags;
  int checklistTotal;
  int checklistDone;

  KanbanCard({
    required this.id,
    required this.title,
    required this.description,
    this.priority = 'Medium',
    this.dueDate = 'Today',
    List<String>? tags,
    this.checklistTotal = 3,
    this.checklistDone = 1,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority,
        'dueDate': dueDate,
        'tags': tags,
        'checklistTotal': checklistTotal,
        'checklistDone': checklistDone,
      };

  factory KanbanCard.fromJson(Map<String, dynamic> json) {
    return KanbanCard(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'Medium',
      dueDate: json['dueDate'] ?? 'Today',
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      checklistTotal: json['checklistTotal'] ?? 0,
      checklistDone: json['checklistDone'] ?? 0,
    );
  }
}

class KanbanColumn {
  String id;
  String title;
  String colorHex;
  List<KanbanCard> cards;

  KanbanColumn({
    required this.id,
    required this.title,
    this.colorHex = '#00E5FF',
    required this.cards,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'colorHex': colorHex,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  factory KanbanColumn.fromJson(Map<String, dynamic> json) {
    return KanbanColumn(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Column',
      colorHex: json['colorHex'] ?? '#00E5FF',
      cards: (json['cards'] as List?)
              ?.map((c) => KanbanCard.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class GridRowItem {
  String id;
  String title;
  String status; // Done, In Progress, Backlog, Idea
  String priority; // High, Medium, Low
  String category;
  String date;
  String assignee;
  List<String> tags;

  GridRowItem({
    required this.id,
    required this.title,
    this.status = 'In Progress',
    this.priority = 'Medium',
    this.category = 'Engineering',
    this.date = 'Today',
    this.assignee = 'Pritam',
    List<String>? tags,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'priority': priority,
        'category': category,
        'date': date,
        'assignee': assignee,
        'tags': tags,
      };

  factory GridRowItem.fromJson(Map<String, dynamic> json) {
    return GridRowItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'In Progress',
      priority: json['priority'] ?? 'Medium',
      category: json['category'] ?? 'Engineering',
      date: json['date'] ?? 'Today',
      assignee: json['assignee'] ?? 'Pritam',
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}

class WorkspaceItem {
  String id;
  String name;
  String icon;
  String description;

  WorkspaceItem({
    required this.id,
    required this.name,
    this.icon = '⚡',
    this.description = 'Personal Workspace',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
      };

  factory WorkspaceItem.fromJson(Map<String, dynamic> json) {
    return WorkspaceItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Workspace',
      icon: json['icon'] ?? '⚡',
      description: json['description'] ?? '',
    );
  }
}
