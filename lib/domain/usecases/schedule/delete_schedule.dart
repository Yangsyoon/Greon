import '../../../data/repositories/schedule_repository_impl.dart';
import '../../entities/schedule/schedule.dart';
import '../../repositories/schedule_repository.dart';

class DeleteSchedule {
  final ScheduleRepository repository;

  DeleteSchedule(this.repository);

  Future<void> call(String userId, Schedule schedule) {
    return repository.deleteSchedule(userId, schedule);
  }
}
