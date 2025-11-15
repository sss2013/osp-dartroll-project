// post_write_page.dart
import 'package:flutter/material.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';

class PostWritePage extends StatefulWidget {
  final String category; // review / friend

  const PostWritePage({Key? key, required this.category}) : super(key: key);

  @override
  State<PostWritePage> createState() => _PostWritePageState();
}

class _PostWritePageState extends State<PostWritePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final int titleMaxLength = 80; // 제목 글자 제한
  final int contentMaxLength = 500; // 내용 글자 제한

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색 흰색
      appBar: AppBar(
        backgroundColor: Colors.lightBlue, // 목록 페이지와 동일한 색상
        title: const Text(
          '게시글 작성',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // 제목 굵게
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 제목 입력칸
                  TextField(
                    controller: titleController,
                    maxLength: titleMaxLength,
                    decoration: InputDecoration(
                      hintText: '제목을 입력해주세요 ($titleMaxLength자 제한)',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 내용 입력칸
                  TextField(
                    controller: contentController,
                    maxLength: contentMaxLength,
                    maxLines: null, // 여러 줄 입력 가능
                    minLines: 10,    // 초기 표시 줄 수 (확장된 상태)
                    decoration: InputDecoration(
                      hintText: '내용을 입력해주세요 ($contentMaxLength자 제한)',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 60), // 하단 버튼 공간 확보
                ],
              ),
            ),
          ),
          // 사진 업로드 버튼
          Positioned(
            left: 12,
            bottom: 12,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image, color: Colors.black),
              label: const Text('사진 업로드', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 완료 버튼
          Positioned(
            right: 12,
            bottom: 12,
            child: ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('완료', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
      );
      return;
    }

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: widget.category,
      title: titleController.text,
      content: contentController.text,
      author: '닉네임', // 임시
      region: '전국', // 기본값
      subRegion: '전체',
      genre: '전체',
      views: 0,
      likes: 0,
      date: DateTime.now(),
    );

    Navigator.pop(context, newPost);
  }
}
