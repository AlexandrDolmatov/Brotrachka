import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/screens/chat/chat_screen.dart';
import '/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/widgets/user_profile_widget.dart'; // Импортируем ваш виджет профиля

class ResponsesScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ResponsesScreen({required this.jobId, required this.jobTitle, Key? key})
      : super(key: key);

  @override
  _ResponsesScreenState createState() => _ResponsesScreenState();
}

class _ResponsesScreenState extends State<ResponsesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();

  Future<List<Map<String, dynamic>>> _getApplications() async {
    final snapshot = await _firestore
        .collection('jobs')
        .doc(widget.jobId)
        .collection('applications')
        .where('status', isEqualTo: 'waiting')
        .get();

    List<Map<String, dynamic>> applications = [];
    for (var doc in snapshot.docs) {
      final userDoc = await _firestore.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        applications.add(userDoc.data()!);
      }
    }
    return applications;
  }

  Future<void> _updateApplicationStatus(String userId, String status) async {
    await _firestore
        .collection('jobs')
        .doc(widget.jobId)
        .collection('applications')
        .doc(userId)
        .update({'status': status});

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('applications')
        .doc(widget.jobId)
        .update({'status': status});

    setState(() {});
  }

  Future<void> _acceptApplication(String workerId, String workerName) async {
    String employerId = _auth.currentUser!.uid;

    String chatId =
        await _chatService.createOrGetChat(employerId, workerId, widget.jobId);

    await _chatService.sendMessage(
      chatId: chatId,
      senderId: employerId,
      receiverId: workerId,
      text: "Вы приняты на работу ${widget.jobTitle}!",
    );

    await _firestore.collection('jobs').doc(widget.jobId).update({
      'acceptedPeople': FieldValue.increment(1),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId, jobId: widget.jobId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отклики'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getApplications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Нет откликов'));
          }

          final applications = snapshot.data!;

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final applicant = applications[index];
              final String name = applicant['displayName'] ?? 'Без имени';
              final double rating = (applicant['rating'] ?? 0).toDouble();
              final String workerId = applicant['uid'] ?? 'None';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(name),
                  subtitle: rating > 0
                      ? Text(
                          'Рейтинг: $rating',
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle,
                            color: Colors.green, size: 32.0),
                        onPressed: () {
                          _updateApplicationStatus(workerId, 'accepted');
                          _acceptApplication(workerId, name);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red, size: 32.0),
                        onPressed: () {
                          _updateApplicationStatus(workerId, 'denied');
                        },
                      ),
                    ],
                  ),
                  // Добавляем onTap для перехода на экран профиля рабочего
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserProfileWidget(userId: workerId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
