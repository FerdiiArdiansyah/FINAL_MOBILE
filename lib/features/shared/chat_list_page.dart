import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/chat_model.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Percakapan'),
              Tab(text: 'Pengguna'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Existing conversations
            StreamBuilder<List<ChatRoomModel>>(
              stream: db.getChatRooms(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rooms = snap.data ?? [];
                if (rooms.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Belum ada percakapan',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 6),
                        Text('Buka tab "Pengguna" untuk memulai chat',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final room = rooms[i];
                    final otherId = room.participants.firstWhere(
                      (p) => p != user.uid,
                      orElse: () => '',
                    );
                    final otherName =
                        room.participantNames[otherId] ?? 'Unknown';
                    final isBkRoom = room.type == 'bk_confidential';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isBkRoom ? Colors.purple : AppTheme.primaryColor,
                        child: Text(
                          otherName.isNotEmpty
                              ? otherName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(otherName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (isBkRoom)
                            const Icon(Icons.lock_outline,
                                size: 14, color: Colors.purple),
                        ],
                      ),
                      subtitle: Text(
                        room.lastMessage ?? 'Belum ada pesan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => context.push('/chat/${room.id}'),
                    );
                  },
                );
              },
            ),

            // Tab 2: Find users to chat with
            FutureBuilder<List<UserModel>>(
              future: db.getAllUsers(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final others = snap.data!
                    .where((u) => u.uid != user.uid)
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
                if (others.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada pengguna lain',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: others.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final u = others[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _roleColor(u.role),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(u.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(AppRoles.displayName(u.role)),
                      trailing: const Icon(Icons.chat_bubble_outline,
                          size: 18, color: Colors.grey),
                      onTap: () async {
                        final chatType = u.role == AppRoles.guruBk
                            ? 'bk_confidential'
                            : 'private';
                        final room = await db.getOrCreateChatRoom(
                          user.uid,
                          u.uid,
                          {user.uid: user.name, u.uid: u.name},
                          type: chatType,
                        );
                        if (context.mounted) {
                          context.push('/chat/${room.id}');
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case AppRoles.guruMapel:
        return Colors.blue;
      case AppRoles.guruBk:
        return Colors.purple;
      case AppRoles.guruPiket:
        return Colors.green;
      case AppRoles.waliKelas:
        return Colors.orange;
      case AppRoles.admin:
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }
}
