import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  String? getCurrentUserId() {
    User? user = _firebaseAuth.currentUser;
    return user?.uid;
  }

  Future<User?> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      // Шаг 1: Проверка уникальности никнейма
      bool nicknameExists = await checkIfNicknameExists(displayName);
      if (nicknameExists) {
        throw Exception('Никнейм уже существует. Выберите другой никнейм.');
      }

      // Шаг 2: Создание пользователя в Firebase Authentication
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Шаг 3: Сохранение данных пользователя в коллекции users
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'email': email,
          'role': 'worker', // по умолчанию роль "worker"
          'uid': user.uid,
          'profileImageUrl': '',
          'city': 'Город не указан',
        });

        // Шаг 4: Добавление никнейма в коллекцию nicknames
        await _addNickname(displayName);
      }

      return user;
    } catch (e) {
      print('Ошибка при регистрации: $e');
      return null;
    }
  }

  // Проверка, существует ли никнейм
  Future<bool> checkIfNicknameExists(String nickname) async {
    DocumentSnapshot<Map<String, dynamic>> docSnapshot =
        await _firestore.collection('nicknames').doc('nicks').get();

    if (docSnapshot.exists) {
      List<dynamic> nicknames = docSnapshot.data()?['nicknames'] ?? [];
      return nicknames.contains(nickname); // Проверяем, существует ли никнейм
    }

    return false; // Если документа нет, считаем, что никнейм уникален
  }

  // Добавление нового никнейма в базу данных
  Future<void> _addNickname(String nickname) async {
    await _firestore.collection('nicknames').doc('nicks').update({
      'nicknames':
          FieldValue.arrayUnion([nickname]), // Добавляем новый никнейм в массив
    });
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> updateRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('users').doc(uid).get();
      return snapshot.data();
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
