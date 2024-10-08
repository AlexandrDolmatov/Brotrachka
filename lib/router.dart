import 'package:brotrachka/screens/home/main_screen.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/category_selection_screen.dart';
import 'screens/jobs/job_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/review/reviews_screen.dart';
import 'models/job_model.dart';
import 'screens/jobs/job_detail_screen.dart';
import 'screens/jobs/job_create_screen.dart';
import 'screens/profile/my_jobs_screen.dart';
import 'screens/profile/responses_screen.dart';
import 'screens/profile/friends_list_screen.dart';
import 'screens/profile/my_role.dart';
import 'screens/profile/my_responses.dart';
import '/screens/profile/user_jobs_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => MainScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/myRole':
        return MaterialPageRoute(builder: (_) => MyRoleScreen());
      case '/myApplications':
        return MaterialPageRoute(builder: (_) => MyResponsesScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case '/categorySelection':
        return MaterialPageRoute(builder: (_) => CategorySelectionScreen());
      case '/jobList':
        return MaterialPageRoute(builder: (_) => JobListScreen());
      case '/jobDetail':
        final job = settings.arguments as Job?;
        if (job != null) {
          return MaterialPageRoute(
            builder: (_) => JobDetailScreen(job: job),
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body:
                  Center(child: Text('Ошибка: данные о вакансии отсутствуют')),
            ),
          );
        }
      case '/jobCreate':
        return MaterialPageRoute(builder: (_) => JobCreateScreen());
      case '/profile':
        final args = settings.arguments as Map<String, dynamic>;
        final bool isWorker = args['isWorker'] ?? true;
        final String displayName = args['displayName'] ?? 'Имя Пользователя';
        final double rating = (args['rating'] as num).toDouble();
        final Job? job = args['job'];

        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            isWorker: isWorker,
            displayName: displayName,
            rating: rating,
            job: job,
          ),
        );
      case '/editProfile':
        return MaterialPageRoute(builder: (_) => EditProfileScreen());
      case '/friendsList':
        return MaterialPageRoute(builder: (_) => FriendsScreen());
      case '/myJobs':
        final userId = settings.arguments as String?;
        if (userId == null || userId.isEmpty) {
          // Возвращаем ошибку или навигацию назад, если userId не был передан или является пустым
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Ошибка: отсутствует идентификатор пользователя'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) => MyJobsScreen(userId: userId),
        );
      case '/reviews':
        final userId = settings.arguments as String?;
        if (userId == null || userId.isEmpty) {
          // Возвращаем ошибку или навигацию назад, если userId не был передан или является пустым
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Ошибка: отсутствует идентификатор пользователя'),
              ),
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => ReviewsScreen(userId: userId));
      case '/userJobs':
        final userId = settings.arguments as String?;
        if (userId == null || userId.isEmpty) {
          // Возвращаем ошибку или навигацию назад, если userId не был передан или является пустым
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Ошибка: отсутствует идентификатор пользователя'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => UserJobsScreen(userId: userId),
        );
      case '/responses':
        final job = settings.arguments as Job?;
        if (job != null) {
          return MaterialPageRoute(
            builder: (_) => ResponsesScreen(
                jobId: job.id, jobTitle: job.title), // Передача jobId
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body:
                  Center(child: Text('Ошибка: данные об откликах отсутствуют')),
            ),
          );
        }
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
