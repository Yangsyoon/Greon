import '../entities/schedule/schedule.dart';

abstract class ScheduleRepository {
  Future<void> addSchedule(String userId, Schedule schedule);
  Future<void> deleteSchedule(String userId, Schedule schedule);
}
