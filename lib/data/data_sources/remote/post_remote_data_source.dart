import 'package:cloud_firestore/cloud_firestore.dart';

// PostModel이 정의된 파일의 실제 경로로 수정해야 합니다.
import '../../models/model/PostModel.dart';

// --- 인터페이스 (계약) ---
// PostRemoteDataSource가 어떤 기능을 가져야 하는지 정의합니다.
abstract class PostRemoteDataSource {
  Future<List<PostModel>> getPosts();
// 여기에 게시물 추가, 수정, 삭제 등의 함수를 추가할 수 있습니다.
}

// --- 구현 클래스 ---
// 위에서 정의한 기능을 실제로 수행하는 클래스입니다.
class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final FirebaseFirestore firestore;

  // 생성 시 FirebaseFirestore 인스턴스를 주입받습니다.
  PostRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<PostModel>> getPosts() async {
    try {
      final querySnapshot = await firestore.collection('posts').get();

      // Firestore 문서를 PostModel 객체 리스트로 변환하여 반환합니다.
      return querySnapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();
    } catch (e) {
      // 실제 앱에서는 더 정교한 에러 처리가 필요합니다.
      print('PostRemoteDataSource에서 오류 발생: $e');
      throw Exception('게시물을 불러오는 데 실패했습니다.');
    }
  }
}