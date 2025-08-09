import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/domain/entities/order/order_item.dart';
import 'package:greon/presentation/widgets/auth_check_modalsheet.dart';
import 'package:greon/presentation/widgets/payment_details_row.dart';
import 'package:greon/presentation/widgets/transparent_button.dart';
import '../../di/di.dart' as di;

import '../../application/cart_bloc/cart_bloc.dart';
import '../../application/delivery_info_fetch_cubit/delivery_info_fetch_cubit.dart';
import '../../application/order_add_cubit/order_add_cubit.dart';
import '../../configs/configs.dart';
import '../../core/constant/colors.dart';
import '../../core/router/app_router.dart';
import '../../domain/entities/order/order_details.dart';
import 'dashed_separator.dart';
import 'package:intl/intl.dart';


class PaymentDetails extends StatefulWidget {
  const PaymentDetails(
      {super.key,
      required this.buttonText,
      required this.isFromCheckout,
      required this.isLogged});

  final String buttonText;
  final bool isFromCheckout;
  final bool isLogged;

  @override
  State<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.cart.isEmpty) {
          return const SizedBox.shrink();
        }

        final int totalProductPrice = state.cart.fold(
            0, (total, item) => total + item.price * item.quantity);
        final int productDiscount = 500; // 할인 예시
        final int couponDiscount = 2000; // 쿠폰 할인 예시
        final int deliveryFee = 4000;
        final int totalPayment =
            totalProductPrice - productDiscount - couponDiscount + deliveryFee;
        final formattedTotalPayment = NumberFormat('#,###', 'ko_KR').format(totalPayment);


        // 공통 row 스타일
        Widget buildDetailsRow({
          required String title,
          required Widget valueWidget,
        }) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppText.b2?.copyWith(fontSize: 14)),
                valueWidget, // 오른쪽 내용 (텍스트 또는 텍스트+버튼)
              ],
            ),
          );
        }

        Widget paymentWidget = Container(
          color: Colors.white,
          padding: Space.all(0.66, 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "예상 결제 금액",
                style: AppText.h3b?.copyWith(fontSize: AppText.h3b!.fontSize! ,color: Colors.black),
              ),
              Space.yf(0.66),
              buildDetailsRow(
                title: "총 상품 금액",
                valueWidget: Text(
                  '₩${NumberFormat('#,###').format(totalProductPrice)}',
                  style: AppText.b2?.copyWith(fontSize: 14),
                ),
              ),

              buildDetailsRow(
                title: "상품 할인",
                valueWidget: Text(
                  '- ₩${NumberFormat('#,###').format(productDiscount)}',
                  style: AppText.b2?.copyWith(fontSize: 14),
                ),
              ),

              buildDetailsRow(
                title: "쿠폰 할인",
                valueWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () {
                        //showCouponSelectionModal(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "쿠폰 선택",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '- ₩${NumberFormat('#,###').format(couponDiscount)}',
                      style: AppText.b2?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),

              buildDetailsRow(
                title: "배송비",
                valueWidget: Text(
                  '₩${NumberFormat('#,###').format(deliveryFee)}',
                  style: AppText.b2?.copyWith(fontSize: 14),
                ),
              ),

              // PaymentDetailsRow("총 결제 금액", '$totalPayment', AppText.h3b?.copyWith(
              //   fontSize: AppText.h3b!.fontSize! * 4 / 5,
              // ),),
              const DashedSeparator(),
              Space.yf(.5),
              Center(
              child:SizedBox(
                width: MediaQuery.of(context).size.width * 2 / 3,
                child: ElevatedButton(
                  onPressed: () {
                    widget.isFromCheckout
                        ? null
                        : widget.isLogged
                        ? Navigator.pushNamed(context, AppRouter.checkout,
                        arguments: state.cart)
                        : showAuthCheckModalSheet(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 둥근 모서리
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14), // 높이 유지
                    backgroundColor: Colors.black, // 필요 시 색상 지정
                  ),
                  child: Text(
                    '₩$formattedTotalPayment ${widget.buttonText}', // ₩23,000 주문하기
                    style: AppText.h3b?.copyWith(
                      fontSize: AppText.h3b!.fontSize! * 4 / 5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ),
              widget.isFromCheckout
                  ? BlocListener<OrderAddCubit, OrderAddState>(
                listener: (context, orderState) {
                  if (orderState is OrderAddLoading) {
                    setState(() {
                      isLoading = true;
                    });
                  } else if (orderState is OrderAddSuccess) {
                    Navigator.of(context)
                        .pushNamed(AppRouter.ordersuccess);
                  } else if (orderState is OrderAddFail) {
                    Navigator.of(context).pushNamed(AppRouter.orderfailure);
                  }
                },
                child: Padding(
                  padding: Space.vf(1.0),
                  child: transparentButton(
                      context: context,
                      onTap: () {
                        if (context
                            .read<DeliveryInfoFetchCubit>()
                            .state
                            .selectedDeliveryInformation ==
                            null) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  child: Container(
                                    height: AppDimensions.normalize(23),
                                    child: Center(
                                      child: Text(
                                        "Your Delivery Info is Empty.\nPlease Add Or Select An Adress.",
                                        style: AppText.b1b?.copyWith(
                                          fontSize: AppText.b1b!.fontSize! * 2 / 3,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              });
                        } else {
                          context.read<OrderAddCubit>().addOrder(
                              OrderDetails(
                                  id: '',
                                  orderItems: state.cart
                                      .map((item) => OrderItem(
                                    id: '',
                                    product: item.product,
                                    price: item.price,
                                    quantity: item.quantity,
                                  ))
                                      .toList(),
                                  deliveryInfo: context
                                      .read<DeliveryInfoFetchCubit>()
                                      .state
                                      .selectedDeliveryInformation!,
                                  discount: 0));
                        }
                      },
                      buttonText: isLoading ? "Wait..." : "Pay On Delivery"),
                ),
              )
                  : const SizedBox.shrink()
            ],
          ),
        );

        return widget.isFromCheckout
            ? paymentWidget
            : Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: paymentWidget,
        );
      },
    );
  }

}
