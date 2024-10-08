import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import '/models/job_model.dart';
import '/widgets/user_profile_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ProfileScreen extends StatelessWidget {
  final bool isWorker; // Если true - рабочий, false - работодатель
  final String displayName;
  final double rating;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Job? job;

  ProfileScreen({
    required this.isWorker,
    required this.displayName,
    required this.rating,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Профиль',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GestureDetector для контейнера с фото, именем и рейтингом
            GestureDetector(
              onTap: () {
                logger.d('Переход на страницу с id: $userId');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileWidget(userId: userId),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[
                      200], // Используем серый цвет для соответствия стилю приложения
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Row(
                  children: [
                    // Фото пользователя
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                Colors.grey[300], // Заглушка при ожидании
                          );
                        } else if (snapshot.hasError) {
                          return CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(
                              'assets/svg/default_avatar.png', // При ошибке
                            ),
                          );
                        } else if (snapshot.hasData && snapshot.data!.exists) {
                          var userData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          String? avatarUrl = userData['profileImageUrl'];

                          if (avatarUrl != null && avatarUrl.isNotEmpty) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  NetworkImage(avatarUrl), // Загружаем аватар
                            );
                          } else {
                            return CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                'assets/svg/default_avatar.png', // Дефолтное изображение
                              ),
                            );
                          }
                        } else {
                          return CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(
                              'assets/svg/default_avatar.png', // Если данных нет
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(width: 16.0),
                    // Имя и рейтинг
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.yellow, size: 20.0),
                            SizedBox(width: 4.0),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 25.0),
            // Кнопки
            _buildButton(context, 'Изменить профиль', Icons.edit, () {
              Navigator.pushNamed(context, '/editProfile');
            }),
            SizedBox(height: 16.0), // Пространство между кнопками
            _buildButton(context, 'Моя роль', Icons.person_outline, () {
              Navigator.pushNamed(context, '/myRole');
            }),
            SizedBox(height: 20.0),
            // Роль специфичные кнопки
            if (isWorker) ...[
              _buildButton(context, 'Мои отклики', Icons.send, () {
                Navigator.pushNamed(context, '/myApplications');
              }),
              SizedBox(height: 16.0),
              _buildButton(context, 'Отзывы', Icons.rate_review, () {
                Navigator.pushNamed(context, '/reviews', arguments: userId);
              }),
              SizedBox(height: 16.0),
              _buildButton(context, 'Друзья', Icons.people_outline, () {
                Navigator.pushNamed(context, '/friendsList');
              }),
            ] else ...[
              _buildButton(context, 'Мои вакансии', Icons.work_outline, () {
                Navigator.pushNamed(
                  context,
                  '/myJobs',
                  arguments: userId,
                );
              }),
              SizedBox(height: 16.0),
              _buildButton(context, 'Создать вакансию', Icons.add_box, () {
                Navigator.pushNamed(context, '/jobCreate');
              }),
              SizedBox(height: 16.0),
              _buildButton(context, 'Отзывы', Icons.rate_review, () {
                Navigator.pushNamed(
                  context,
                  '/reviews',
                  arguments: userId,
                );
              }),
              SizedBox(height: 16.0),
              _buildButton(context, 'Отклики', Icons.send, () {
                Navigator.pushNamed(
                  context,
                  '/userJobs',
                  arguments: userId,
                );
              }),
            ],
            SizedBox(height: 30.0),
            // Кнопка выхода
            _buildButton(
              context,
              'Выйти из аккаунта',
              Icons.logout,
              () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Функция для создания кнопок
  Widget _buildButton(BuildContext context, String text, IconData icon,
      VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24.0),
        label: Text(
          text,
          style: TextStyle(fontSize: 18.0),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50), // Кнопка на всю ширину
          backgroundColor: Colors.grey[200], // Цвет кнопки (серый)
          foregroundColor: Colors.black, // Цвет текста (черный)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}
