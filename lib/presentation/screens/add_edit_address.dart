import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kpostal/kpostal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditAddressPage extends StatefulWidget {
  const AddEditAddressPage({super.key});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _phone3Controller = TextEditingController();

  final FocusNode _recipientFocus = FocusNode();
  final FocusNode _detailFocus = FocusNode();
  final FocusNode _phone1Focus = FocusNode();
  final FocusNode _phone2Focus = FocusNode();
  final FocusNode _phone3Focus = FocusNode();

  String? _postCode;

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: const UnderlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  void _openKpostal() async {
    Kpostal result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KpostalView()),
    );

    if (!mounted) return;

    setState(() {
      _postCode = result.postCode;
      _postCodeController.text = result.postCode;
      _addressController.text = result.address;
    });
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required int maxLength,
  }) {
    return SizedBox(
      width: maxLength == 3 ? 50 : 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        maxLength: maxLength,
        decoration: const InputDecoration(
          counterText: "", // 0/3 표시 제거
          isDense: true, // 패딩 최소화
          contentPadding: EdgeInsets.symmetric(vertical: 8), // 높이 조절
          border: UnderlineInputBorder(),
        ),
        onChanged: (value) {
          if (value.length == maxLength && nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
      )
    );
  }

  Future<void> _saveAddress() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인이 필요합니다.")),
        );
        return;
      }

      final addressData = {
        'recipient': _recipientController.text,
        'postCode': _postCodeController.text,
        'address': _addressController.text,
        'detail': _detailController.text,
        'phone': '${_phone1Controller.text}-${_phone2Controller.text}-${_phone3Controller.text}',
        'fullAddress': '${_addressController.text} ${_detailController.text}',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .add(addressData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("주소가 저장되었습니다.")),
      );

      Navigator.pop(context, addressData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 실패: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("배송지 추가")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 받는 분
            TextField(
              controller: _recipientController,
              focusNode: _recipientFocus,
              decoration: _inputDecoration("받는 분"),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _detailFocus.requestFocus(),
            ),
            const SizedBox(height: 16),

            // 우편번호 + 검색 버튼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postCodeController,
                    readOnly: true,
                    decoration: _inputDecoration("우편번호"),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _openKpostal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  child: const Text("우편번호 검색"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 주소
            TextField(
              controller: _addressController,
              readOnly: true,
              decoration: _inputDecoration("주소"),
            ),
            const SizedBox(height: 16),

            // 상세주소
            TextField(
              controller: _detailController,
              focusNode: _detailFocus,
              decoration: _inputDecoration("상세주소"),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _phone1Focus.requestFocus(),
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "연락처",
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4), // 글자와 입력란 간격
                Row(
                  children: [
                    _buildPhoneField(
                      controller: _phone1Controller,
                      focusNode: _phone1Focus,
                      nextFocus: _phone2Focus,
                      maxLength: 3,
                    ),
                    const SizedBox(width: 4),
                    const Text('-'),
                    const SizedBox(width: 4),
                    _buildPhoneField(
                      controller: _phone2Controller,
                      focusNode: _phone2Focus,
                      nextFocus: _phone3Focus,
                      maxLength: 4,
                    ),
                    const SizedBox(width: 4),
                    const Text('-'),
                    const SizedBox(width: 4),
                    _buildPhoneField(
                      controller: _phone3Controller,
                      focusNode: _phone3Focus,
                      maxLength: 4,
                    ),
                  ],
                ),
              ],
            ),


            const SizedBox(height: 32),

            Center(
              child: ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text(
                  "배송지 입력하기",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}