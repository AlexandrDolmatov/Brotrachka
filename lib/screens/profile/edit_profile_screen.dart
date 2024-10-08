import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Для загрузки изображений
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Для выпадающего списка с поиском
import 'package:logger/logger.dart';

final logger = Logger();

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String? _selectedCity;
  String? _initialName;
  String? _initialCity;
  String? _profileImageUrl; // URL изображения профиля
  List<String> _cities = [];

  bool _showOldPassword = false;
  bool _showNewPassword = false;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    _loadCities();
  }

  void _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _initialName = user.displayName;

      // Загружаем данные из Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Проверяем, есть ли данные в документе
      if (userDoc.exists) {
        setState(() {
          _selectedCity = userDoc['city'] ?? '';
          _initialCity = userDoc['city'] ?? '';
          _profileImageUrl =
              userDoc['profileImageUrl'] ?? ''; // Загружаем URL изображения
        });
      }
    }
  }

  Future<void> _updateProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // Получаем текущего пользователя
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          // 1. Загружаем изображение в Firebase Storage
          String downloadUrl =
              await _uploadImageToFirebase(user.uid, _profileImage!);

          // 2. Сохраняем URL изображения в Firestore
          await _saveImageUrlToFirestore(user.uid, downloadUrl);

          print('Изображение успешно обновлено');
        } catch (e) {
          print('Ошибка при загрузке изображения: $e');
        }
      } else {
        print('Пользователь не аутентифицирован');
      }
    }
  }

  Future<String> _uploadImageToFirebase(String userId, File image) async {
    String filePath =
        'users/$userId/profile_images/${DateTime.now().millisecondsSinceEpoch}.png';

    Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _saveImageUrlToFirestore(String userId, String imageUrl) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'profileImageUrl': imageUrl, // Обновляем URL изображения
    });
  }

  Future<void> _updateName(String name) async {
    if (name != _initialName) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(name);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'name': name});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Имя успешно обновлено')),
          );
        }
      } catch (e) {
        print('Ошибка при обновлении имени: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении имени')),
        );
      }
    }
  }

  Future<void> _updateEmail(String email) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.updateEmail(email);
      } catch (e) {
        print('Ошибка при обновлении электронной почты: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении электронной почты')),
        );
      }
    }
  }

  Future<void> _updatePassword(String oldPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пароль успешно обновлен')),
        );
      }
    } catch (e) {
      print('Ошибка при обновлении пароля: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при обновлении пароля')),
      );
    }
  }

  Future<void> _loadCities() async {
    String jsonString = await rootBundle.loadString('assets/json/cities.json');
    final List<dynamic> cityList = json.decode(jsonString);
    setState(() {
      _cities = cityList
          .where((city) =>
              city['city'] !=
              null) // Фильтруем только те, у которых 'city' не null
          .map((city) => city['city'] as String)
          .toList();
    });
    //logger.d(cityList);
  }

  Future<void> _updateCity(String city) async {
    if (city != _initialCity) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'city': city, // Обновляем поле "город" в Firestore
        });
        setState(() {
          _initialCity = city; // Обновляем локальную переменную для проверки
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Город успешно обновлен')),
        );
      }
    }
  }

  // Обновленный выпадающий список городов с поиском
  Widget _buildCityDropdown() {
    return DropdownSearch<String>(
      items: (String filter, LoadProps? loadProps) async {
        // Если у вас есть фильтрация, вы можете её обработать здесь
        return _cities; // Возвращаем список городов из переменной _cities
      },
      selectedItem: _selectedCity,
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
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          border: OutlineInputBorder(),
        ),
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCity = newValue;
        });
      },
      validator: (value) => value == null ? 'Пожалуйста, выберите город' : null,
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final String name = _nameController.text;
      final String email = _emailController.text;
      final String oldPassword = _oldPasswordController.text;
      final String newPassword = _newPasswordController.text;

      if (name.isNotEmpty) await _updateName(name);
      if (email.isNotEmpty) await _updateEmail(email);
      if (oldPassword.isNotEmpty && newPassword.isNotEmpty) {
        await _updatePassword(oldPassword, newPassword);
      }
      if (_selectedCity != null && _selectedCity != _initialCity) {
        await _updateCity(_selectedCity!); // Сохраняем город
      }
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, // Полная ширина кнопки
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Сохранить',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактировать профиль'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _updateProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!) as ImageProvider
                            : AssetImage('assets/svg/default_avatar.png'),
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                SizedBox(height: 16),

                // Поле для имени
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    fillColor: Colors.grey[200],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите ваше имя';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Поле для электронной почты
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Электронная почта',
                    fillColor: Colors.grey[200],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите вашу электронную почту';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Выпадающий список городов с поиском
                _buildCityDropdown(),
                SizedBox(height: 16),

                // Текст "Хотите поменять пароль?"
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Хотите поменять пароль?',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),

                // Поле для старого пароля
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: !_showOldPassword,
                  decoration: InputDecoration(
                    labelText: 'Старый пароль',
                    fillColor: Colors.grey[200],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showOldPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _showOldPassword = !_showOldPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (_newPasswordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return 'Пожалуйста, введите ваш старый пароль';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Поле для нового пароля
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Новый пароль',
                    fillColor: Colors.grey[200],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _showNewPassword = !_showNewPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (_oldPasswordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return 'Пожалуйста, введите ваш новый пароль';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),

                // Кнопка "Сохранить"
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
