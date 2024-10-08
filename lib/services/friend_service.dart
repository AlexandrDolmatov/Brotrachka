import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Получение заявок в друзья
  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    String currentUserId = _auth.currentUser!.uid;
    final snapshot = await _firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id, // ID заявки для будущего обновления или удаления
              ...doc.data() as Map<String, dynamic>
            })
        .toList();
  }

  // Получение списка друзей
  Future<List<Map<String, dynamic>>> getFriends() async {
    String currentUserId = _auth.currentUser!.uid;
    final snapshot = await _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'accepted')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Принять заявку в друзья (изменение статуса и добавление в подколлекцию friends)
  Future<void> acceptFriendRequest(
      String requestId, String user1Id, String user2Id) async {
    await _firestore.collection('friendships').doc(requestId).update({
      'status': 'accepted',
    });

    // Добавляем обоих пользователей в подколлекцию friends
    await _firestore
        .collection('users')
        .doc(user1Id)
        .collection('friends')
        .doc(user2Id)
        .set({
      'friendId': user2Id,
      'addedAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('users')
        .doc(user2Id)
        .collection('friends')
        .doc(user1Id)
        .set({
      'friendId': user1Id,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Отклонить заявку в друзья (удаление записи)
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friendships').doc(requestId).delete();
  }

  // Поиск пользователей по displayName
  Future<List<Map<String, dynamic>>> searchUsersByDisplayName(
      String query) async {
    final snapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Отправить заявку в друзья
  Future<void> sendFriendRequest(String userId, String userName) async {
    String currentUserId = _auth.currentUser!.uid;
    String currentUserName = _auth.currentUser!.displayName ?? 'Пользователь';

    // Проверяем, существует ли уже заявка
    final existingRequest = await _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: currentUserId)
        .where('user2Id', isEqualTo: userId)
        .get();

    if (existingRequest.docs.isEmpty) {
      await _firestore.collection('friendships').add({
        'user1Id': currentUserId,
        'user1Name': currentUserName,
        'user2Id': userId,
        'user2Name': userName,
        'status': 'pending',
      });
    }
  }
}
