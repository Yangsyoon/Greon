import '../../entities/schedule/schedule.dart';
import '../../repositories/schedule_repository.dart';

class AddSchedule {
  final ScheduleRepository repository;

  AddSchedule(this.repository);

  Future<void> call(String userId, Schedule schedule) {
    return repository.addSchedule(userId, schedule);
  }
}
