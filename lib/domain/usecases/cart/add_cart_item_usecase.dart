import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/cart/cart_item.dart';
import '../../repositories/cart_repository.dart';

class AddCartUseCase implements UseCase<CartItem, CartItem> {
  final CartRepository repository;
  AddCartUseCase(this.repository);

  @override
  Future<Either<Failure, CartItem>> call(CartItem params) async{
    print("addcartusecase call 호출됨");
    return await repository.addToCart(params); // Right로 한 번 더 감싸지 마세요!
  }
}
