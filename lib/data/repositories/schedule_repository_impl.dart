import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constant/api.dart';
import '../../domain/entities/schedule/schedule.dart';
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final FirebaseFirestore firestore;

  ScheduleRepositoryImpl({required this.firestore});

  @override
  Future<void> addSchedule(String userId, Schedule schedule) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('schedules')
        .add(schedule.toMap());
  }
  Future<void> deleteSchedule(String userId, Schedule schedule) async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('schedules')
        .where('plant_name', isEqualTo: schedule.plantName)
        .where('plant_id', isEqualTo: schedule.plantId)
        .where('date', isEqualTo: Timestamp.fromDate(schedule.date))
        .where('type', isEqualTo: schedule.type)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}

