import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brotrachka/services/job_service.dart';
import 'package:brotrachka/models/job_model.dart';

class UserJobsScreen extends StatefulWidget {
  final String userId;

  UserJobsScreen({required this.userId});
  @override
  _UserJobsScreenState createState() => _UserJobsScreenState();
}

class _UserJobsScreenState extends State<UserJobsScreen> {
  final JobService _jobService = JobService();
  List<Job> _jobs = [];

  @override
  void initState() {
    super.initState();
    _fetchUserJobs();
  }

  Future<void> _fetchUserJobs() async {
    var jobs = await _jobService.getJobsById(widget.userId);
    setState(() {
      _jobs = jobs;
    });
  }

  Future<void> _refreshJobs() async {
    await _fetchUserJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои вакансии'),
      ),
      body: _jobs.isEmpty
          ? Center(
              child: Text(
              'У вас нет вакансий',
              style: TextStyle(fontSize: 18.0),
            ))
          : RefreshIndicator(
              onRefresh: _refreshJobs,
              child: ListView.builder(
                itemCount: _jobs.length,
                itemBuilder: (context, index) {
                  final job = _jobs[index];
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
                        Navigator.pushNamed(context, '/responses',
                            arguments: job);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
