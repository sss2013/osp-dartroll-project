// lib/src/features/community/presentation/pages/post_detail_page.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/features/community/presentation/pages/post_edit_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cultureyo/src/features/community/data/comment_model.dart';
import 'package:cultureyo/src/features/community/service/comment_service.dart';
import 'package:cultureyo/src/features/community/service/post_service.dart';
import 'package:cultureyo/src/features/profile/domain/user_service.dart'; // ⭐ [추가] UserService import

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late int likes;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoadingComments = true;

  // 💡 [변경] 더미 데이터 제거 및 실제 ID를 저장할 변수와 로딩 상태 변수 추가
  String? _currentUserId;
  bool _isUserIdLoading = true;


  // 💡 [변경] Service 인스턴스를 Provider로 주입받을 변수로 선언
  late CommentService _commentService;
  late PostService _postService;
  late UserService _userService; // ⭐ [추가] UserService 변수

  String? _replyingToCommentId;
  String _commentHintText = '댓글을 입력하세요...';

  // ⭐ [수정] 현재 사용자가 게시물 작성자인지 확인하는 Getter (ID 로드 상태 고려)
  bool get _isAuthor {
    // ID 로드가 완료되었고, ID가 null이 아니며, 게시물 작성자 ID와 일치할 때만 true
    if (_isUserIdLoading || _currentUserId == null) return false;
    return _currentUserId == widget.post.authorId;
  }

  // ==========================================================


  @override
  void initState() {
    super.initState();
    likes = widget.post.likes;
    // 🚨 _fetchComments는 didChangeDependencies에서 호출되는 _loadCurrentUserAndComments()에 통합됩니다.
  }

  // 💡 [수정] Service 인스턴스를 context를 통해 가져오는 메서드
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context.read를 사용하여 Service 인스턴스를 가져옵니다.
    _commentService = context.read<CommentService>();
    _postService = context.read<PostService>();
    _userService = context.read<UserService>(); // ⭐ [추가] UserService 주입

    // 🚨 ID 로드 로직 추가 및 댓글 목록 로드 실행 통합
    if (_currentUserId == null && _isUserIdLoading) {
      _loadCurrentUserAndComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // ⭐ [신규 함수] 사용자 ID 로드와 댓글 로드 로직을 통합 관리
  Future<void> _loadCurrentUserAndComments() async {
    // 1. 사용자 ID 로드 시도
    try {
      final id = await _userService.loadUserId();
      if (!mounted) return;

      setState(() {
        _currentUserId = id; // 실제 유저 ID 저장
        _isUserIdLoading = false;
      });
      log('✅ User ID 로드 성공: $_currentUserId', name: 'USER_LOAD');
    } on Exception catch (e) {
      log('🚨 [USER_ID_LOAD_ERROR] $e', name: 'USER_LOAD');
      if (!mounted) return;

      // ID 로드 실패 시 (예: 로그아웃 상태, 네트워크 오류)
      _showSnackbar('사용자 정보를 불러오는데 실패했습니다. 댓글 작성/수정/삭제 권한이 제한됩니다.');
      setState(() {
        _isUserIdLoading = false;
        _currentUserId = 'guest_unauth'; // 인증 실패 상태를 나타내는 임시 ID
      });
    }

    // 2. ID 로드 성공/실패 여부와 관계없이 댓글 로드 실행
    _fetchComments();
  }


  void _setReplyingTo(Comment parentComment) {
    if (!mounted) return;
    setState(() {
      _replyingToCommentId = parentComment.id;
      _commentHintText = '${parentComment.authorNickname}님에게 답글을 입력하세요...';
      _commentFocusNode.requestFocus();
    });
    // SnackBar 노출 시간 1.5초로 단축
    _showSnackbar('답글 모드로 전환되었습니다.', duration: const Duration(milliseconds: 1000));
  }

  void _cancelReplying() {
    if (!mounted) return;
    setState(() {
      _replyingToCommentId = null;
      _commentHintText = '댓글을 입력하세요...';
      FocusScope.of(context).unfocus(); // 키보드 내리기
    });
  }

  // 댓글 계층 구조 정렬 로직 (변경 없음)
  List<Comment> _sortCommentsByHierarchy(List<Comment> allComments) {
    final List<Comment> sortedList = [];
    final List<Comment> topLevelComments = allComments
        .where((c) => c.parentId == null)
        .toList();
    topLevelComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final Map<String, List<Comment>> repliesMap = {};
    for (var comment in allComments.where((c) => c.parentId != null)) {
      if (comment.parentId != null) {
        repliesMap.putIfAbsent(comment.parentId!, () => []).add(comment);
      }
    }

    for (var parent in topLevelComments) {
      sortedList.add(parent);
      final List<Comment>? replies = repliesMap[parent.id];
      if (replies != null) {
        replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        sortedList.addAll(replies);
      }
    }
    return sortedList;
  }

  // ⭐ [수정] 댓글 목록 조회 로직: DioException 처리 추가
  Future<void> _fetchComments() async {
    if (!mounted) return;
    _cancelReplying();

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final fetchedComments = await _commentService.fetchComments(widget.post.id);

      if (mounted) {
        setState(() {
          _isLoadingComments = false;
          _comments = _sortCommentsByHierarchy(fetchedComments);
        });
      }
    } on DioException catch (e) { // 💡 [추가] DioException 처리
      log('🚨 [FETCH_ERROR] DioException: ${e.message}', name: 'COMMENT_FETCH');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('댓글 로딩 중 오류 발생: $errorMessage');
        setState(() => _isLoadingComments = false);
      }
    } catch (e) {
      log('🚨 [FETCH_ERROR] Exception: $e', name: 'COMMENT_FETCH');
      _showSnackbar('댓글 로딩 중 예상치 못한 오류 발생');
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  // ⭐ [수정] 댓글 작성/답글 작성 로직: userId 인자 제거
  Future<void> _submitCommentApi() async {
    if (_currentUserId == null) {
      _showSnackbar('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    final String commentText = _commentController.text.trim();
    final String? parentId = _replyingToCommentId;

    if (commentText.isEmpty) {
      _showSnackbar('내용을 입력해주세요.',duration: const Duration(milliseconds: 1000));
      return;
    }

    try {
      // 💡 [수정] userId 인자 제거 (토큰 사용)
      final success = await _commentService.submitComment(
        widget.post.id,
        commentText,
        parentId: parentId,
      );

      if (mounted) {
        if (success) {
          _showSnackbar(parentId != null ? '답글이 성공적으로 작성되었습니다.' : '댓글이 성공적으로 작성되었습니다.',duration: const Duration(milliseconds: 1000));
          _commentController.clear();
          _cancelReplying();
          _fetchComments(); // 새로고침
        } else {
          _showSnackbar(parentId != null ? '답글 작성 실패 (서버 오류)' : '댓글 작성 실패 (서버 오류)');
        }
      }
    } on DioException catch (e) { // 💡 [추가] DioException 처리
      log('🚨 [SUBMIT_ERROR] DioException: ${e.message}', name: 'COMMENT_SUBMIT');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('작성 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      _showSnackbar('작성 중 예상치 못한 오류 발생');
    }
  }

  // ⭐ [수정] 게시물 삭제 로직: userId 인자 제거
  Future<void> _deletePostApi() async {
    if (_currentUserId == null) {
      _showSnackbar('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    try {
      // 💡 [수정] userId 인자 제거 (토큰 사용)
      final success = await _postService.deletePost(
        widget.post.id,
        widget.post.category,
      );

      if (mounted) {
        if (success) {
          _showSnackbar('게시물이 성공적으로 삭제되었습니다.');
          Navigator.pop(context, true); // true 반환하여 목록 새로고침 유도
        } else {
          _showSnackbar('게시물 삭제 실패 (서버 응답 오류)');
        }
      }
    } on DioException catch (e) { // 💡 [추가] DioException 처리
      log('🚨 [DELETE_ERROR] DioException: ${e.message}', name: 'POST_DELETE');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('게시물 삭제 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      _showSnackbar('게시물 삭제 중 예상치 못한 오류 발생');
    }
  }

  // ⭐ [수정] 댓글 삭제 로직: userId 인자 제거
  Future<void> _deleteCommentApi(String commentId) async {
    if (_currentUserId == null) {
      _showSnackbar('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    log('▶️ [DELETE_COMMENT_INIT] Comment ID: $commentId, User ID: $_currentUserId', name: 'UI_ACTION_DELETE');
    try {
      // 💡 [수정] userId 인자 제거 (토큰 사용)
      final success = await _commentService.deleteComment(commentId); // ID가 null이 아님을 보장

      if (mounted) {
        if (success) {
          _showSnackbar('댓글이 성공적으로 삭제되었습니다.');
          _fetchComments(); // 새로고침
        } else {
          _showSnackbar('댓글 삭제 실패 (서버 응답 오류)');
        }
      }
    } on DioException catch (e) { // 💡 [추가] DioException 처리
      log('🚨 [DELETE_ERROR] DioException: ${e.message}', name: 'COMMENT_DELETE');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('댓글 삭제 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      _showSnackbar('댓글 삭제 중 예상치 못한 오류 발생');
    }
  }

  // ⭐ [복구] SnackBar duration 설정 가능하도록 개선
  void _showSnackbar(String message, {Duration duration = const Duration(seconds: 4)}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
        ),
      );
    }
  }

  // ⭐ [복구] 날짜 포맷팅 헬퍼 함수
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ⭐ [복구] 카테고리 박스 헬퍼 함수
  Widget _buildCategoryBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // ⭐ [복구] 공연 카드 헬퍼 함수
  Widget _buildPerformanceCard(BuildContext context) {
    if (widget.post.performanceUrl == null || widget.post.performanceUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final url = widget.post.performanceUrl!;
    final displayTitle = (widget.post.performanceTitle != null && widget.post.performanceTitle!.isNotEmpty)
        ? widget.post.performanceTitle!
        : '이 공연에 대해 더 알고싶다면?';

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
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
              children: [
                const Icon(Icons.link, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Flexible(
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
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ⭐ [복구] 댓글 아이템 빌드 헬퍼 함수
  Widget _buildCommentItem(Comment comment) {
    final bool isDeleted = comment.isDeleted;
    final String displayText = isDeleted ? '삭제된 댓글입니다.' : comment.text;
    final Color textColor = isDeleted ? Colors.grey : Colors.black;
    final double leftPadding = comment.parentId != null ? 36.0 : 0.0;
    final bool isReplyingToThis = _replyingToCommentId == comment.id;

    // 💡 [수정] 댓글 삭제 버튼 조건에 _currentUserId가 null이 아닌지 확인 추가
    final bool canDeleteComment = !isDeleted && _currentUserId != null && comment.userId == _currentUserId;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 6, bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isReplyingToThis ? Colors.yellow[50] : Colors.white,
          border: Border.all(color: isReplyingToThis ? Colors.orange : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 닉네임, 날짜
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.person, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment.authorNickname,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _formatDate(comment.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 내용
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                displayText,
                style: TextStyle(color: textColor, fontSize: 14, fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal),
              ),
            ),
            const SizedBox(height: 8),

            // 답글/추천/삭제/신고 버튼 영역
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(
                children: [
                  // 답글 작성 버튼
                  if (!isDeleted && comment.parentId == null)
                    TextButton(
                      onPressed: () => _setReplyingTo(comment),
                      child: const Text('답글 작성', style: TextStyle(fontSize: 12, color: Colors.blue)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        minimumSize: const Size(0, 0),
                      ),
                    ),

                  if (!isDeleted && comment.parentId == null && isReplyingToThis)
                    const SizedBox(width: 8),

                  // 답글 모드 해제 버튼
                  if (isReplyingToThis)
                    TextButton(
                      onPressed: _cancelReplying,
                      child: const Text('답글 취소', style: TextStyle(fontSize: 12, color: Colors.orange)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        minimumSize: const Size(0, 0),
                      ),
                    ),

                  const Spacer(),

                  // ⭐ [수정] 댓글 삭제 버튼 조건 변경
                  if (canDeleteComment)
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("댓글 삭제"),
                              content: const Text("이 댓글을 정말로 삭제하시겠습니까?"),
                              actions: <Widget>[
                                TextButton(child: const Text("취소"), onPressed: () => Navigator.of(context).pop()),
                                TextButton(
                                  child: const Text("삭제", style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _deleteCommentApi(comment.id);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('삭제', style: TextStyle(fontSize: 12, color: Colors.red)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        minimumSize: const Size(0, 0),
                      ),
                    ),
                  const SizedBox(width: 8),

                  // 신고하기 버튼
                  if (!isDeleted)
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.report, size: 14, color: Colors.red),
                      label: const Text('신고하기', style: TextStyle(fontSize: 12, color: Colors.red)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        minimumSize: const Size(0, 0),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {

    // ⭐ [추가] 유저 ID 로딩 중일 때 로딩 인디케이터 표시
    if (_isUserIdLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '게시글 상세',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Wrap(
                    spacing: 4,
                    children: [
                      _buildCategoryBox(widget.post.region),
                      _buildCategoryBox(widget.post.genre),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    widget.post.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Text('작성자: ${widget.post.author}'),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye, size: 16),
                          const SizedBox(width: 4),
                          Text('${widget.post.views}'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.thumb_up, size: 16),
                          const SizedBox(width: 4),
                          Text('$likes'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${widget.post.date.year}.${widget.post.date.month.toString().padLeft(2, '0')}.${widget.post.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 20),


                  if (_isAuthor)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [

                          GestureDetector(
                            onTap: () async {
                              log('▶️ [POST_EDIT_BUTTON] 게시물 수정 버튼 클릭됨', name: 'UI_ACTION');

                              final bool? result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostEditPage(
                                    postToEdit: widget.post,
                                  ),
                                ),
                              );

                              if (result == true) {
                                _showSnackbar('게시물이 수정되었습니다. 상세 정보 새로고침이 필요합니다.');
                                // TODO: 수정 완료 후 게시물 상세 정보 갱신 로직 추가 필요
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 20, color: Colors.blue[700]),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '게시물 수정',
                                    style: TextStyle(fontSize: 14, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),


                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("게시글 삭제"),
                                    content: const Text("정말로 이 게시글을 삭제하시겠습니까?"),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text("취소"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("삭제", style: TextStyle(color: Colors.red)),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _deletePostApi();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_forever, size: 20, color: Colors.red[700]),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '게시물 삭제',
                                    style: TextStyle(fontSize: 14, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(widget.post.content, style: const TextStyle(fontSize: 16)),

                  _buildPerformanceCard(context),

                  const SizedBox(height: 16),


                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: 좋아요 API 호출 로직 추가 필요
                        setState(() {
                          likes += 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.thumb_up, size: 20, color: Colors.black),
                            SizedBox(width: 6),
                            Text(
                              '추천하기',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: 20),


                  if (_replyingToCommentId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.reply, size: 18, color: Colors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _commentHintText.replaceAll('입력하세요...', '작성 중'),
                              style: const TextStyle(color: Colors.orange, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: _cancelReplying,
                            child: const Text('취소', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),

                  const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),

                  _isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            '작성된 댓글이 없습니다.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '첫 댓글을 남겨보세요!',
                            style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) => _buildCommentItem(_comments[index]),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.lightBlue,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    // ⭐ [수정] _currentUserId가 null이면 댓글 입력을 막음
                    readOnly: _currentUserId == null || _isUserIdLoading,
                    decoration: InputDecoration(
                      hintText: _isUserIdLoading
                          ? '사용자 정보를 불러오는 중...'
                          : (_currentUserId == null ? '로그인 상태를 확인할 수 없습니다.' : _commentHintText),
                      hintStyle: TextStyle(color: _currentUserId == null ? Colors.red : Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                GestureDetector(
                  // ⭐ [수정] _currentUserId가 null이 아닐 때만 댓글 작성 가능
                  onTap: (_currentUserId == null || _isUserIdLoading) ? null : _submitCommentApi,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (_currentUserId == null || _isUserIdLoading) ? Colors.grey : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.send,
                      color: (_currentUserId == null || _isUserIdLoading) ? Colors.white : Colors.lightBlue,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}