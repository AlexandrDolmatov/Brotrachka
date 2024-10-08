import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class JobFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic> filters) onApplyFilters;
  final Map<String, dynamic> initialFilters;

  JobFilterScreen({required this.onApplyFilters, required this.initialFilters});

  @override
  _JobFilterScreenState createState() => _JobFilterScreenState();
}

class _JobFilterScreenState extends State<JobFilterScreen> {
  late String selectedCity;
  late String selectedJobType;
  late int minPayment;
  late int maxPayment;
  late TextEditingController minPaymentController;
  late TextEditingController maxPaymentController;

  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    selectedCity =
        widget.initialFilters['city'] ?? ''; // Добавляем фильтр города
    selectedJobType = widget.initialFilters['jobType'] ?? 'Все';
    minPayment = widget.initialFilters['minPayment'] ?? 0;
    maxPayment = widget.initialFilters['maxPayment'] ?? 10000;

    minPaymentController = TextEditingController(text: minPayment.toString());
    maxPaymentController = TextEditingController(text: maxPayment.toString());

    // Загружаем список городов
    _loadCities();
  }

  Future<void> _loadCities() async {
    String jsonString = await rootBundle.loadString('assets/json/cities.json');
    final List<dynamic> cityList = json.decode(jsonString);
    if (mounted) {
      setState(() {
        _cities = cityList
            .where((city) => city['city'] != null)
            .map((city) => city['city'] as String)
            .toList();
      });
    }
  }

  bool _filtersChanged() {
    // Логика, чтобы проверить, были ли изменены фильтры
    return selectedCity != widget.initialFilters['city'] ||
        selectedJobType != widget.initialFilters['jobType'] ||
        minPayment != widget.initialFilters['minPayment'] ||
        maxPayment != widget.initialFilters['maxPayment'];
  }

  @override
  Widget build(BuildContext context) {
    if (_cities.isEmpty) {
      return Center(
          child:
              CircularProgressIndicator()); // Показываем индикатор, пока города не загружены
    }

    return Container(
      padding: EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.5, // Половина экрана
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Выбор города с поиском
          Text('Город:', style: TextStyle(fontSize: 18)),
          DropdownSearch<String>(
            items: (String filter, LoadProps? loadProps) {
              return _cities; // Возвращаем список городов из переменной _cities
            },
            selectedItem: selectedCity,
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
                selectedCity = newValue ?? '';
              });
            },
            validator: (value) => value == null || value.isEmpty
                ? 'Пожалуйста, выберите город'
                : null,
          ),
          SizedBox(height: 16.0),

          // Тип работы
          Text('Тип работы:', style: TextStyle(fontSize: 18)),
          DropdownButton<String>(
            value: selectedJobType,
            items: [
              'Все',
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
                selectedJobType = value!;
              });
            },
          ),
          SizedBox(height: 16.0),

          // Диапазон оплаты
          Text('Сумма оплаты:', style: TextStyle(fontSize: 18)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minPaymentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Минимум',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      minPayment = int.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: TextField(
                  controller: maxPaymentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Максимум',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      maxPayment = int.tryParse(value) ?? 10000;
                    });
                  },
                ),
              ),
            ],
          ),
          Spacer(),

          // Кнопка применения фильтров
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_filtersChanged()) {
                  widget.onApplyFilters({
                    'city': selectedCity,
                    'jobType': selectedJobType,
                    'minPayment': minPayment,
                    'maxPayment': maxPayment,
                  });
                  Navigator.pop(context);
                } else {
                  // Если фильтры не изменились, просто закрываем экран
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                backgroundColor: Colors.blueAccent,
              ),
              child: Text(
                'Применить фильтр',
                style: TextStyle(fontSize: 18.0, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
