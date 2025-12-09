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
import 'package:cultureyo/src/features/profile/domain/user_service.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late int likes;
  // 게시물 신고 상태는 로컬에서 관리 (서버 응답으로 업데이트)
  bool _isPostReported = false;
  late int _postReportedCount;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoadingComments = true;

  String? _currentUserId;
  bool _isUserIdLoading = true;

  late CommentService _commentService;
  late PostService _postService;
  late UserService _userService;

  String? _replyingToCommentId;
  String _commentHintText = '댓글을 입력하세요...';

  bool get _isAuthor {
    if (_isUserIdLoading || _currentUserId == null) return false;
    return _currentUserId == widget.post.authorId;
  }

  // ==========================================================

  @override
  void initState() {
    super.initState();
    likes = widget.post.likes;
    _postReportedCount = widget.post.reportedCount ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _commentService = context.read<CommentService>();
    _postService = context.read<PostService>();
    _userService = context.read<UserService>();

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

  Future<void> _loadCurrentUserAndComments() async {
    // 1. 사용자 ID 로드 시도
    try {
      final id = await _userService.loadUserId();
      if (!mounted) return;

      setState(() {
        _currentUserId = id;
        _isUserIdLoading = false;
      });
      log('✅ User ID 로드 성공: $_currentUserId', name: 'USER_LOAD');
    } on Exception catch (e) {
      log('🚨 [USER_ID_LOAD_ERROR] $e', name: 'USER_LOAD');
      if (!mounted) return;

      _showSnackbar('사용자 정보를 불러오는데 실패했습니다. 댓글 작성/좋아요 권한이 제한됩니다.');
      setState(() {
        _isUserIdLoading = false;
        _currentUserId = 'guest_unauth';
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
    _showSnackbar('답글 모드로 전환되었습니다.', duration: const Duration(milliseconds: 1000));
  }

  void _cancelReplying() {
    if (!mounted) return;
    setState(() {
      _replyingToCommentId = null;
      _commentHintText = '댓글을 입력하세요...';
      FocusScope.of(context).unfocus();
    });
  }

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

  Future<void> _fetchComments() async {
    if (!mounted) return;

    if (!_isLoadingComments) {
      setState(() {
        _isLoadingComments = true;
      });
    }

    _cancelReplying();

    try {
      // 서버에서 댓글 목록을 가져옵니다.
      final fetchedComments = await _commentService.fetchComments(widget.post.id);

      if (mounted) {
        setState(() {
          _isLoadingComments = false;
          _comments = _sortCommentsByHierarchy(fetchedComments);
        });
      }
    } on DioException catch (e) {
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
    } on DioException catch (e) {
      log('🚨 [SUBMIT_ERROR] DioException: ${e.message}', name: 'COMMENT_SUBMIT');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('작성 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      _showSnackbar('작성 중 예상치 못한 오류 발생');
    }
  }

  // 게시물 좋아요 토글 API 호출
  Future<void> _toggleLikeApi() async {
    if (_currentUserId == null || _isUserIdLoading || _currentUserId == 'guest_unauth') {
      _showSnackbar('로그인된 사용자만 추천할 수 있습니다.', duration: const Duration(seconds: 2));
      return;
    }

    try {
      final String postId = widget.post.id;
      final String category = widget.post.category;

      log('▶️ [POST_LIKE_TOGGLE_INIT] Post ID: $postId, Category: $category', name: 'UI_ACTION_LIKE');

      final int newLikesCount = await _postService.toggleLike(
        postId,
        category,
      );

      if (mounted) {
        setState(() {
          likes = newLikesCount;
        });

        _showSnackbar('게시물 추천 정보가 업데이트되었습니다. (새로고침 필요)', duration: const Duration(seconds: 1));
      }

    } on DioException catch (e) {
      log('🚨 [LIKE_TOGGLE_ERROR] DioException: ${e.message}', name: 'POST_LIKE');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('추천 처리 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      log('🚨 [LIKE_TOGGLE_ERROR] Exception: $e', name: 'POST_LIKE');
      _showSnackbar('추천 처리 중 예상치 못한 오류 발생');
    }
  }

  // 게시물 신고 로직
  Future<void> _toggleReportPostApi() async {
    if (_currentUserId == null || _isUserIdLoading || _currentUserId == 'guest_unauth') {
      _showSnackbar('로그인된 사용자만 게시글을 신고할 수 있습니다.', duration: const Duration(seconds: 2));
      return;
    }

    try {
      final result = await _postService.toggleReportPost(
        widget.post.id,
        widget.post.category,
      );

      log('✅ [POST_REPORT_SUCCESS] API Response reported: ${result.reported}, count: ${result.reportedCount}', name: 'POST_REPORT');

      if (mounted) {
        setState(() {
          _isPostReported = !result.reported; // 서버 응답을 반영
          _postReportedCount = result.reportedCount;
        });

        String message;

        if (result.reported) {
          message = '게시글을 신고 처리했습니다.';
          if (_postReportedCount >= 3) {
            message += ' (게시물 차단이 적용되었습니다.)';
          }
        } else {
          message = '이미 신고한 게시글입니다.';
        }

        _showSnackbar('$message (누적 신고: ${_postReportedCount}회)', duration: const Duration(seconds: 2));
      }

    } on DioException catch (e) {
      log('🚨 [POST_REPORT_ERROR] DioException: ${e.message}', name: 'POST_REPORT');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('게시글 신고 처리 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      log('🚨 [POST_REPORT_ERROR] Exception: $e', name: 'POST_REPORT');
      _showSnackbar('게시글 신고 처리 중 예상치 못한 오류 발생');
    }
  }

  // 댓글 좋아요 상태를 로컬에서 업데이트하는 헬퍼 함수
  void _updateCommentLikeStatus(String commentId, int newLikesCount, bool isLiked) {
    final int index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final oldComment = _comments[index];

      // copyWith를 사용하여 깔끔하게 업데이트합니다.
      final updatedComment = oldComment.copyWith(
        // 좋아요 필드
        likes: newLikesCount,
        liked: isLiked,
      );

      setState(() {
        _comments[index] = updatedComment;
      });
    }
  }


  // 댓글 신고 상태를 로컬에서 업데이트하는 헬퍼 함수
  void _updateCommentReportStatus(String commentId, int newReportedCount, bool isReported) {
    final int index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final oldComment = _comments[index];
      // copyWith를 사용하여 갱신
      final updatedComment = oldComment.copyWith(
        reportedCount: newReportedCount,
        reported: isReported,
      );

      setState(() {
        _comments[index] = updatedComment;
      });
    }
  }


  // 댓글 좋아요 토글 API 호출 및 UI 처리
  Future<void> _toggleLikeCommentApi(Comment comment) async {
    // 1. 권한 확인 (로그인 필요)
    if (_currentUserId == null || _isUserIdLoading || _currentUserId == 'guest_unauth') {
      _showSnackbar('로그인된 사용자만 댓글을 추천할 수 있습니다.', duration: const Duration(seconds: 2));
      return;
    }

    // 2. 작성자 본인의 댓글은 좋아요 불가능
    if (_currentUserId == comment.userId) {
      _showSnackbar('본인이 작성한 댓글에는 좋아요를 누를 수 없습니다.', duration: const Duration(seconds: 2));
      return;
    }


    try {
      final result = await _commentService.toggleCommentLike(comment.id);

      if (mounted) {
        // 1. 로컬 상태 업데이트 (현재 좋아요 누른 상태를 반영)
        _updateCommentLikeStatus(comment.id, result.likeCount, result.liked);

        // 2. 스낵바 메시지 출력
        final String action = result.liked ? '좋아요' : '좋아요 취소';
        _showSnackbar('댓글에 $action 처리되었습니다. (현재 ${result.likeCount}개)', duration: const Duration(seconds: 1));
      }

    } on DioException catch (e) {
      log('🚨 [COMMENT_LIKE_ERROR] DioException: ${e.message}', name: 'COMMENT_LIKE');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('댓글 좋아요 처리 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      log('🚨 [COMMENT_LIKE_ERROR] Exception: $e', name: 'COMMENT_LIKE');
      _showSnackbar('댓글 좋아요 처리 중 예상치 못한 오류 발생');
    }
  }


  // 댓글 신고 API 호출 및 UI 처리
  Future<void> _toggleReportApi(Comment comment) async {
    if (_currentUserId == null || _isUserIdLoading || _currentUserId == 'guest_unauth') {
      _showSnackbar('로그인된 사용자만 신고할 수 있습니다.', duration: const Duration(seconds: 2));
      return;
    }

    try {
      final result = await _commentService.toggleCommentReport(comment.id);

      if (mounted) {

        _updateCommentReportStatus(comment.id, result.reportedCount, result.reported);

        String message;
        if (result.reported) {
          // 서버 응답: 신고 성공
          message = '댓글을 신고 처리했습니다.';
          if (result.reportedCount >= 3) {
            message += ' (누적 신고 3회 이상: 댓글이 차단됩니다.)';
          }
        } else {
          // 서버 응답: 신고 실패 (이미 신고했거나 다른 이유)
          message = '이미 신고한 댓글입니다. ';
        }
        _showSnackbar(message, duration: const Duration(seconds: 2));
      }

    } on DioException catch (e) {
      log('🚨 [REPORT_ERROR] DioException: ${e.message}', name: 'COMMENT_REPORT');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('신고 처리 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      log('🚨 [REPORT_ERROR] Exception: $e', name: 'COMMENT_REPORT');
      _showSnackbar('신고 처리 중 예상치 못한 오류 발생');
    }
  }


  Future<void> _deletePostApi() async {
    if (_currentUserId == null) {
      _showSnackbar('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    try {
      final success = await _postService.deletePost(
        widget.post.id,
        widget.post.category,
      );

      if (mounted) {
        if (success) {
          _showSnackbar('게시물이 성공적으로 삭제되었습니다.');
          Navigator.pop(context, true);
        } else {
          _showSnackbar('게시물 삭제 실패 (서버 응답 오류)');
        }
      }
    } on DioException catch (e) {
      log('🚨 [DELETE_ERROR] DioException: ${e.message}', name: 'POST_DELETE');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('게시물 삭제 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      _showSnackbar('게시물 삭제 중 예상치 못한 오류 발생');
    }
  }

  Future<void> _deleteCommentApi(String commentId) async {
    if (_currentUserId == null) {
      _showSnackbar('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    log('▶️ [DELETE_COMMENT_INIT] Comment ID: $commentId, User ID: $_currentUserId', name: 'UI_ACTION_DELETE');
    try {
      final success = await _commentService.deleteComment(commentId);

      if (mounted) {
        if (success) {
          _showSnackbar('댓글이 성공적으로 삭제되었습니다.');
          _fetchComments(); // 새로고침
        } else {
          _showSnackbar('댓글 삭제 실패 (서버 응답 오류)');
        }
      }
    } on DioException catch (e) {
      log('🚨 [DELETE_ERROR] DioException: ${e.message}', name: 'COMMENT_DELETE');
      if (mounted) {
        final errorMessage = e.response?.data['message']?.toString() ?? '네트워크 오류';
        _showSnackbar('댓글 삭제 중 오류 발생: $errorMessage');
      }
    } catch (e) {
      _showSnackbar('댓글 삭제 중 예상치 못한 오류 발생');
    }
  }

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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

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

  Widget _buildPerformanceCard(BuildContext context) {
    if (widget.post.performanceUrl == null || widget.post.performanceUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final url = widget.post.performanceUrl!;
    final displayTitle = (widget.post.performanceTitle != null && widget.post.performanceTitle!.isNotEmpty)
        ? widget.post.performanceTitle!
        : '이 공연에 대해 더 알고싶다면?';

    // 이전에 저장된 정보를 활용하여 PerformanceDetail이 필요함을 인지합니다.
    // 현재는 URL만 사용하지만, 상세 정보(thumbnail, date, region, genre)를 표시할 수 있습니다.
    // [2025-11-18] 저장된 정보: ID 포맷 'genre:number', '/api/getEventDetail' API 호출 계획

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
                  // Tapping this card should open a new browser window with a link to the performance's information.
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

  // 🌟 [통합 및 수정된 함수] 게시글/댓글 작성자 프로필 팝업을 띄우는 메서드
  void _showUserProfileDialog(BuildContext context, String authorNickname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목: 인수로 받은 닉네임 사용
                Text(
                  '$authorNickname님의 프로필',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // 프로필 아이콘
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.lightBlue.withOpacity(0.2), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 45,
                        child: Icon(Icons.person, size: 45, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 닉네임
                Text(
                  authorNickname, // 인수로 받은 닉네임 사용
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // 1:1 채팅하기 버튼
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 1:1 채팅하기 기능 구현
                    _showSnackbar('$authorNickname님에게 1:1 채팅을 신청했습니다. (기능 미구현)');
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('1:1 채팅하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[200],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 12),

                // 닫기 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[200],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    elevation: 2,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // 댓글 아이템 빌드 함수
  Widget _buildCommentItem(Comment comment) {
    final bool isDeleted = comment.isDeleted;
    final bool isBlockedByReport = comment.reportedCount >= 3;

    final String displayText = isDeleted
        ? '삭제된 댓글입니다.'
        : (isBlockedByReport
        ? '관리자에 의해 차단된 댓글입니다.'
        : comment.text);

    final Color textColor = isDeleted ? Colors.grey : (isBlockedByReport ? Colors.red.shade400 : Colors.black);

    final double leftPadding = comment.parentId != null ? 36.0 : 0.0;
    final bool isReplyingToThis = _replyingToCommentId == comment.id;

    final bool isMyComment = !isDeleted && _currentUserId != null && comment.userId == _currentUserId;
    final bool canDeleteComment = isMyComment;

    // 좋아요 버튼 표시 여부: 삭제/차단되지 않은 댓글
    final bool showLikeButton = !isDeleted && !isBlockedByReport;

    const IconData likeIcon = Icons.thumb_up_outlined;
    const Color likeColor = Colors.blue;

    // 신고하기 버튼 표시 여부: 삭제/차단되지 않은 댓글 && 내 댓글이 아닐 때
    final bool showReportButton = !isDeleted && !isBlockedByReport && !isMyComment;


    return Column(
      children: [
        Padding(
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

                    // 🌟 [수정] 닉네임과 프로필 아이콘을 묶고 탭 제스처 추가
                    GestureDetector(
                      onTap: () {
                        // 삭제/차단되지 않은 댓글이 아니며 본인 댓글도 아닐 때만 프로필 다이얼로그 표시
                        if (!isDeleted && !isBlockedByReport && !isMyComment) {
                          // 🌟 [수정] 통합 함수 호출 시 댓글 작성자 닉네임 전달
                          _showUserProfileDialog(context, comment.authorNickname);
                        } else if (isMyComment) {
                          _showSnackbar('본인의 프로필은 마이페이지에서 확인해 주세요.', duration: const Duration(seconds: 1));
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            comment.authorNickname,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          // ⭐ [추가] 댓글 작성자 프로필 아이콘 (삭제/차단되지 않았을 때만 표시)
                          if (!isDeleted && !isBlockedByReport)
                            Icon(
                              Icons.account_circle,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                        ],
                      ),
                    ),

                    const Spacer(), // 남은 공간을 채워 날짜를 오른쪽으로 밀어냅니다.

                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 댓글 본문 내용 영역을 회색 배경으로 구분
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12), // 내용과 배경 경계 사이의 패딩
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100, // 옅은 회색 배경색 적용
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontStyle: (isDeleted || isBlockedByReport) ? FontStyle.italic : FontStyle.normal,
                        fontWeight: isBlockedByReport ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 답글/좋아요/삭제/신고 버튼 영역
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Row(
                    children: [
                      // 답글 작성 버튼
                      if (!isDeleted && !isBlockedByReport && comment.parentId == null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[200], // blue[200] 배경색
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () => _setReplyingTo(comment),
                            child: const Text('답글 작성', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)), // 흰색 텍스트
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),

                      if (!isDeleted && !isBlockedByReport && comment.parentId == null)
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

                      // 좋아요 버튼 디자인
                      if (showLikeButton)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[200], // blue[200] 배경색 적용
                            borderRadius: BorderRadius.circular(8), // 둥근 모서리
                          ),
                          child: TextButton.icon(
                            onPressed: () => _toggleLikeCommentApi(comment),
                            icon: const Icon(likeIcon, size: 14, color: Colors.white), // 아이콘 색상 흰색
                            label: Text(
                                '${comment.likes}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white, // 텍스트 색상 흰색
                                    fontWeight: FontWeight.normal)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 버튼 클릭 영역 최소화
                            ),
                          ),
                        ),
                      const Spacer(),
                      // 댓글 삭제 버튼
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
                      if (showReportButton)
                        TextButton.icon(
                          onPressed: () => _toggleReportApi(comment),
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
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    // 게시물 신고 누적 3회 이상 여부
    final bool isPostBlocked = _postReportedCount >= 3;

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
        backgroundColor: Colors.blue[200],
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

                  // 게시물 제목
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Row( // 작성자 정보 표시를 위한 Row 추가
                          children: [
                            const Text('작성자: ', style: TextStyle(fontSize: 14, color: Colors.black87)),
                            Text(
                              widget.post.author,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(width: 6),
                            // 🌟 [수정] 프로필 아이콘 추가 (클릭 시 통합 함수 호출)
                            GestureDetector(
                              onTap: () {
                                _showUserProfileDialog(context, widget.post.author);
                              },
                              child: Icon(
                                Icons.account_circle,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye, size: 16),
                          const SizedBox(width: 4),
                          Text('${widget.post.views}'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // 좋아요 개수 표시
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


                  // 게시물 수정/삭제 버튼 (작성자일 경우)
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
                                      TextButton(child: const Text("취소"), onPressed: () => Navigator.of(context).pop()),
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

                  // 게시물 내용 조건부 표시
                  if (isPostBlocked)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Center(
                        child: Text(
                          '관리자에 의해 차단된 글입니다.',
                          style: TextStyle(fontSize: 16, color: Colors.red.shade500, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    Text(widget.post.content, style: const TextStyle(fontSize: 16)),

                  // 공연 카드 (차단되지 않았을 때만 표시)
                  _buildPerformanceCard(context),

                  const SizedBox(height: 16),

                  // 게시물 신고 버튼
                  if (!_isAuthor && !isPostBlocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _toggleReportPostApi,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.report, size: 20, color: Colors.red[700]),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '신고하기',
                                    style: TextStyle(fontSize: 14, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 이미 신고했거나 차단된 경우 메시지 표시
                  if (_isPostReported || isPostBlocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isPostBlocked
                                ? '이 게시물은 차단 상태입니다. '
                                : (_isPostReported ? '이미 신고한 게시글입니다. (누적 신고: $_postReportedCount)' : ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),


                  Center(
                    child: GestureDetector(
                      onTap: _toggleLikeApi,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.thumb_up_outlined,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '추천하기',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.normal,
                              ),
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
            color: Colors.blue[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    readOnly: _currentUserId == null || _isUserIdLoading,
                    decoration: InputDecoration(
                      hintText: _isUserIdLoading
                          ? '사용자 정보를 불러오는 중...'
                          : (_currentUserId == 'guest_unauth' ? '로그인 상태를 확인할 수 없습니다.' : _commentHintText),
                      hintStyle: TextStyle(color: _currentUserId == 'guest_unauth' ? Colors.red : Colors.grey[500]),
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
                  onTap: (_currentUserId == null || _isUserIdLoading || _currentUserId == 'guest_unauth') ? null : _submitCommentApi,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (_currentUserId == null || _isUserIdLoading || _currentUserId == 'guest_unauth') ? Colors.grey : Colors.white,
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
                      color: (_currentUserId == null || _isUserIdLoading || _currentUserId == 'guest_unauth') ? Colors.white : Colors.lightBlue,
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