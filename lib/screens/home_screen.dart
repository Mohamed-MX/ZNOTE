import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/redacted_note_unlock.dart';
import '../providers/theme_provider.dart';
import '../widgets/note_app_lock_ui.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZNOTE'),
        actions: [
          IconButton(
            tooltip: 'App lock & pattern',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => showAppPatternLockSettingsSheet(context),
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: firestoreService.streamNotes(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorString = snapshot.error.toString();
            if (errorString.contains('permission-denied')) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Permission Denied.\nPlease go to your Firebase Console -> Firestore Database -> Rules and update them to allow read/write access. For testing, you can use:\nallow read, write: if request.auth != null;',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              );
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notes = snapshot.data ?? [];
          
          // Sort so pinned notes appear first
          notes.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'No notes yet. Create one!',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _buildNoteCard(context, note, firestoreService);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openNote(BuildContext context, NoteModel note) async {
    if (note.isRedacted) {
      final unlocked = await ensureRedactedNoteUnlocked(context);
      if (!unlocked) return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteEditorScreen(note: note),
        ),
      );
    }
  }

  Widget _buildNoteCard(BuildContext context, NoteModel note, FirestoreService firestoreService) {
    return GestureDetector(
      onTap: () => _openNote(context, note),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isNotEmpty ? note.title : 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    const Icon(Icons.push_pin, size: 16, color: Colors.blueAccent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM dd, yyyy - HH:mm').format(note.createdAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: note.isRedacted
                    ? const Center(
                        child: Icon(Icons.lock, size: 40, color: Colors.grey),
                      )
                    : _buildBlocksPreview(note.blocks),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'delete') {
                      firestoreService.deleteNote(note.userId, note.id);
                    } else if (value == 'pin') {
                      note.isPinned = !note.isPinned;
                      firestoreService.updateNote(note);
                    } else if (value == 'redact') {
                      note.isRedacted = !note.isRedacted;
                      firestoreService.updateNote(note);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(note.isPinned ? 'Unpin' : 'Pin'),
                    ),
                    PopupMenuItem(
                      value: 'redact',
                      child: Text(note.isRedacted ? 'Unredact' : 'Redact (Lock)'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlocksPreview(List<NoteBlock> blocks) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: blocks.length > 4 ? 4 : blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        if (block.type == 'checklist') {
          return Row(
            children: [
              Icon(
                block.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: block.isDone ? TextDecoration.lineThrough : null,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              block.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }
      },
    );
  }
}
