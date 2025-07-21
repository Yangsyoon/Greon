// share_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:share_plus/share_plus.dart';

part 'share_state.dart';

class ShareCubit extends Cubit<ShareState> {
  ShareCubit() : super(ShareInitialState());

  final String _storeUrl = 'https://m.smartstore.naver.com/greencompanion/products/10972246014';

  Future<void> shareStoreLink() async {
    try {
      emit(ShareLoadingState());

      await Share.share('🌿 우리 스마트스토어에서 구경해보세요!\n$_storeUrl');

      emit(ShareSuccessState());
    } catch (e) {
      emit(ShareErrorState('링크 공유에 실패했습니다: $e'));
    }
  }
}
