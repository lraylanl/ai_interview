import 'package:flutter/material.dart';
import '../../model/user.dart';
import '../../model/chat_room.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final User? currentUser;
  final List<ChatRoom> ongoingRooms;
  final List<ChatRoom> completedRooms;
  final void Function(ChatRoom) onOpenChatRoom;
  final void Function(ChatRoom) onDeleteChatRoom;

  const ChatHistoryDrawer({
    Key? key,
    required this.currentUser,
    required this.ongoingRooms,
    required this.completedRooms,
    required this.onOpenChatRoom,
    required this.onDeleteChatRoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.blue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  '면접 기록',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentUser != null)
                  Text(
                    '${currentUser?.name}님',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )
                else
                  const Text(
                    '로그인 필요',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.indigo,
                    tabs: [
                      Tab(text: '진행 중'),
                      Tab(text: '완료'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildChatRoomList(context, ongoingRooms, false),
                        _buildChatRoomList(context, completedRooms, true),
                      ],
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

  Widget _buildChatRoomList(BuildContext context, List<ChatRoom> rooms, bool isCompleted) {
    if (currentUser == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }
    if (rooms.isEmpty) {
      return Center(
        child: Text(isCompleted ? '완료된 면접이 없습니다.' : '진행 중인 면접이 없습니다.'),
      );
    }

    return ListView.builder(
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final chatRoom = rooms[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.chat,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
            title: Text(
              chatRoom.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              chatRoom.prompt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  onDeleteChatRoom(chatRoom);
                }
              },
            ),
            onTap: () {
              Navigator.pop(context); // Drawer를 닫습니다.
              onOpenChatRoom(chatRoom);
            },
          ),
        );
      },
    );
  }
}