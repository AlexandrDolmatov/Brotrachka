import 'package:flutter/material.dart';
import '/models/job_model.dart';
import '/services/job_service.dart';
import '/screens/jobs/job_filter_screen.dart';

class JobListScreen extends StatefulWidget {
  @override
  _JobListScreenState createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final JobService jobService = JobService();
  List<Job> jobs = [];
  String searchQuery = '';
  String selectedJobType = 'Все';
  String selectedcity = ''; // Город должен быть строкой, а не числом
  int minPayment = 0;
  int maxPayment = 1000000;

  bool isFilterApplied = false;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final fetchedJobs = await jobService.getJobs();
      setState(() {
        jobs = fetchedJobs;
        // Не нужно сбрасывать флаг isFilterApplied при загрузке вакансий
      });
    } catch (error) {
      // Добавь обработку ошибок на случай проблем с загрузкой данных
      print('Ошибка загрузки вакансий: $error');
    }
  }

  void _searchJobs(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      selectedJobType = filters['jobType'];
      selectedcity = filters['city']; // Используй строку, а не число для города
      minPayment = filters['minPayment'];
      maxPayment = filters['maxPayment'];
      isFilterApplied = true; // Флаг для отслеживания применения фильтра
    });
  }

  Future<void> _refreshJobs() async {
    if (isFilterApplied) {
      // Если фильтры активны, повторно применяем их
      setState(() {
        // Здесь не нужно сбрасывать фильтры, просто повторное применение фильтров
        // или вызов фильтрации с текущими параметрами
      });
    } else {
      await _fetchJobs(); // Если фильтры не применены, обновляем данные с сервера
    }
  }

  void _resetFilters() {
    setState(() {
      selectedJobType = 'Все';
      selectedcity = '';
      minPayment = 0;
      maxPayment = 1000000;
      isFilterApplied = false;
    });
    // Сброс списка вакансий после сброса фильтров
    _fetchJobs();
  }

  @override
  Widget build(BuildContext context) {
    // Фильтрация вакансий
    final filteredJobs = jobs.where((job) {
      bool matchesJobType =
          selectedJobType == 'Все' || job.jobType == selectedJobType;
      bool matchesPayment =
          job.payment >= minPayment && job.payment <= maxPayment;
      bool matchesSearch = job.title.toLowerCase().contains(searchQuery);
      bool matchesCity = selectedcity.isEmpty || job.city == selectedcity;

      // Условие скрытия вакансий, если они полностью укомплектованы
      bool isVacancyOpen = job.acceptedPeople < job.peopleRequired;

      return matchesJobType &&
          matchesPayment &&
          matchesSearch &&
          matchesCity &&
          isVacancyOpen;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Убираем стрелку назад
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Brotrachka',
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return JobFilterScreen(
                    onApplyFilters: _applyFilters,
                    initialFilters: {
                      'jobType': selectedJobType,
                      'city':
                          selectedcity, // Корректное значение для фильтра города
                      'minPayment': minPayment,
                      'maxPayment': maxPayment,
                    },
                  );
                },
                isScrollControlled: true,
              );
            },
          ),
          if (isFilterApplied)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.red),
              onPressed: _resetFilters, // Кнопка для сброса фильтров
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: _searchJobs,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshJobs,
              child: ListView.builder(
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
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
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
