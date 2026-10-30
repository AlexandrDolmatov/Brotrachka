import 'package:brotrachka/models/job_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final postedAt = DateTime.utc(2024, 10, 8, 12);

  test('reads the createdAt timestamp written by JobService', () {
    final job = Job.fromMap({
      'id': 'listing-1',
      'title': 'Event assistant',
      'createdAt': Timestamp.fromDate(postedAt),
      'peopleRequired': 3,
      'acceptedPeople': 1,
    });
    expect(job.postedAt.isAtSameMomentAs(postedAt), isTrue);
    expect(job.id, 'listing-1');
    expect(job.peopleRequired - job.acceptedPeople, 2);
  });

  test('reads legacy postedAt documents', () {
    final job = Job.fromMap({'postedAt': Timestamp.fromDate(postedAt)});
    expect(job.postedAt.isAtSameMomentAs(postedAt), isTrue);
  });

  test('preserves a date when converting a local model to a map and back', () {
    final job = Job.fromMap({'postedAt': postedAt, 'title': 'Local listing'});
    final restored = Job.fromMap(job.toMap());
    expect(restored.postedAt, postedAt);
    expect(restored.title, job.title);
  });
}
