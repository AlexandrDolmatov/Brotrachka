import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Метод для создания вакансии с учетом нового поля peopleRequired
  Future<void> createJob(
    Job newJob, {
    required String title,
    required String description,
    required int payment,
    required String requirements,
    required String jobType,
    required int peopleRequired, // Новое поле
    required String city,
  }) async {
    try {
      // Получаем текущего пользователя
      User? user = _auth.currentUser;

      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Создаем документ с автоматическим ID
      DocumentReference jobRef = _firestore.collection('jobs').doc();

      // Сохраняем сгенерированный ID в объекте вакансии
      newJob.id = jobRef.id;

      // Добавляем новую вакансию в коллекцию jobs
      await jobRef.set({
        'id': newJob.id, // Сохранение jobId в документе
        'title': title,
        'description': description,
        'jobType': jobType,
        'payment': payment,
        'requirements': requirements,
        'peopleRequired':
            peopleRequired, // Сохраняем требуемое количество людей
        'acceptedPeople': 0, // Изначально 0 принятых людей
        'employerId': user.uid, // ID работодателя
        'createdAt': FieldValue.serverTimestamp(),
        'city': city,
      });
    } catch (e) {
      throw Exception("Error creating job: $e");
    }
  }

  // Метод для обновления существующей вакансии
  Future<void> updateJob(Job updatedJob) async {
    try {
      // Получаем ссылку на документ вакансии по ID
      DocumentReference jobRef =
          _firestore.collection('jobs').doc(updatedJob.id);

      // Обновляем данные вакансии
      await jobRef.update({
        'title': updatedJob.title,
        'description': updatedJob.description,
        'jobType': updatedJob.jobType,
        'payment': updatedJob.payment,
        'requirements': updatedJob.requirements,
        'peopleRequired': updatedJob.peopleRequired,
        'acceptedPeople': updatedJob.acceptedPeople,
        'city': updatedJob.city, // Обновляем acceptedPeople, если нужно
        // Не обновляем 'createdAt', чтобы сохранить время создания
      });
    } catch (e) {
      throw Exception("Error updating job: $e");
    }
  }

  // Получение списка всех вакансий
  Future<List<Job>> getJobs() async {
    QuerySnapshot snapshot = await _firestore.collection('jobs').get();

    return snapshot.docs.map((doc) {
      return Job.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Получение вакансий по ID работодателя
  Future<List<Job>> getJobsById(String employerId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('jobs')
        .where('employerId', isEqualTo: employerId)
        .get();

    return snapshot.docs.map((doc) {
      return Job.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Метод для увеличения количества принятых людей на вакансию
  Future<void> incrementAcceptedPeople(String jobId) async {
    try {
      DocumentReference jobRef = _firestore.collection('jobs').doc(jobId);

      // Используем транзакцию для корректного увеличения значения
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot jobSnapshot = await transaction.get(jobRef);

        if (!jobSnapshot.exists) {
          throw Exception("Job does not exist");
        }

        int currentAccepted = jobSnapshot['acceptedPeople'] ?? 0;
        int peopleRequired = jobSnapshot['peopleRequired'] ?? 1;

        if (currentAccepted >= peopleRequired) {
          throw Exception("All required positions are already filled");
        }

        // Обновляем количество принятых людей
        transaction.update(jobRef, {
          'acceptedPeople': currentAccepted + 1,
        });
      });
    } catch (e) {
      throw Exception("Error updating accepted people count: $e");
    }
  }

  // Метод для уменьшения количества принятых людей на вакансию (например, при отмене заявки)
  Future<void> decrementAcceptedPeople(String jobId) async {
    try {
      DocumentReference jobRef = _firestore.collection('jobs').doc(jobId);

      // Используем транзакцию для корректного уменьшения значения
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot jobSnapshot = await transaction.get(jobRef);

        if (!jobSnapshot.exists) {
          throw Exception("Job does not exist");
        }

        int currentAccepted = jobSnapshot['acceptedPeople'] ?? 0;

        if (currentAccepted > 0) {
          // Уменьшаем количество принятых людей
          transaction.update(jobRef, {
            'acceptedPeople': currentAccepted - 1,
          });
        }
      });
    } catch (e) {
      throw Exception("Error updating accepted people count: $e");
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
    } catch (e) {
      throw Exception('Ошибка при удалении вакансии: $e');
    }
  }
}
