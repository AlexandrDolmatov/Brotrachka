import 'package:cloud_firestore/cloud_firestore.dart'; // Для работы с Firestore
import 'package:flutter/material.dart';
import '/models/job_model.dart';
import '/services/user_service.dart';
import '/services/auth_service.dart';
import '/widgets/user_profile_widget.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job; // Аргумент для города

  const JobDetailScreen({required this.job});

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final UserService userService = UserService();
  final AuthService authService = AuthService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool hasResponded = false;
  String employerName = '';
  double employerRating = 0.0;
  String employerId = '';

  @override
  void initState() {
    super.initState();
    _checkIfResponded();
    _loadEmployerData(); // Загрузка данных о работодателе
  }

  // Проверка, откликнулся ли пользователь на эту вакансию
  Future<void> _checkIfResponded() async {
    bool responded = await userService.hasUserResponded(widget.job.id);
    setState(() {
      hasResponded = responded;
    });
  }

  // Загрузка данных о работодателе из Firestore
  Future<void> _loadEmployerData() async {
    try {
      // Получаем employerId из коллекции jobs по id вакансии
      DocumentSnapshot jobSnapshot =
          await firestore.collection('jobs').doc(widget.job.id).get();

      if (jobSnapshot.exists) {
        employerId = jobSnapshot['employerId'];

        // После получения employerId получаем данные о пользователе из коллекции users
        DocumentSnapshot userSnapshot =
            await firestore.collection('users').doc(employerId).get();

        if (userSnapshot.exists) {
          setState(() {
            employerName = userSnapshot['displayName'] ?? 'Неизвестно';
            employerRating = userSnapshot['rating'] != null
                ? userSnapshot['rating'].toDouble()
                : 0.0;
          });
        }
      }
    } catch (e) {
      print('Ошибка при загрузке данных о работодателе: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось загрузить данные работодателя'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали вакансии'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок вакансии
            Text(
              widget.job.title,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 8.0),

            // Город
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.redAccent),
                SizedBox(width: 8.0),
                Text(
                  widget.job.city, // Отображаем переданный город
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),

            // Тип работы
            Row(
              children: [
                Icon(Icons.work_outline, color: Colors.grey),
                SizedBox(width: 8.0),
                Text(
                  widget.job.jobType,
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Divider(height: 24.0, color: Colors.grey[400]),

            // Описание вакансии
            Text(
              'Описание',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              widget.job.description,
              style: TextStyle(fontSize: 24.0, color: Colors.black87),
            ),
            Divider(height: 24.0, color: Colors.grey[400]),

            // Сумма оплаты
            Text(
              'Оплата: ${widget.job.payment} ₽',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 38, 117, 253),
              ),
            ),
            SizedBox(height: 16.0),

            // Количество требуемых людей
            Text(
              'Требуется: ${widget.job.peopleRequired} человек(а)',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),

            // Отображение количества откликов
            Text(
              'Принято: ${widget.job.acceptedPeople}/${widget.job.peopleRequired}',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: widget.job.acceptedPeople >= widget.job.peopleRequired
                    ? Colors.red
                    : Colors.green,
              ),
            ),

            // Требования
            Text(
              'Требования',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              widget.job.requirements,
              style: TextStyle(fontSize: 24.0, color: Colors.black87),
            ),
            Spacer(),

            // Виджет работодателя (имя и рейтинг) в рамке
            employerId.isNotEmpty
                ? Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Переход на профиль работодателя
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileWidget(
                              userId: employerId, // Передаем ID работодателя
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Работодатель: $employerName',
                            style: TextStyle(fontSize: 18.0),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber),
                              SizedBox(width: 4.0),
                              Text(
                                employerRating.toStringAsFixed(1),
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : CircularProgressIndicator(), // Показать загрузку, если данные еще загружаются
            SizedBox(height: 16.0),

            // Кнопка "Откликнуться" или "Вы уже откликнулись"
            hasResponded ||
                    widget.job.acceptedPeople >= widget.job.peopleRequired
                ? ElevatedButton(
                    onPressed: null, // Не кликабельная кнопка
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 75),
                      backgroundColor: Colors.grey, // Серая кнопка
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      widget.job.acceptedPeople >= widget.job.peopleRequired
                          ? 'Места заполнены'
                          : 'Вы уже откликнулись',
                      style: TextStyle(
                        fontSize: 25,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      try {
                        // Отклик на вакансию
                        await userService.respondToJob(
                            widget.job.id, widget.job.title);

                        // Уведомляем об успешном отклике
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Вы откликнулись на эту вакансию'),
                          ),
                        );

                        // Обновляем состояние, чтобы показать, что пользователь откликнулся
                        setState(() {
                          hasResponded = true;
                        });
                      } catch (e) {
                        // Обрабатываем ошибку
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка при отклике: $e'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Откликнуться',
                      style: TextStyle(
                        fontSize: 25,
                        color: const Color.fromARGB(255, 24, 23, 23),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 75),
                      backgroundColor: Colors.blueAccent,
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
