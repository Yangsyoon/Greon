import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/cart/cart_item.dart';
import '../../../domain/usecases/cart/add_cart_item_usecase.dart';
import '../../../domain/usecases/cart/clear_cart_usecase.dart';
import '../../../domain/usecases/cart/get_cached_cart_usecase.dart';
import '../../../domain/usecases/cart/sync_cart_usecase.dart';
import '../../domain/repositories/cart_repository.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository; // ← 추가
  final GetCachedCartUseCase _getCachedCartUseCase;
  final AddCartUseCase _addCartUseCase;
  final SyncCartUseCase _syncCartUseCase;
  final ClearCartUseCase _clearCartUseCase;

  CartBloc(
    this._getCachedCartUseCase,
    this._addCartUseCase,
    this._syncCartUseCase,
    this._clearCartUseCase,
      this._cartRepository,
  ) : super(const CartInitial(cart: [])) {
    on<GetCart>(_onGetCart);
    on<AddProduct>(_onAddToCart);
    on<ClearCart>(_onClearCart);
  }

  void _onGetCart(GetCart event, Emitter<CartState> emit) async {
    try {
      emit(CartLoading(cart: state.cart));
      final result = await _cartRepository.getCartFromFirestore();
      result.fold(
            (failure) => emit(CartError(cart: state.cart, failure: failure)),
            (cart) => emit(CartLoaded(cart: cart)),
      );
    } catch (e) {
      emit(CartError(failure: ExceptionFailure(), cart: state.cart));
    }
  }

  void _onAddToCart(AddProduct event, Emitter<CartState> emit) async {
    print('AddProduct event received with !!!!!!');
    try {
      emit(CartLoading(cart: state.cart));
      final result = await _addCartUseCase(event.cartItem);
      result.fold(
            (failure) {
          print('실패: $failure');
          emit(CartError(cart: state.cart, failure: failure));
        },
            (savedCartItem) {
          final updatedCart = List<CartItem>.from(state.cart)..add(savedCartItem);
          emit(CartLoaded(cart: updatedCart));
        },
      );
    } catch (e) {
      emit(CartError(cart: state.cart, failure: ExceptionFailure()));
    }
  }




  void _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      emit(const CartLoading(cart: []));
      emit(const CartLoaded(cart: []));
      await _clearCartUseCase(NoParams());
    } catch (e) {
      emit(CartError(cart: const [], failure: ExceptionFailure()));
    }
  }
}
