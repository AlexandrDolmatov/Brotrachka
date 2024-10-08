import 'package:brotrachka/screens/jobs/job_create_screen.dart';
import 'package:flutter/material.dart';
import '/models/job_model.dart';
import '/services/job_service.dart';

class MyJobsScreen extends StatefulWidget {
  final String userId;

  MyJobsScreen({required this.userId});

  @override
  _MyJobsScreenState createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final JobService jobService = JobService();
  List<Job> myJobs = [];

  @override
  void initState() {
    super.initState();
    _fetchMyJobs();
  }

  Future<void> _fetchMyJobs() async {
    final fetchedJobs = await jobService.getJobsById(widget.userId);
    setState(() {
      myJobs = fetchedJobs as List<Job>;
    });
  }

  Future<void> _refreshJobs() async {
    await _fetchMyJobs();
  }

  // Функция для удаления вакансии
  Future<void> _deleteJob(String jobId) async {
    try {
      await jobService.deleteJob(jobId); // Удаляем вакансию через сервис
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Вакансия удалена')),
      );
      _refreshJobs(); // Обновляем список вакансий после удаления
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении вакансии: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои вакансии'),
      ),
      body: myJobs.isEmpty
          ? Center(
              child: Text(
                'Вы пока не создали ни одной вакансии',
                style: TextStyle(fontSize: 18.0),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshJobs,
              child: ListView.builder(
                itemCount: myJobs.length,
                itemBuilder: (context, index) {
                  final job = myJobs[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      title: Text(
                        job.title,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${job.payment} ₽'),
                      onTap: () {
                        Navigator.pushNamed(context, '/jobDetail',
                            arguments: job);
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Кнопка редактирования
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JobCreateScreen(job: job),
                                ),
                              ).then((_) => _refreshJobs());
                            },
                          ),
                          // Кнопка удаления
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Подтверждение удаления вакансии
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Удалить вакансию?'),
                                  content: Text(
                                      'Вы уверены, что хотите удалить эту вакансию?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteJob(job.id); // Удаляем вакансию
                                      },
                                      child: Text('Удалить'),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
