import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brotrachka/services/auth_service.dart';

class CategorySelectionScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Выберите категорию',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue, // Цвет AppBar
        centerTitle: true, // Центрируем заголовок
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Добавляем отступы со всех сторон
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Большая кнопка "Рабочий"
            ElevatedButton(
              onPressed: () async {
                User? user = _authService.currentUser;
                if (user != null) {
                  await _authService.updateRole(user.uid, 'worker');
                  Navigator.pushNamed(context, '/', arguments: {
                    'isWorker': true,
                    'name': user.displayName ?? '',
                    'rating': 0.0,
                  });
                }
              },
              child: Text(
                'Рабочий',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 70), // Кнопка на всю ширину
                backgroundColor: Colors.blue, // Синий цвет кнопки
                foregroundColor: Colors.white, // Белый цвет текста
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            SizedBox(height: 30), // Пространство между кнопками
            // Большая кнопка "Работодатель"
            ElevatedButton(
              onPressed: () async {
                User? user = _authService.currentUser;
                if (user != null) {
                  await _authService.updateRole(user.uid, 'employer');
                  Navigator.pushNamed(context, '/', arguments: {
                    'isWorker': false,
                    'name': user.displayName ?? '',
                    'rating': 0.0,
                  });
                }
              },
              child: Text(
                'Работодатель',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 70), // Кнопка на всю ширину
                backgroundColor: Colors.blue, // Синий цвет кнопки
                foregroundColor: Colors.white, // Белый цвет текста
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
