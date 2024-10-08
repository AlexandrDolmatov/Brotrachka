import 'package:flutter/material.dart';
import '/services/job_service.dart';
import '/models/job_model.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Импортируем DropdownSearch
import 'dart:convert';
import 'package:flutter/services.dart';

class JobCreateScreen extends StatefulWidget {
  final Job? job; // Принимаем объект вакансии, если это редактирование

  JobCreateScreen({this.job});

  @override
  _JobCreateScreenState createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends State<JobCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Переменные для хранения данных формы
  String _title = '';
  String _description = '';
  String _jobType = 'Разгрузка/Погрузка';
  int _payment = 0;
  String _requirements = '';
  int _peopleRequired = 1;
  String _city = ''; // Новый параметр для города
  List<String> _cities = []; // Список городов

  // Инициализация экземпляра JobService
  final JobService _jobService = JobService();

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      // Если вакансия передана, заполняем поля данными
      _title = widget.job!.title;
      _description = widget.job!.description;
      _jobType = widget.job!.jobType;
      _payment = widget.job!.payment;
      _requirements = widget.job!.requirements;
      _peopleRequired = widget.job!.peopleRequired;
      _city = widget.job!.city; // Добавляем город из вакансии
    }

    // Загружаем список городов
    _loadCities();
  }

  Future<void> _loadCities() async {
    String jsonString = await rootBundle.loadString('assets/json/cities.json');
    final List<dynamic> cityList = json.decode(jsonString);
    setState(() {
      _cities = cityList
          .where((city) => city['city'] != null)
          .map((city) => city['city'] as String)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.job != null; // Проверяем, редактирование ли это
    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEditing ? 'Редактирование вакансии' : 'Создание вакансии'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название вакансии
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              SizedBox(height: 16.0),

              // Описание работы
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите описание';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              SizedBox(height: 16.0),

              // Тип работы
              DropdownButtonFormField<String>(
                value: _jobType,
                decoration: InputDecoration(
                  labelText: 'Тип работы',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Разгрузка/Погрузка',
                  'Монтаж/Демонтаж',
                  'Официант',
                  'Курьер',
                  "Промоутер",
                  "Охранник/Сторож",
                  "Уборщик"
                ]
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _jobType = value!;
                  });
                },
              ),
              SizedBox(height: 16.0),

              // Сумма оплаты
              TextFormField(
                initialValue: _payment.toString(),
                decoration: InputDecoration(
                  labelText: 'Сумма оплаты',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите сумму оплаты';
                  }
                  return null;
                },
                onSaved: (value) {
                  _payment = int.tryParse(value!) ?? 0;
                },
              ),
              SizedBox(height: 16.0),

              // Требования к рабочему
              TextFormField(
                initialValue: _requirements,
                decoration: InputDecoration(
                  labelText: 'Требования',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите требования';
                  }
                  return null;
                },
                onSaved: (value) {
                  _requirements = value!;
                },
              ),
              SizedBox(height: 16.0),

              // Количество требуемых людей
              TextFormField(
                initialValue: _peopleRequired.toString(),
                decoration: InputDecoration(
                  labelText: 'Количество людей',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите количество людей';
                  }
                  if (int.tryParse(value) == null ||
                      int.tryParse(value)! <= 0) {
                    return 'Введите корректное количество';
                  }
                  return null;
                },
                onSaved: (value) {
                  _peopleRequired = int.tryParse(value!) ?? 1;
                },
              ),
              SizedBox(height: 16.0),

              // Город (с использованием DropdownSearch)
              DropdownSearch<String>(
                items: (String filter, LoadProps? loadProps) async {
                  return _cities;
                },
                selectedItem: _city,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      labelText: "Поиск города",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Выберите город",
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _city = newValue ?? '';
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Пожалуйста, выберите город'
                    : null,
              ),
              SizedBox(height: 24.0),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      // Если редактируем, обновляем вакансию
                      if (isEditing) {
                        Job updatedJob = Job(
                          id: widget
                              .job!.id, // Используем id существующей вакансии
                          title: _title,
                          description: _description,
                          jobType: _jobType,
                          payment: _payment,
                          requirements: _requirements,
                          peopleRequired: _peopleRequired,
                          city: _city, // Обновляем город
                          postedAt:
                              widget.job!.postedAt, // Оставляем старую дату
                          acceptedPeople: widget.job!.acceptedPeople,
                        );

                        try {
                          await _jobService.updateJob(updatedJob);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Вакансия успешно обновлена!')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Ошибка при обновлении вакансии: $e')),
                          );
                        }
                      } else {
                        // Если не редактируем, то создаем новую вакансию
                        Job newJob = Job(
                          id: '',
                          title: _title,
                          description: _description,
                          jobType: _jobType,
                          payment: _payment,
                          requirements: _requirements,
                          peopleRequired: _peopleRequired,
                          city: _city, // Добавляем город
                          postedAt: DateTime.now(),
                          acceptedPeople: 0,
                        );

                        try {
                          await _jobService.createJob(
                            newJob,
                            jobType: _jobType,
                            title: _title,
                            description: _description,
                            payment: _payment,
                            requirements: _requirements,
                            peopleRequired: _peopleRequired,
                            city: _city,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Вакансия успешно создана!')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Ошибка при создании вакансии: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: Text(isEditing ? 'Сохранить' : 'Создать',
                      style: TextStyle(color: Colors.black, fontSize: 20.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: TextStyle(fontSize: 18.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
