import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brotrachka/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Заголовок
            Text(
              'Регистрация',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 40),

            // Поле ввода Email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Поле ввода Пароля с возможностью его просмотра
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 5),

            // Уведомление о минимальной длине пароля
            Text(
              'Пароль должен содержать минимум 6 символов',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 20),

            // Поле ввода Имени пользователя
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Имя пользователя',
                prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 40),

            // Кнопка "Зарегистрироваться"
            ElevatedButton(
              onPressed: () async {
                try {
                  // Проверка на никнейм перед регистрацией
                  bool nicknameExists = await _authService
                      .checkIfNicknameExists(_displayNameController.text);
                  if (nicknameExists) {
                    setState(() {
                      _errorMessage = 'Данное имя пользователя уже занято';
                    });
                    return;
                  }

                  if (_passwordController.text.length < 6) {
                    setState(() {
                      _errorMessage =
                          'Пароль должен содержать минимум 6 символов';
                    });
                    return;
                  }

                  User? user = await _authService.registerWithEmailAndPassword(
                    _emailController.text,
                    _passwordController.text,
                    _displayNameController.text,
                  );

                  if (user != null) {
                    Navigator.pushNamed(context, '/categorySelection');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Не удалось зарегистрироваться')),
                    );
                  }
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Ошибка: $e';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  'Зарегистрироваться',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Отображение ошибки, если есть
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),

            SizedBox(height: 20),

            // Кнопка "Уже есть аккаунт? Войти"
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                'Уже есть аккаунт? Войти',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
