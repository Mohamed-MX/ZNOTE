import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  List<NoteBlock> _blocks = [];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _blocks = List.from(widget.note!.blocks.map((b) => NoteBlock(
            type: b.type,
            content: b.content,
            isDone: b.isDone,
          )));
    }
    if (_blocks.isEmpty) {
      _blocks.add(NoteBlock(type: 'text'));
    }
  }

  void _saveNote() {
    final user = _authService.currentUser;
    if (user == null) return;

    // Remove empty blocks to keep it clean
    _blocks.removeWhere((b) => b.content.trim().isEmpty && b.type == 'text');
    if (_titleController.text.trim().isEmpty && _blocks.isEmpty) {
      Navigator.pop(context);
      return; // Do not save empty note
    }

    final note = NoteModel(
      id: widget.note?.id ?? '',
      title: _titleController.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      userId: user.uid,
      blocks: _blocks,
      isPinned: widget.note?.isPinned ?? false,
      isRedacted: widget.note?.isRedacted ?? false,
    );

    if (widget.note == null) {
      _firestoreService.addNote(note);
    } else {
      _firestoreService.updateNote(note);
    }

    Navigator.pop(context);
  }

  void _addBlock(String type) {
    setState(() {
      _blocks.add(NoteBlock(type: type));
    });
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                DateFormat('MMM dd, yyyy - HH:mm').format(
                  widget.note?.createdAt ?? DateTime.now(),
                ),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.transparent,
                ),
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  onReorder: _onReorder,
                  buildDefaultDragHandles: false, // We use custom drag handle
                  itemCount: _blocks.length,
                  itemBuilder: (context, index) {
                    return _buildBlockEditor(index);
                  },
                ),
              ),
            ),
            // Moved to the bottom of the body so it rises with the keyboard easily
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.withAlpha(51))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => _addBlock('text'),
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Add Text'),
                  ),
                  TextButton.icon(
                    onPressed: () => _addBlock('checklist'),
                    icon: const Icon(Icons.check_box_outlined),
                    label: const Text('Add Checklist'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockEditor(int index) {
    final block = _blocks[index];
    
    return Row(
      key: Key(block.uid),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.type == 'checklist')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Checkbox(
              value: block.isDone,
              onChanged: (bool? value) {
                setState(() {
                  block.isDone = value ?? false;
                });
              },
            ),
          ),
        Expanded(
          child: TextFormField(
            initialValue: block.content,
            maxLines: block.type == 'text' ? null : 1,
            keyboardType: block.type == 'text' ? TextInputType.multiline : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: block.type == 'text' ? 'Write something...' : 'List item',
            ),
            style: TextStyle(
              fontSize: 16,
              decoration: (block.type == 'checklist' && block.isDone) ? TextDecoration.lineThrough : null,
              color: (block.type == 'checklist' && block.isDone) ? Colors.grey : null,
            ),
            onChanged: (value) {
              block.content = value;
            },
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'delete') _removeBlock(index);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0),
            child: Icon(Icons.menu, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
