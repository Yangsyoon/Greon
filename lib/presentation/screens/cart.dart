import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/presentation/widgets/custom_appbar.dart';
import 'package:greon/presentation/widgets/empty_cart_container.dart';
import 'package:greon/presentation/widgets/error_container.dart';
import 'package:greon/presentation/widgets/payment_details.dart';

import '../../../../domain/entities/cart/cart_item.dart';
import '../../application/cart_bloc/cart_bloc.dart';
import '../../application/user_bloc/user_bloc.dart';
import '../widgets/cart_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> selectedCartItems = [];

  @override
  void initState() {
    super.initState();
    // 화면이 열릴 때 cart를 Firestore에서 불러오는 이벤트 실행
    context.read<CartBloc>().add(GetCart());
  }

  bool get isAllSelected =>
      context.read<CartBloc>().state is CartLoaded &&
      selectedCartItems.length ==
          (context.read<CartBloc>().state as CartLoaded).cart.length;

  void toggleSelectAll(bool? selected) {
    if (selected == true) {
      final cartItems = (context.read<CartBloc>().state as CartLoaded).cart;
      setState(() {
        selectedCartItems = List.from(cartItems);
      });
    } else {
      setState(() {
        selectedCartItems.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white, // 전체 흰 배경
        appBar: CustomAppBar("장바구니", context, automaticallyImplyLeading: true),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // ← 이거 추가!
                children: [
                  const SizedBox(height: 8),
                  // 상단: 전체선택 + 선택삭제
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: isAllSelected,
                            onChanged: toggleSelectAll,
                            activeColor: Colors.black,
                          ),
                          const Text(
                            "전체선택",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: selectedCartItems.isEmpty
                            ? null
                            : () async {
                                final bloc = context.read<CartBloc>();

                                // ✅ 하나씩 await 하면서 삭제
                                for (final item in selectedCartItems) {
                                  bloc.add(DeleteCartItem(item));
                                  // ⏱ 살짝 대기: Bloc이 상태 처리할 시간 확보 (선택 사항)
                                  await Future.delayed(
                                      const Duration(milliseconds: 50));
                                }

                                // ✅ 리스트 클리어 및 강제 새로고침
                                setState(() {
                                  selectedCartItems.clear();
                                });
                                bloc.add(GetCart());
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: selectedCartItems.isEmpty
                              ? Colors.grey
                              : Colors.red,
                        ),
                        child: const Text(
                          "선택삭제",
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // 여기서 바로 텍스트만
                  const SizedBox(height: 8),
                  const Text(
                    "배송 상품",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 장바구니 아이템 리스트
// 장바구니 아이템 리스트
                  Expanded(
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, state) {
                        if (state is CartError) {
                          return errorContainer(context, true);
                        }
                        if (state is CartLoaded && state.cart.isEmpty) {
                          return emptyCartContainer(context);
                        }
                        if (state is CartLoading) {
                          return ListView.builder(
                            itemCount: 5,
                            padding: EdgeInsets.only(
                                bottom: AppDimensions.normalize(127)),
                            itemBuilder: (context, index) =>
                                const CartItemCard(), // 로딩 중
                          );
                        }
                        if (state is CartLoaded) {
                          return ListView.builder(
                            itemCount: state.cart.length,
                            padding: EdgeInsets.only(
                                bottom: AppDimensions.normalize(127)),
                            itemBuilder: (context, index) {
                              final item = state.cart[index];
                              return CartItemCard(
                                cartItem: item,
                                isSelected: selectedCartItems.contains(item),
                                onLongClick: () {
                                  setState(() {
                                    if (selectedCartItems.contains(item)) {
                                      selectedCartItems.remove(item);
                                    } else {
                                      selectedCartItems.add(item);
                                    }
                                  });
                                },
                                onDelete: () {
                                  context
                                      .read<CartBloc>()
                                      .add(DeleteCartItem(item));
                                },
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
            // 결제/로그인 정보
            BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                return PaymentDetails(
                  buttonText: "주문하기",
                  isFromCheckout: false,
                  isLogged: state is UserLogged,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
