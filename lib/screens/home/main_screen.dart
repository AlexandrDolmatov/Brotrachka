import 'package:flutter/material.dart';
import 'package:brotrachka/screens/jobs/job_list_screen.dart';
import 'package:brotrachka/screens/chat/chat_list_screen.dart';
import 'package:brotrachka/screens/profile/profile_screen.dart';
import 'package:brotrachka/services/auth_service.dart';
import '/models/job_model.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Параметры пользователя (в реальном приложении данные могут быть загружены из Firebase)
  final AuthService _authService = AuthService();
  late String _displayName;
  late bool _isWorker;
  late double _rating;
  Job? _job;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    var user = _authService.currentUser;
    if (user != null) {
      var userData = await _authService.getUserData(user.uid);
      setState(() {
        _displayName = userData?['displayName'] ?? 'Неизвестно';
        _isWorker = userData?['role'] == 'worker';
        _rating = (userData?['rating'] ?? 0).toDouble();
      });
    }
  }

  // Список экранов
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return JobListScreen();
      case 1:
        return ChatListScreen();
      case 2:
        return ProfileScreen(
          displayName: _displayName,
          isWorker: _isWorker,
          rating: _rating,
          job: _job,
        );
      default:
        return JobListScreen();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Вакансии',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Чат',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
