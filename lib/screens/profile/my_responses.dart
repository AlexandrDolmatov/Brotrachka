import 'package:brotrachka/screens/jobs/job_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Подключаем intl для форматирования дат
import '/models/job_model.dart';
//import '/screens/jobs/job_detail_screen.dart';
import '/services/user_service.dart';

class MyResponsesScreen extends StatefulWidget {
  const MyResponsesScreen({Key? key}) : super(key: key);

  @override
  _MyResponsesScreenState createState() => _MyResponsesScreenState();
}

class _MyResponsesScreenState extends State<MyResponsesScreen> {
  final UserService userService = UserService();
  List<Map<String, dynamic>> userApplications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserApplications();
  }

  // Получаем список откликов пользователя
  Future<void> _fetchUserApplications() async {
    try {
      List<Map<String, dynamic>> applications =
          await userService.getUserApplications();
      setState(() {
        userApplications = applications;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching user applications: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Метод для форматирования даты с помощью intl
  String _formatDate(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои отклики'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userApplications.isEmpty
              ? const Center(
                  child: Text(
                    'Вы еще не откликнулись на вакансии.',
                    style: TextStyle(fontSize: 18.0),
                  ),
                )
              : ListView.builder(
                  itemCount: userApplications.length,
                  itemBuilder: (context, index) {
                    var application = userApplications[index];
                    String jobId = application['jobId'];
                    String jobTitle = application['jobTitle'] ?? 'Без названия';
                    Timestamp appliedAt = application['appliedAt'];
                    String status = application['status'] ?? 'waiting';

                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                      child: ListTile(
                        title: Text(
                          jobTitle,
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Откликнулись: ${_formatDate(appliedAt)}',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            Text(
                              'Статус: ${status == 'waiting' ? 'Ожидает' : status == 'accepted' ? 'Принят' : 'Отклонен'}',
                              style: TextStyle(
                                color: status == 'accepted'
                                    ? Colors.green
                                    : status == 'denied'
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          // Получаем данные о вакансии по jobId и переходим на экран деталей
                          Job? job = await userService.getJobById(jobId);
                          if (job != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailScreen(job: job),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ошибка при загрузке вакансии'),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
