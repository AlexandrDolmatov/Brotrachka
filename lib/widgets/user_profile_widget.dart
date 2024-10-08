import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '/models/job_model.dart';
import '/models/usermodel_model.dart'; // Подключаем модель пользователя
import 'package:logger/logger.dart';
//import 'package:flutter_svg/flutter_svg.dart'; // Подключаем пакет для работы с SVG

final logger = Logger();

class UserProfileWidget extends StatelessWidget {
  final String userId; // ID пользователя, которого нужно отобразить

  UserProfileWidget({required this.userId});

  Future<UserModel> _getUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return UserModel.fromDocumentSnapshot(userDoc);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      // Логирование ошибки
      logger.d('Ошибка загрузки данных пользователя: $e');
      throw e; // Пробрасываем ошибку дальше
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки данных'));
        }

        if (!snapshot.hasData) {
          return Center(child: Text('Пользователь не найден'));
        }

        final user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(user.displayName),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAvatar(userId), // Загрузка аватара пользователя
                SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(user.city),
                SizedBox(height: 8),
                Text('Рейтинг: ${user.rating.toStringAsFixed(1)}'),
                SizedBox(height: 24),
                user.role == 'employer'
                    ? _buildEmployerInfo(context, user) // Передаем context
                    : _buildWorkerInfo(user),
              ],
            ),
          ),
        );
      },
    );
  }

  // Функция для загрузки аватара пользователя
  Widget _buildAvatar(String? userId) {
    if (userId == null || userId.isEmpty) {
      logger.d(
          'UserId пустой'); // Если userId пустой, показываем дефолтное изображение
      return CircleAvatar(
        radius: 50,
        backgroundImage: AssetImage('assets/svg/default_avatar.png'),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Пока данные загружаются
        }

        if (snapshot.hasError) {
          return CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(
                'assets/svg/default_avatar.png'), // Дефолтное изображение при ошибке
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          String? avatarUrl = data['profileImageUrl'];

          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            return CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                  avatarUrl), // Загружаем аватар из Firebase Storage
            );
          }
        }

        // Если аватара нет, подгружаем дефолтное изображение
        return CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage(
              'assets/svg/default_avatar.png'), // Дефолтное изображение
        );
      },
    );
  }

  Widget _buildEmployerInfo(BuildContext context, UserModel user) {
    // Показываем вакансии заказчика
    return Expanded(
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('jobs')
            .where('employerId', isEqualTo: user.id)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки вакансий'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Нет активных вакансий'));
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job =
                  Job.fromMap(jobs[index].data() as Map<String, dynamic>);

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // Переход на экран вакансии с передачей объекта Job
                    Navigator.pushNamed(context, '/jobDetail', arguments: job);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              job.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${job.payment} ₽',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          job.description,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        SizedBox(height: 4),
                        Text(
                          'Опубликовано: ${DateFormat('dd.MM.yyyy').format(job.postedAt)}',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkerInfo(UserModel user) {
    // Показываем отзывы исполнителя
    return Expanded(
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('reviews')
            .where('revieweeId', isEqualTo: user.id)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки отзывов'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Рейтинг: ${rating?.toString() ?? "N/A"}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Row(
                            children: List.generate(
                              rating != null ? rating.round() : 0,
                              (index) => Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        comment,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Оставлен: $createdAt',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
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
