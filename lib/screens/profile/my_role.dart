import 'package:flutter/material.dart';
import 'package:brotrachka/services/auth_service.dart';

class MyRoleScreen extends StatefulWidget {
  @override
  _MyRoleScreenState createState() => _MyRoleScreenState();
}

class _MyRoleScreenState extends State<MyRoleScreen> {
  final AuthService _authService = AuthService();
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // Получаем роль текущего пользователя
  Future<void> _fetchUserRole() async {
    String? userId = _authService.getCurrentUserId();
    if (userId != null) {
      Map<String, dynamic>? userData = await _authService.getUserData(userId);
      setState(() {
        _currentRole = userData?['role'] ?? 'Неизвестно';
      });
    }
  }

  // Метод для смены роли
  Future<void> _updateRole(String newRole) async {
    String? userId = _authService.getCurrentUserId();
    if (userId != null) {
      await _authService.updateRole(userId, newRole);
      setState(() {
        _currentRole = newRole;
      });
    }
  }

  // Метод для преобразования role из Firestore в человекочитаемый формат
  String _getReadableRole(String? role) {
    if (role == 'worker') {
      return 'Рабочий';
    } else if (role == 'employer') {
      return 'Работодатель';
    } else {
      return 'Неизвестно';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Моя роль',
            style: TextStyle(letterSpacing: 1.5, fontSize: 28)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Отображение текущей роли
              Text(
                'Ваша текущая роль:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                _getReadableRole(_currentRole),
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
              ),
              SizedBox(height: 40),

              // Кнопка смены роли на Рабочий
              ElevatedButton(
                onPressed: () => _updateRole('worker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Цвет кнопки
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20), // Размер кнопки
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Закругление краев
                  ),
                ),
                child: Text(
                  'Сменить роль на Рабочий',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),

              // Кнопка смены роли на Работодатель
              ElevatedButton(
                onPressed: () => _updateRole('employer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Цвет кнопки
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20), // Размер кнопки
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Закругление краев
                  ),
                ),
                child: Text(
                  'Сменить роль на Работодатель',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
