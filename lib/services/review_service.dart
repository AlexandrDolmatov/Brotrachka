import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Добавление нового отзыва
  Future<void> addReview({
    required String reviewerId,
    required String revieweeId,
    required double rating,
    required String comment,
    required String jobId,
  }) async {
    try {
      await _firestore.collection('reviews').add({
        'reviewerId': reviewerId,
        'revieweeId': revieweeId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'jobId': jobId,
      });

      // Обновить рейтинг у пользователя
      await _updateUserRating(revieweeId);
    } catch (e) {
      print('Error adding review: $e');
    }
  }

  // Получение всех отзывов для конкретного пользователя
  Stream<QuerySnapshot> getReviewsForUser(String userId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .snapshots();
  }

  // Подсчет и обновление среднего рейтинга для пользователя
  Future<void> _updateUserRating(String userId) async {
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .get();

    if (reviewsSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      int reviewCount = reviewsSnapshot.docs.length;

      for (var review in reviewsSnapshot.docs) {
        totalRating += review['rating'];
      }

      double averageRating = totalRating / reviewCount;

      // Обновить средний рейтинг в профиле пользователя
      await _firestore.collection('users').doc(userId).update({
        'rating': averageRating,
      });
    }
  }
}
