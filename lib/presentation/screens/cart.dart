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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar("CART", context, automaticallyImplyLeading: true),
      body: Stack(
        children: [
          Padding(
            padding: Space.all(1, 0),
            child: Column(
              children: [
                // BlocBuilder로 cart 상태 감시
                BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    if (state is CartError) {
                      return errorContainer(context, true);
                    }
                    if (state is CartLoaded && state.cart.isEmpty) {
                      return emptyCartContainer(context);
                    }
                    if (state is CartLoading) {
                      return Expanded(
                        child: ListView.builder(
                          itemCount: 5,
                          padding: EdgeInsets.only(
                              bottom: AppDimensions.normalize(127)),
                          itemBuilder: (context, index) =>
                          const CartItemCard(), // 로딩용 카드
                        ),
                      );
                    }
                    if (state is CartLoaded) {
                      return Expanded(
                        child: ListView.builder(
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
                            );
                          },
                        ),
                      );
                    }
                    // 초기상태 등
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          // 결제/로그인 정보
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              return PaymentDetails(
                buttonText: "Proceed To Checkout",
                isFromCheckout: false,
                isLogged: state is UserLogged,
              );
            },
          ),
        ],
      ),
    );
  }
}
