import 'package:flutter/material.dart';
import '/services/friend_service.dart';
import '/services/chat_service.dart';
import '/screens/chat/chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();

  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _friendsList = [];

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
    _loadFriendsList();
  }

  // Метод для поиска пользователей
  void _searchUsers(String query) async {
    if (query.isNotEmpty) {
      final results = await _friendService.searchUsersByDisplayName(query);
      setState(() {
        _searchResults = results;
      });
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  // Загрузка заявок в друзья
  Future<void> _loadFriendRequests() async {
    final requests = await _friendService.getFriendRequests();
    if (mounted) {
      setState(() {
        _friendRequests = requests;
      });
    }
  }

  bool _isAlreadyFriend(String userId) {
    return _friendsList.any((friend) => friend['user2Id'] == userId);
  }

  bool _isRequestPending(String userId) {
    return _friendRequests.any((request) => request['user1Id'] == userId);
  }

  Future<void> _loadFriendsList() async {
    final friends = await _friendService.getFriends();
    if (mounted) {
      setState(() {
        _friendsList = friends;
      });
    }
  }

  Future<void> _openChat(String user2Id, String user1Id) async {
    // Создаем или получаем существующий чат
    String chatId = await _chatService.openChat(user2Id, user1Id);
    // Переходим на экран чата
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId, jobId: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Друзья'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Поле для поиска друзей
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск друзей по имени',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _searchUsers(value);
              },
            ),
            SizedBox(height: 16),

            // Если идет поиск, показываем только результаты поиска
            if (_searchQuery.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      title: Text(user['displayName'] ?? 'Пользователь'),
                      trailing: _isAlreadyFriend(user['uid'])
                          ? Text('Уже в друзьях',
                              style: TextStyle(color: Colors.grey))
                          : _isRequestPending(user['uid'])
                              ? Text('Запрос отправлен',
                                  style: TextStyle(color: Colors.grey))
                              : IconButton(
                                  icon: Icon(Icons.person_add,
                                      color: Colors.blue),
                                  onPressed: () async {
                                    await _friendService.sendFriendRequest(
                                      user['uid'],
                                      user['displayName'] ?? 'Пользователь',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Заявка отправлена')),
                                    );
                                  },
                                ),
                    );
                  },
                ),
              ),

            // Если НЕ идет поиск, показываем заявки и друзей
            if (_searchQuery.isEmpty) ...[
              // Заявки в друзья
              if (_friendRequests.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _friendRequests.length,
                    itemBuilder: (context, index) {
                      final request = _friendRequests[index];
                      return ListTile(
                        title: Text(request['user1Name'] ?? 'Пользователь'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () async {
                                setState(() {
                                  _friendRequests.removeAt(
                                      index); // Убираем заявку из списка немедленно
                                });
                                await _friendService.acceptFriendRequest(
                                  request['id'],
                                  request['user1Id'],
                                  request['user2Id'],
                                );
                                _loadFriendsList(); // Подгружаем список друзей, если нужно
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () async {
                                await _friendService
                                    .rejectFriendRequest(request['id']);
                                await _loadFriendRequests();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Список друзей
              if (_friendsList.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _friendsList.length,
                    itemBuilder: (context, index) {
                      final friend = _friendsList[index];
                      return ListTile(
                        title: Text(friend['user2Name'] ?? 'Друг'),
                        trailing: IconButton(
                          icon: Icon(Icons.message, color: Colors.blue),
                          onPressed: () async {
                            // Логика открытия чата
                            await _openChat(
                                friend['user2Id'], friend['user1Id']);
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (_friendRequests.isEmpty && _friendsList.isEmpty)
                Column(
                  children: [
                    Icon(Icons.person_outline, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'У вас пока нет друзей',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                )
            ],
          ],
        ),
      ),
    );
  }
}
