import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/chat_service.dart';
import '/screens/review/write_review_screen.dart'; // Экран для написания отзыва
import 'package:logger/logger.dart';

final logger = Logger();

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String jobId;

  ChatScreen({required this.chatId, required this.jobId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _showReviewBanner = false; // Показывает плашку для отзыва
  String _userRole = ''; // Роль пользователя: заказчик или исполнитель

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _checkUserRole(); // Определяем роль пользователя (заказчик или исполнитель)
  }

  // Определение роли пользователя
  Future<void> _checkUserRole() async {
    final currentUserId = _auth.currentUser!.uid;

    // Проверяем наличие jobId перед выполнением запроса
    if (widget.jobId.isEmpty) {
      logger.d("Ошибка: jobId отсутствует.");
      setState(() {
        _userRole = 'none';
      });
      return;
    }

    final jobSnapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .get();

    if (jobSnapshot.exists && jobSnapshot.data() != null) {
      final jobData = jobSnapshot.data() as Map<String, dynamic>;
      if (jobData['employerId'] == currentUserId) {
        setState(() {
          _userRole = 'customer'; // Пользователь является заказчиком
        });
        logger.d("Пользователь является заказчиком.");
        _checkIfCustomerReviewSubmitted(); // Проверяем отзыв заказчика
      } else {
        setState(() {
          _userRole = 'worker'; // Пользователь является исполнителем
        });
        logger.d("Пользователь является исполнителем.");
        _checkIfWorkerReviewSubmitted(); // Проверяем отзыв исполнителя
      }
    } else {
      logger.d("Ошибка: не удалось получить данные о работе.");
    }
  }

  // Проверка, оставил ли заказчик отзыв
  Future<void> _checkIfCustomerReviewSubmitted() async {
    if (widget.jobId.isNotEmpty) {
      DocumentSnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (chatSnapshot.exists && chatSnapshot.data() != null) {
        final chatData = chatSnapshot.data() as Map<String, dynamic>;

        if (chatData['reviewSubmittedByCustomer'] == true) {
          setState(() {
            _showReviewBanner = false; // Отзыв уже оставлен, скрываем плашку
          });
          logger.d("Отзыв заказчика уже отправлен.");
        } else {
          setState(() {
            _showReviewBanner = true; // Отзыв не оставлен, показываем плашку
          });
          logger.d("Отзыв заказчика не был отправлен.");
        }
      }
    }
  }

  // Проверка, оставил ли исполнитель отзыв
  Future<void> _checkIfWorkerReviewSubmitted() async {
    if (widget.jobId.isNotEmpty) {
      DocumentSnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (chatSnapshot.exists && chatSnapshot.data() != null) {
        final chatData = chatSnapshot.data() as Map<String, dynamic>;

        if (chatData['reviewSubmittedByWorker'] == true) {
          setState(() {
            _showReviewBanner = false; // Отзыв уже оставлен, скрываем плашку
          });
          logger.d("Отзыв исполнителя уже отправлен.");
        } else {
          setState(() {
            _showReviewBanner = true; // Отзыв не оставлен, показываем плашку
          });
          logger.d("Отзыв исполнителя не был отправлен.");
        }
      }
    }
  }

  // Пометка сообщений как прочитанных
  void _markMessagesAsRead() async {
    final currentUserId = _auth.currentUser!.uid;
    await _chatService.markMessagesAsRead(
      chatId: widget.chatId,
      userId: currentUserId,
    );
  }

  // Отправка сообщения
  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final currentUserId = _auth.currentUser!.uid;
      final participants =
          await _chatService.getChatParticipants(widget.chatId);
      final receiverId = participants.firstWhere((id) => id != currentUserId);

      String messageText = _controller.text;
      _controller.clear();

      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: currentUserId,
        receiverId: receiverId,
        text: messageText,
      );

      _chatService.updateChat(
        chatId: widget.chatId,
        lastMessage: messageText,
        lastMessageRead: false,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Скрыть плашку с отзывом и обновить данные в Firestore
  void _hideReviewBannerAndMarkSubmitted(String role) async {
    setState(() {
      _showReviewBanner = false;
    });

    if (role == 'customer') {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'reviewSubmittedByCustomer': true,
      });
      logger.d("Отзыв заказчика отмечен как отправленный.");
    } else if (role == 'worker') {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'reviewSubmittedByWorker': true,
      });
      logger.d("Отзыв исполнителя отмечен как отправленный.");
    }
  }

  // Открыть экран для написания отзыва
  void _openReviewScreen() async {
    final currentUserId = _auth.currentUser!.uid;
    final participants = await _chatService.getChatParticipants(widget.chatId);
    final revieweeId = participants.firstWhere((id) => id != currentUserId);
    final jobId = widget.jobId;

    String role = _userRole; // Роль уже известна из _checkUserRole

    showDialog(
      context: context,
      builder: (context) => WriteReviewScreen(
        revieweeId: revieweeId,
        jobId: jobId,
      ),
    ).then((_) {
      // После закрытия диалога отзыв считается отправленным
      _hideReviewBannerAndMarkSubmitted(role);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Чат')),
      body: Column(
        children: [
          // Плашка для оставления отзыва
          if (_showReviewBanner)
            GestureDetector(
              onTap: _openReviewScreen,
              child: Container(
                color: Colors.yellow[200],
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Договорились о работе? Оставьте отзыв!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () async {
                        // Скрытие плашки и обновление в Firestore
                        _hideReviewBannerAndMarkSubmitted(_userRole);
                      },
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == _auth.currentUser!.uid;
                    final bool isRead = message['isRead'] ?? false;

                    return ListTile(
                      title: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blue[200]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(message['text']),
                              ),
                            ),
                            SizedBox(width: 5),
                            if (isMe)
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: isRead ? Colors.blue : Colors.grey,
                                  ),
                                  Positioned(
                                    left: 4,
                                    child: Icon(
                                      Icons.check,
                                      size: 18,
                                      color: isRead ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
