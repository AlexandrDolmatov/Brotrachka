import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String city;
  final double rating;
  final String avatarUrl;
  final String role;

  UserModel({
    required this.id,
    required this.displayName,
    required this.city,
    required this.rating,
    required this.avatarUrl,
    required this.role,
  });

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id, // ID документа всегда существует
      displayName: data['displayName'] ?? 'Неизвестно', // Поле name
      city: data['city'] ?? 'Город не указан', // Поле city
      rating: data['rating'] != null
          ? data['rating'].toDouble()
          : 0.0, // Поле rating
      avatarUrl: data['avatarUrl'] ?? '', // Проверяем, есть ли avatarUrl
      role: data['role'] ?? 'worker', // Роль пользователя
    );
  }
}
