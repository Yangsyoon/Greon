
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/cart/cart_item.dart';
import '../../repositories/cart_repository.dart';

class DeleteCartItemUseCase implements UseCase<void, CartItem> {
  final CartRepository repository;

  DeleteCartItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CartItem cartItem) {
    final id = cartItem.id;
    if (id == null) {
      return Future.value(Left(ExceptionFailure()));
    }
    return repository.deleteCartItem(id);
  }

}


