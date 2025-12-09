// lib/src/features/community/presentation/pages/post_edit_page.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 💡 [추가] Provider 사용을 위한 임포트
import 'package:dio/dio.dart'; // 💡 [추가] DioException 처리를 위한 임포트
// http 임포트는 제거되었습니다 (Service 계층으로 이동)
// import 'package:http/http.dart' as http;
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:url_launcher/url_launcher.dart';
// PostService 추가
import 'package:cultureyo/src/features/community/service/post_service.dart';


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

  // 💡 [테스트용] 현재 사용자 ID 정의 (API 요청에 필요했으나, 제거 예정)
  // 현재는 PostDetailPage처럼 UserService를 통해 ID를 로드하는 로직이 없으므로,
  // 이 페이지 진입 시 인증 상태가 유지된다는 가정 하에 ID 필드 자체는 그대로 둡니다.
  final String _currentUserId = 'testUser123';

  // ⭐ [변경] PostService 인스턴스를 Provider로 주입받을 변수로 선언
  late PostService _postService;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 💡 [추가] Service 인스턴스를 context를 통해 가져오는 메서드
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context.read를 사용하여 Service 인스턴스를 가져옵니다.
    _postService = context.read<PostService>();
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

    // 💡 [수정] DioException 처리 로직으로 변경
    try {
      // 💡 [수정] _currentUserId 인자 제거 (Header 토큰 인증 사용)
      final success = await _postService.modifyPost(
        postId,
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
          const SnackBar(content: Text('게시물 수정에 실패했습니다 (서버 응답 오류)')),
        );
      }
    } on DioException catch (e) { // 💡 [추가] DioException 처리
      log('🚨 [게시물 수정 Dio 에러] ${e.message}', name: 'POST_EDIT');
      if (!mounted) return;
      // 서버에서 전달된 메시지가 있다면 사용, 없다면 Dio 에러 메시지 사용
      final errorMessage = e.response?.data['message']?.toString() ?? e.message;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('게시물 수정 중 오류 발생: $errorMessage')),
      );
    } catch (e) {
      // Service 내부에서 에러 로그가 찍히므로, 여기서는 사용자에게 네트워크 오류만 알림 (기존 로직 유지)
      log('🚨 [게시물 수정 일반 에러] Exception: $e', name: 'POST_EDIT');
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('게시물 수정 중 예상치 못한 연결 오류가 발생했습니다.')),
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