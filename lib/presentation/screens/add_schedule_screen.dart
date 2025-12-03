import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/entities/schedule/schedule.dart';
import '../../domain/usecases/schedule/add_schedule.dart';

class AddScheduleScreen extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const AddScheduleScreen({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memoController = TextEditingController();
  final _plantNameController = TextEditingController();

  String? _selectedType;

  final List<String> _scheduleTypes = ['물주기', '양분주기', '분갈이', '햇빛 관리', '기타'];

  @override
  void dispose() {
    _plantNameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    // Firestore가 기대하는 구조대로 직접 저장
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('schedules')
        .add({
      'plant_id': 'plant001', // 현재 임시
      'plant_name': _plantNameController.text,
      'date': Timestamp.fromDate(
        DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          8,
          0,
          0,
        ),
      ),
      'type': _selectedType!,
      'memo': _memoController.text,
      'auto_generated': false,
    });

    Navigator.pop(context, true);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일정 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _plantNameController,
                decoration: const InputDecoration(
                  labelText: '식물 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? '식물 이름을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "일정 종류",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _scheduleTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '일정 종류를 선택하세요',
                ),
                validator: (value) =>
                value == null ? '일정 종류를 선택하세요' : null,
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "메모",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _memoController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '메모를 입력하세요',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSchedule,
                  child: const Text('저장', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
