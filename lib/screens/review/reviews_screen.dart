import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/review_service.dart'; // Подключаем ReviewService
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

final logger = Logger();

class ReviewsScreen extends StatelessWidget {
  final String userId; // ID пользователя, чьи отзывы просматриваются

  const ReviewsScreen({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ReviewService _reviewService = ReviewService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Отзывы'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reviewService.getReviewsForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            logger.d('Отзывов получено: ${snapshot.data?.docs.length ?? 0}');
            logger.d('Запрос отзывов для пользователя с ID: $userId');
            return Center(child: Text('Нет отзывов'));
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              logger.d('Отзыв: ${review.data()}');

              final double? rating =
                  review['rating'] != null ? review['rating'].toDouble() : null;
              final String comment =
                  review['comment'] ?? 'Комментарий отсутствует';

              // Проверяем, есть ли поле createdAt
              final Timestamp? timestamp = review['createdAt'] as Timestamp?;
              final String createdAt = timestamp != null
                  ? DateFormat('dd.MM.yyyy').format(timestamp.toDate())
                  : 'Дата отсутствует';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Row(
                    children: [
                      Text('Рейтинг: ${rating?.toString() ?? "N/A"}'),
                      SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment, style: TextStyle(fontSize: 20)),
                      Text(
                        'Оставлен: $createdAt',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
