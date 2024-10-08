import 'package:brotrachka/models/job_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get userCollection => _firestore.collection('users');

  // Получение данных пользователя по UID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(userId).get();
    return userSnapshot.exists
        ? userSnapshot.data() as Map<String, dynamic>?
        : null;
  }

  // Метод для отклика на вакансию
  Future<void> respondToJob(String jobId, String jobTitle) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Добавляем отклик в подколлекцию applications внутри вакансии
      await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(user.uid) // uid пользователя в качестве ID документа
          .set({
        'userId': user.uid,
        'status': 'waiting'
      }); // сохраняем userId в документе

      // Сохраняем отклик в подколлекцию applications внутри документа пользователя
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('applications') // создаем подколлекцию applications
          .doc(jobId) // ID документа = jobId
          .set({
        'jobId': jobId, // ID вакансии
        'jobTitle': jobTitle, // Название вакансии
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
      });
    } catch (e) {
      throw Exception("Error responding to job: $e");
    }
  }

  // Метод для получения откликов на вакансию
  Future<List<String>> getUserResponses(String jobId) async {
    try {
      // Получаем коллекцию applications для заданного jobId
      QuerySnapshot applicationsSnapshot = await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .get();

      // Получаем userIds из документов
      List<String> userIds =
          applicationsSnapshot.docs.map((doc) => doc.id).toList();
      return userIds;
    } catch (e) {
      print("Error fetching user responses: $e");
      return [];
    }
  }

  // Метод для получения всех откликов пользователя
  Future<List<Map<String, dynamic>>> getUserApplications() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Получаем подколлекцию applications для текущего пользователя
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('applications')
          .get();

      // Преобразуем документы в список Map<String, dynamic>
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching user applications: $e");
      return [];
    }
  }

  Future<Job?> getJobById(String jobId) async {
    try {
      DocumentSnapshot jobSnapshot =
          await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();

      if (jobSnapshot.exists) {
        return Job.fromMap(jobSnapshot.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error fetching job by id: $e");
    }
    return null;
  }

  // Метод для проверки, откликнулся ли пользователь на вакансию
  Future<bool> hasUserResponded(String jobId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Проверяем, существует ли документ с откликом для текущего пользователя
      DocumentSnapshot responseSnapshot = await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(user.uid)
          .get();

      return responseSnapshot.exists;
    } catch (e) {
      print("Error checking if user responded: $e");
      return false;
    }
  }
}
