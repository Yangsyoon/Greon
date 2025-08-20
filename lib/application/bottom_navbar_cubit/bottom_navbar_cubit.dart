import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/enums/enums.dart';
import 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState(tab: NavigationTab.homeTab));

  // 탭만 업데이트할 경우
  void updateTab(NavigationTab tab) {
    emit(NavigationState(
      tab: tab,
      key: state.key + 1,
    ));
  }

  // 탭과 카테고리를 함께 업데이트할 경우
  void updateTabWithCategory(NavigationTab tab, String category) {
    print(tab);
    print(category);
    emit(NavigationState(
      tab: tab,
      category: category,
      key: state.key + 1,
    ));
  }
}