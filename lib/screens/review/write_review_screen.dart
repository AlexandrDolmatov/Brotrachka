import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/review_service.dart'; // Импортируем наш сервис для отзывов

class WriteReviewScreen extends StatefulWidget {
  final String revieweeId; // ID исполнителя, которому оставляется отзыв
  final String jobId; // ID работы, для которой оставляется отзыв

  WriteReviewScreen({required this.revieweeId, required this.jobId});

  @override
  _WriteReviewScreenState createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _rating = 0; // Рейтинг по умолчанию
  final TextEditingController _commentController = TextEditingController();
  final ReviewService _reviewService = ReviewService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSubmitting = false; // Флаг, чтобы показывать индикатор загрузки

  // Отправка отзыва
  Future<void> _submitReview() async {
    final comment = _commentController.text;
    final currentUser = _auth.currentUser;

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, выберите рейтинг')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Отправка отзыва через ReviewService
      await _reviewService.addReview(
        reviewerId: currentUser!.uid, // ID текущего пользователя
        revieweeId:
            widget.revieweeId, // ID пользователя, которому оставляют отзыв
        rating: _rating,
        comment: comment,
        jobId: widget.jobId, // ID работы
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Отзыв успешно отправлен!')),
      );
      Navigator.of(context).pop(); // Закрываем экран после успешной отправки
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке отзыва: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black54.withOpacity(0.7), // Полупрозрачное поле
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Оставьте отзыв',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // Звездный рейтинг
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0; // Обновляем рейтинг
                    });
                  },
                );
              }),
            ),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Комментарий',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            _isSubmitting
                ? CircularProgressIndicator() // Индикатор загрузки при отправке
                : ElevatedButton(
                    onPressed: _submitReview,
                    child: Text('Оценить'),
                  ),
          ],
        ),
      ),
    );
  }
}
