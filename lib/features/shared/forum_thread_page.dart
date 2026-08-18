import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class ForumThreadPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic>? postData;

  const ForumThreadPage({super.key, required this.postId, this.postData});

  @override
  State<ForumThreadPage> createState() => _ForumThreadPageState();
}

class _ForumThreadPageState extends State<ForumThreadPage> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    final user = context.read<AuthProvider>().userModel!;
    setState(() => _sending = true);
    try {
      final db = FirestoreService();
      await db.addForumReply(widget.postId, {
        'authorId': user.uid,
        'authorName': user.name,
        'authorRole': user.role,
        'content': _replyCtrl.text.trim(),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      _replyCtrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    final post = widget.postData ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(post['subjectName'] as String? ?? 'Forum'),
      ),
      body: Column(
        children: [
          // Original post
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(
                        post['subjectName'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: AppTheme.secondaryColor,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  post['title'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(post['content'] as String? ?? ''),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.accentColor,
                      child: Text(
                        (post['authorName'] as String? ?? '?')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post['authorName'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Replies
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.getForumReplies(widget.postId),
              builder: (context, snap) {
                final replies = snap.data ?? [];
                if (replies.isEmpty) {
                  return const Center(
                    child: Text('Belum ada balasan. Jadilah yang pertama!',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: replies.length,
                  itemBuilder: (context, i) {
                    final r = replies[i];
                    final isTeacher =
                        (r['authorRole'] as String? ?? '').contains('GURU');
                    final isMe = r['authorId'] == user.uid;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isTeacher
                                  ? AppTheme.successColor
                                  : AppTheme.accentColor,
                              child: Text(
                                (r['authorName'] as String? ?? '?')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppTheme.primaryColor.withValues(
                                        alpha: 0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isTeacher
                                      ? AppTheme.successColor
                                          .withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        r['authorName'] as String? ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isTeacher
                                              ? AppTheme.successColor
                                              : null,
                                        ),
                                      ),
                                      if (isTeacher) ...[
                                        const SizedBox(width: 4),
                                        const Chip(
                                          label: Text('Guru',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white)),
                                          backgroundColor:
                                              AppTheme.successColor,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(r['content'] as String? ?? ''),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 8),
                          if (isMe)
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Reply input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tulis balasan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendReply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendReply,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
