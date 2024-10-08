import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Метод для создания чата между работодателем и пользователем
  Future<String> createOrGetChat(
      String employerId, String workerId, String jobId) async {
    // Уникальный chatId на основе двух userId (работодатель и работник)
    String chatId = employerId + '_' + workerId;

    // Проверяем, существует ли уже чат
    DocumentReference chatDoc = _firestore.collection('chats').doc(chatId);
    DocumentSnapshot snapshot = await chatDoc.get();

    if (!snapshot.exists) {
      // Если чата нет, создаем новый
      await chatDoc.set({
        'participants': [employerId, workerId],
        'createdAt': FieldValue.serverTimestamp(),
        'jobId': jobId,
        'reviewSubmitted': false,
      });
    }

    return chatId; // Возвращаем chatId для навигации в экран чата
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String receiverId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Обновляем данные о чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageRead': false, // Сообщение не прочитано получателем
      });
    } catch (e) {
      print('Error sending message: $e');
    }

    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageRead':
          false, // Изначально считается, что сообщение не прочитано
    });
  }

  // Метод для открытия чата между друзьями (без jobId)
  Future<String> openChat(String userId1, String userId2) async {
    // Уникальный chatId на основе двух userId
    String chatId = userId1 + '_' + userId2;

    // Проверяем, существует ли уже чат
    DocumentReference chatDoc = _firestore.collection('chats').doc(chatId);
    DocumentSnapshot snapshot = await chatDoc.get();

    if (!snapshot.exists) {
      // Если чата нет, создаем новый
      await chatDoc.set({
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'jobId': '', // Для друзей jobId пустой
      });
    }

    return chatId; // Возвращаем chatId для навигации в экран чата
  }

  // Обновление статуса сообщений как прочитанных
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('receiverId',
              isEqualTo:
                  userId) // Проверяем, что сообщение получено текущим пользователем
          .get();

      for (var doc in messages.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Обновляем статус прочитанного сообщения в самом чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageRead': true, // Все сообщения помечены как прочитанные
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Обновление информации о чате
  Future<void> updateChat({
    required String chatId,
    required String lastMessage,
    required bool lastMessageRead,
    required DateTime updatedAt,
  }) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': lastMessage,
      'lastMessageRead': lastMessageRead,
      'updatedAt': updatedAt,
    });
  }

  // Получение участников чата
  Future<List<String>> getChatParticipants(String chatId) async {
    final chatDoc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    return List<String>.from(chatDoc['participants']);
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
