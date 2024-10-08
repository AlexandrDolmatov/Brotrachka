import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  String id;
  String title;
  String description;
  String jobType;
  int payment;
  String requirements;
  int peopleRequired; // Новое поле
  int acceptedPeople; // Новое поле для количества принятых сотрудников
  DateTime postedAt;
  String city;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.jobType,
    required this.payment,
    required this.requirements,
    required this.peopleRequired,
    required this.acceptedPeople, // Новое поле
    required this.postedAt,
    required this.city,
  });

  // Добавьте сериализацию и десериализацию для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'jobType': jobType,
      'payment': payment,
      'requirements': requirements,
      'peopleRequired': peopleRequired,
      'acceptedPeople': acceptedPeople, // Новое поле
      'postedAt': postedAt,
      'city': city,
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      jobType: map['jobType'] ?? '',
      payment: map['payment'] ?? 0,
      requirements: map['requirements'] ?? '',
      peopleRequired: map['peopleRequired'] ?? 1,
      acceptedPeople: map['acceptedPeople'] ?? 0, // Новое поле
      postedAt: (map['postedAt'] != null)
          ? (map['postedAt'] as Timestamp).toDate()
          : DateTime.now(),
      city: map['city'] ?? '',
    );
  }
}
