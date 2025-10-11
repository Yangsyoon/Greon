import 'dart:io';
import 'dart:math'; // exp 함수 사용을 위해 필요
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class RoomStyleClassifier {
  static const List<String> _classNames = [
    'industrial',
    'modern',
    'natural',
    'vintage'
  ];
  static const int _inputImageSize = 224;
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];

  // 소프트맥스 함수: 모델의 원본 점수(Logit)를 0~1 사이의 확률값으로 변환
  List<double> _softmax(List<double> scores) {
    final exps = scores.map((score) => exp(score)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((exp) => exp / sumExps).toList();
  }

  Future<String?> classifyImage(File imageFile) async {
    try {
      // (이미지 로드 및 1x3x224x224 텐서 생성 로직은 이전과 동일)
      img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (originalImage == null) return '이미지를 로드할 수 없습니다.';
      img.Image resizedImage = img.copyResize(originalImage, width: _inputImageSize, height: _inputImageSize);
      var inputTensor = List.generate(
        1,
            (b) => List.generate(
          _inputImageSize,
              (j) => List.generate(
            _inputImageSize,
                (k) {
              final pixel = resizedImage.getPixel(k, j);
              return [
                ((pixel.r / 255.0) - _mean[0]) / _std[0],
                ((pixel.g / 255.0) - _mean[1]) / _std[1],
                ((pixel.b / 255.0) - _mean[2]) / _std[2],
              ];
            },
          ),
        ),
      );


      final interpreter = await Interpreter.fromAsset('assets/model_float32.tflite');
      var outputTensor = List.filled(1 * _classNames.length, 0.0).reshape([1, _classNames.length]);
      interpreter.run(inputTensor, outputTensor);

      // 모델이 출력한 원본 점수에 소프트맥스를 적용해 확률 리스트로 변환
      var probabilities = _softmax(outputTensor[0] as List<double>);

      // 가장 높은 확률의 인덱스를 찾기
      int predictedClassIndex = -1;
      double maxScore = 0.0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxScore) {
          maxScore = probabilities[i];
          predictedClassIndex = i;
        }
      }
      interpreter.close();

      if (predictedClassIndex != -1) {
        // ✅ STEP 1: 최종 예측 결과 문자열 생성
        String prediction = '예측된 스타일: ${_classNames[predictedClassIndex]}';

        // ✅ STEP 2: 각 스타일별 확률 정보 문자열을 만듦
        // 각 확률에 100을 곱해 퍼센트로 만들고, 소수점 첫째 자리까지 표시
        String probabilityDetails = '';
        for (int i = 0; i < _classNames.length; i++) {
          probabilityDetails += '${_classNames[i]}: ${(probabilities[i] * 100).toStringAsFixed(1)}%\n';
        }

        // ✅ STEP 3: 두 문자열을 합쳐서 최종 결과로 반환
        return '$prediction\n\n--- 스타일별 확률 ---\n$probabilityDetails';

      } else {
        return '분류에 실패했습니다.';
      }
    } catch (e) {
      print('모델 추론 중 오류 발생: $e');
      return '모델 추론 중 오류가 발생했습니다.';
    }
  }
}