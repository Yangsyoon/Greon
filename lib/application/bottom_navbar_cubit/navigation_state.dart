import 'package:equatable/equatable.dart';

import '../../core/enums/enums.dart';

class NavigationState extends Equatable {
  final NavigationTab tab;
  final String? category; // 카테고리 정보를 추가합니다.
  final int key;

  const NavigationState({required this.tab, this.category, this.key=0});

  @override
  List<Object?> get props => [tab, category, key];
}