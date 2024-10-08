import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'package:logger/logger.dart';
import 'package:flutter/widgets.dart';

final logger = Logger();

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with RouteAware {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  Stream<List<Map<String, dynamic>>> _getUserChats() {
    String currentUserId = _auth.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> chats = [];

      for (var doc in snapshot.docs) {
        String chatId = doc.id;
        List participants = doc['participants'];
        String jobId = doc['jobId'] ?? ''; // Извлекаем jobId

        // Получаем последнее сообщение из коллекции сообщений
        QuerySnapshot messageSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (messageSnapshot.docs.isNotEmpty) {
          var lastMessageData =
              messageSnapshot.docs.first.data() as Map<String, dynamic>;

          bool isMessageRead = lastMessageData['isRead'] ?? true;
          String receiverId = lastMessageData['receiverId'];

          // Проверяем, если текущий пользователь является получателем и сообщение не прочитано
          bool isUnread = receiverId == currentUserId && !isMessageRead;

          chats.add({
            'chatId': chatId,
            'participants': participants,
            'lastMessage': lastMessageData['text'] ?? 'Нет сообщений',
            'isUnread': isUnread,
            'jobId': jobId,
          });
        } else {
          chats.add({
            'chatId': chatId,
            'participants': participants,
            'lastMessage': 'Нет сообщений',
            'isUnread': false,
            'jobId': jobId,
          });
        }
      }

      return chats;
    });
  }

  Future<void> _deleteChat(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
  }

  // Этот метод будет вызван, когда экран снова станет видимым
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Обновляем чаты при возврате на экран
  @override
  void didPopNext() {
    setState(() {
      // Обновляем список чатов при возврате с экрана чата
    });
    logger.d('Обновление списка чатов после возврата');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Мои чаты'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Чатов нет'));
          }

          List<Map<String, dynamic>> chats = snapshot.data!;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatId = chat['chatId'];
              final participants = chat['participants'] as List;
              final lastMessage = chat['lastMessage'];
              final isUnread = chat['isUnread'];
              final jobId = chat['jobId'] ?? '';

              if (participants.isEmpty) {
                return ListTile(
                  title: Text('Неверные данные чата'),
                );
              }

              String otherUserId = participants.firstWhere(
                (participant) => participant != _auth.currentUser!.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) {
                return ListTile(
                  title: Text('Пользователь не найден'),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Загрузка...'),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      title: Text('Пользователь не найден'),
                    );
                  }

                  String userName =
                      userSnapshot.data!['displayName'] ?? 'Без имени';

                  return Dismissible(
                    key: Key(chatId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) async {
                      await _deleteChat(chatId);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          userName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage,
                        style: TextStyle(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isUnread
                          ? CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.blue,
                            )
                          : SizedBox.shrink(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(chatId: chatId, jobId: jobId),
                          ),
                        );
                        logger.d(
                            'Переход в чат с chatId: $chatId и jobId: $jobId');
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
