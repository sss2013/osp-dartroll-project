// lib/src/features/community/presentation/pages/post_edit_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:url_launcher/url_launcher.dart';
// PostService 추가
import 'package:cultureyo/src/features/community/service/post_service.dart';

// PostWritePage에서 사용하던 Performance 모델은 불필요하지만,
// 기존 코드를 단순화하기 위해 주석 처리하고 필요한 필드만 사용합니다.

class PostEditPage extends StatefulWidget {
  final Post postToEdit; // 수정할 기존 게시물 데이터

  const PostEditPage({Key? key, required this.postToEdit}) : super(key: key);

  @override
  State<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends State<PostEditPage> {
  // 제목 컨트롤러는 초기 데이터 채우기 용도로만 사용하고, 내용은 수정 가능해야 합니다.
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final int titleMaxLength = 80;
  final int contentMaxLength = 500;

  // 💡 [테스트용] 현재 사용자 ID 정의 (API 요청에 필요)
  final String _currentUserId = 'testUser123';

  // ⭐ [추가됨] PostService 인스턴스
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // ⭐ [새 로직] 기존 게시물 데이터를 폼에 채우기
  void _initializeData() {
    final Post post = widget.postToEdit;

    // 1. 제목 및 내용 설정
    titleController.text = post.title;
    // content는 수정 가능해야 하므로, 초기값으로 채웁니다.
    contentController.text = post.content;
  }

  // ⭐ [API 로직] 게시물 수정 API 호출 (POST 요청 사용) - Service 호출로 변경
  Future<void> _editPostApi() async {
    final String newContent = contentController.text.trim();
    final BuildContext currentContext = context;

    if (newContent.isEmpty) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('수정할 내용을 입력해주세요.')),
      );
      return;
    }

    final String postId = widget.postToEdit.id;
    final String category = widget.postToEdit.category;

    // 💡 [수정] http 통신 로직 제거 및 PostService 호출로 대체
    try {
      final success = await _postService.modifyPost(
        postId,
        _currentUserId,
        category,
        newContent,
      );

      if (!mounted) return;

      if (success) {
        // [게시물 수정 성공]
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('게시물이 성공적으로 수정되었습니다.')),
        );
        // 상세 페이지로 돌아갈 때, 데이터가 수정되었음을 알리기 위해 pop(true)
        Navigator.pop(currentContext, true);

      } else {
        // 실패는 Service 내부에서 로그 처리됨. 여기서는 사용자에게 알림
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('게시물 수정에 실패했습니다 (서버 오류)')),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('게시물 수정 요청 시간이 초과되었습니다.')),
      );
    } catch (e) {
      // Service 내부에서 에러 로그가 찍히므로, 여기서는 사용자에게 네트워크 오류만 알림
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('게시물 수정 중 네트워크 연결 오류가 발생했습니다.')),
      );
    }
  }

  // '수정 완료' 버튼 클릭 시
  void _onSubmit() {
    _editPostApi(); // 수정 API 호출
  }


  // --- 기존 코드에서 가져온 UI 관련 헬퍼 함수 ---

  // ⭐ [수정] 공연 상세 카드 UI 위젯 (링크 기능 유지 및 상세페이지 양식 동일하게 적용)
  Widget _buildPerformanceCard() {
    final post = widget.postToEdit;

    // URL이 없으면 카드도 표시하지 않음
    if (post.performanceUrl == null || post.performanceUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final url = post.performanceUrl!;
    // ⭐ [수정] 상세 페이지와 동일한 대체 텍스트 사용
    final displayTitle = '이 공연에 대해 더 알고싶다면?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            if (url.isNotEmpty) {
              final uri = Uri.parse(url);
              try {
                if (await canLaunchUrl(uri)) {
                  // 새 브라우저 창으로 링크 열기 기능 유지
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('링크를 열 수 없습니다.')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('잘못된 링크 형식입니다.')),
                  );
                }
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue[50], // 상세 페이지와 동일한 배경색
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.link, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Flexible(
                    child: Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87, // ⭐ [수정] 상세 페이지와 동일한 글자색
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // ⭐ [수정] 상세 페이지와 동일한 아이콘 및 색상
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle selectedTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
    );
    // 읽기 전용 스타일 정의
    const TextStyle readOnlyStyle = TextStyle(
      color: Colors.black54,
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text(
          '게시글 수정',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 1. 공연 선택 필드 (텍스트 고정, 글자색 수정)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '선택된 공연은 수정이 불가합니다.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // ⭐ [수정] 제목 필드와 동일하게 readOnlyStyle 적용
                            style: readOnlyStyle,
                          ),
                        ),
                        const Icon(Icons.lock_outline, color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. 제목 입력 필드 (읽기 전용 표시 유지)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            titleController.text.isNotEmpty ? titleController.text : '제목 없음',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: readOnlyStyle,
                          ),
                        ),
                        const Icon(Icons.lock_outline, color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. 내용 입력 필드 (수정 가능)
                  TextField(
                    controller: contentController,
                    maxLength: contentMaxLength,
                    maxLines: null,
                    minLines: 10,
                    decoration: InputDecoration(
                      hintText: '내용을 입력해주세요 ($contentMaxLength자 제한)',
                      hintStyle: selectedTextStyle,
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    style: selectedTextStyle,
                  ),
                  const SizedBox(height: 12),

                  // 4. 공연 상세 카드 위젯 (링크 확인 기능)
                  _buildPerformanceCard(),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),

          // ⭐ [수정] '수정 완료' 버튼
          Positioned(
            right: 12,
            bottom: 12,
            child: ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('수정 완료', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}