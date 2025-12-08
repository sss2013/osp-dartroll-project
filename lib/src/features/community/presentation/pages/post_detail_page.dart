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
import 'package:cultureyo/src/features/profile/domain/user_service.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  // ⭐ [수정] _isLiked 제거, likes만 유지
  late int likes;

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
    // ⭐ [수정] PostModel에서 가져온 초기값으로 likes만 설정
    likes = widget.post.likes;
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

  // ⭐ [수정] 좋아요 토글 API 호출 (좋아요 개수만 업데이트)
  Future<void> _toggleLikeApi() async {
    if (_currentUserId == null || _isUserIdLoading || _currentUserId == 'guest_unauth') {
      _showSnackbar('로그인된 사용자만 추천할 수 있습니다.', duration: const Duration(seconds: 2));
      return;
    }

    try {
      final String postId = widget.post.id;
      final String category = widget.post.category;

      log('▶️ [POST_LIKE_TOGGLE_INIT] Post ID: $postId, Category: $category', name: 'UI_ACTION_LIKE');

      // PostService의 toggleLike 호출 (이제 int(likesCount)를 반환)
      final int newLikesCount = await _postService.toggleLike(
        postId,
        category,
      );

      if (mounted) {
        setState(() {
          likes = newLikesCount; // ⭐ [수정] Likes Count만 업데이트
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

  Widget _buildCommentItem(Comment comment) {
    final bool isDeleted = comment.isDeleted;
    final String displayText = isDeleted ? '삭제된 댓글입니다.' : comment.text;
    final Color textColor = isDeleted ? Colors.grey : Colors.black;
    final double leftPadding = comment.parentId != null ? 36.0 : 0.0;
    final bool isReplyingToThis = _replyingToCommentId == comment.id;

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
                  Text(widget.post.content, style: const TextStyle(fontSize: 16)),

                  _buildPerformanceCard(context),

                  const SizedBox(height: 16),


                  Center(
                    child: GestureDetector(
                      onTap: _toggleLikeApi,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          // ⭐ [수정] 좋아요 여부 UI가 불필요하므로, 기본 색상 사용
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ⭐ [수정] 아이콘을 채워진 아이콘이 아닌 기본 아이콘으로 고정
                            const Icon(
                              Icons.thumb_up_outlined,
                              size: 20,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '추천하기',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
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
            color: Colors.lightBlue,
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