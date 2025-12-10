// lib/src/features/community/presentation/pages/post_edit_page.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cultureyo/src/features/community/service/post_service.dart';


class PostEditPage extends StatefulWidget {
  final Post postToEdit; // 수정할 기존 게시물 데이터

  const PostEditPage({Key? key, required this.postToEdit}) : super(key: key);

  @override
  State<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends State<PostEditPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final int titleMaxLength = 80;
  final int contentMaxLength = 500;

  // 🌟 [추가] 중복 제출 방지 상태 변수
  bool _isSubmitting = false;

  final String _currentUserId = 'testUser123';
  late PostService _postService;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _postService = context.read<PostService>();
  }


  void _initializeData() {
    final Post post = widget.postToEdit;

    titleController.text = post.title;
    contentController.text = post.content;
  }

  // ⭐ [API 로직 수정] _isSubmitting 체크 및 상태 변경 로직 추가
  Future<void> _editPostApi() async {
    final String newContent = contentController.text.trim();
    final BuildContext currentContext = context;

    // 🌟 [수정] 이미 제출 중이면 함수 종료 (더블 클릭 방지)
    if (_isSubmitting) return;

    if (newContent.isEmpty) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('수정할 내용을 입력해주세요.')),
      );
      return;
    }

    // 🌟 [추가] 제출 시작: 상태 변경 및 UI 업데이트 (버튼 비활성화)
    setState(() {
      _isSubmitting = true;
    });

    final String postId = widget.postToEdit.id;
    final String category = widget.postToEdit.category;

    try {
      final success = await _postService.modifyPost(
        postId,
        category,
        newContent,
      );

      if (!mounted) return;

      if (success) {
        // [게시물 수정 성공]
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('게시물이 성공적으로 수정되었습니다.',), duration: const Duration(milliseconds: 1000)),
        );
        // 상세 페이지로 돌아갈 때, 데이터가 수정되었음을 알리기 위해 pop(true)
        Navigator.pop(currentContext, true);
      } else {
        // 실패는 Service 내부에서 로그 처리됨. 여기서는 사용자에게 알림
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('게시물 수정에 실패했습니다 (서버 응답 오류)')),
        );
      }
    } on DioException catch (e) {
      log('🚨 [게시물 수정 Dio 에러] ${e.message}', name: 'POST_EDIT');
      if (!mounted) return;
      // 서버에서 전달된 메시지가 있다면 사용, 없다면 Dio 에러 메시지 사용
      final errorMessage = e.response?.data['message']?.toString() ?? e.message;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('게시물 수정 중 오류 발생: $errorMessage')),
      );
    } catch (e) {
      log('🚨 [게시물 수정 일반 에러] Exception: $e', name: 'POST_EDIT');
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('게시물 수정 중 예상치 못한 연결 오류가 발생했습니다.')),
      );
    } finally {
      // 🌟 [추가] 작업 완료: 상태 변경 및 UI 업데이트 (성공/실패 무관, 버튼 재활성화)
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // '수정 완료' 버튼 클릭 시
  void _onSubmit() {
    // 🌟 [수정] 제출 중이 아닐 때만 API 호출 허용
    if (!_isSubmitting) {
      _editPostApi();
    }
  }


  // --- 기존 코드에서 가져온 UI 관련 헬퍼 함수 ---
  Widget _buildPerformanceCard() {
    final post = widget.postToEdit;

    if (post.performanceUrl == null || post.performanceUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final url = post.performanceUrl!;
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
            color: Colors.blue[50],
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
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
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
        backgroundColor: Colors.blue[200],
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
              // 🌟 [수정] _isSubmitting이 true일 때 onPressed를 null로 설정하여 버튼 비활성화
              onPressed: _isSubmitting ? null : _onSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // 버튼 배경색과 대비되는 흰색으로 설정
                ),
              )
                  : const Text('수정 완료', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                minimumSize: const Size(120, 48),
                // 🌟 [추가] 비활성화된 상태의 색상 정의
                disabledBackgroundColor: Colors.grey[400],
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