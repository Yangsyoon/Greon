// terms_viewer_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

class TermsViewerScreen extends StatelessWidget {
  final String title;
  final String markdownUrl;

  const TermsViewerScreen({
    super.key,
    required this.title,
    required this.markdownUrl,
  });

  // URL에서 Markdown 텍스트를 가져오는 함수
  Future<String> _fetchMarkdownContent() async {
    try {
      final response = await http.get(Uri.parse(markdownUrl));
      if (response.statusCode == 200) {
        // UTF-8로 디코딩하여 한글 깨짐 방지
        return utf8.decode(response.bodyBytes);
      } else {
        return '약관을 불러오는 데 실패했습니다. (상태 코드: ${response.statusCode})';
      }
    } catch (e) {
      return '약관을 불러오는 중 오류가 발생했습니다: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<String>(
        future: _fetchMarkdownContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return Markdown(
              data: snapshot.data!,
              padding: const EdgeInsets.all(16.0),
            );
          } else {
            return const Center(child: Text('약관 내용이 없습니다.'));
          }
        },
      ),
    );
  }
}