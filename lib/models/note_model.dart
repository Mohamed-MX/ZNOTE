import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteModel {
  String id;
  String title;
  DateTime createdAt;
  String userId;
  bool isPinned;
  bool isRedacted;
  List<NoteBlock> blocks;

  NoteModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.userId,
    this.isPinned = false,
    this.isRedacted = false,
    this.blocks = const [],
  });

  factory NoteModel.fromMap(Map<String, dynamic> data, String documentId) {
    List<NoteBlock> parsedBlocks = [];
    var blocksData = data['blocks'] as List<dynamic>?;
    
    if (blocksData != null) {
      parsedBlocks = blocksData
          .map((item) => NoteBlock.fromMap(item as Map<String, dynamic>))
          .toList();
    } else {
      // Backwards compatibility for older notes
      if (data['content'] != null && data['content'].toString().isNotEmpty) {
        parsedBlocks.add(NoteBlock(type: 'text', content: data['content']));
      }
      var checkListData = data['checklist'] as List<dynamic>? ?? [];
      for (var item in checkListData) {
        parsedBlocks.add(NoteBlock(
            type: 'checklist',
            content: item['text'] ?? '',
            isDone: item['isDone'] ?? false));
      }
      if (parsedBlocks.isEmpty) {
        parsedBlocks.add(NoteBlock(type: 'text', content: ''));
      }
    }

    return NoteModel(
      id: documentId,
      title: data['title'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
      isPinned: data['isPinned'] ?? false,
      isRedacted: data['isRedacted'] ?? false,
      blocks: parsedBlocks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'isPinned': isPinned,
      'isRedacted': isRedacted,
      'blocks': blocks.map((item) => item.toMap()).toList(),
    };
  }

  // Helper to get raw text representation
  String get plainText {
    return blocks.map((b) => b.content).join('\n');
  }
}

class NoteBlock {
  String type; // 'text' or 'checklist'
  String content;
  bool isDone;
  final String _uid = UniqueKey().toString();
  String get uid => _uid;

  NoteBlock({required this.type, this.content = '', this.isDone = false});

  factory NoteBlock.fromMap(Map<String, dynamic> data) {
    return NoteBlock(
      type: data['type'] ?? 'text',
      content: data['content'] ?? '',
      isDone: data['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
      'isDone': isDone,
    };
  }
}
