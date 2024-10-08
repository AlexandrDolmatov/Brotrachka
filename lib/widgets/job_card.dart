import 'package:flutter/material.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String description;
  final int payment;
  final String jobType;
  final String requirements;
  final DateTime postedAt;
  final VoidCallback onTap; // Функция, вызываемая при нажатии на карточку

  const JobCard({
    required this.title,
    required this.description,
    required this.payment,
    required this.requirements,
    required this.jobType,
    required this.postedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10.0),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4.0),
            Text('₽$payment', style: TextStyle(color: Colors.green)),
            SizedBox(height: 4.0),
            Text('Требования: $requirements'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
