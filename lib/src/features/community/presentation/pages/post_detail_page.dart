// lib/src/features/community/presentation/pages/post_detail_page.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/features/community/presentation/pages/post_edit_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cultureyo/src/features/community/data/comment_model.dart';
import 'package:cultureyo/src/features/community/service/comment_service.dart';
import 'package:cultureyo/src/features/community/service/post_service.dart'; // PostService 추가


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

  // 💡 [테스트용] 현재 사용자 ID 정의
  final String _currentUserId = 'testUser123';
  final CommentService _commentService = CommentService();
  final PostService _postService = PostService(); // PostService 인스턴스 추가

  String? _replyingToCommentId;
  String _commentHintText = '댓글을 입력하세요...';

  // ⭐ [추가된 로직] 현재 사용자가 게시물 작성자인지 확인하는 Getter
  bool get _isAuthor {
    return _currentUserId == widget.post.authorId;
  }
  // ==========================================================


  @override
  void initState() {
    super.initState();
    likes = widget.post.likes;
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
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

  // ⭐ [분리 완료] 댓글 목록 조회 로직: CommentService 호출
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
    } on TimeoutException {
      log('🚨 [FETCH_TIMEOUT] 서버 응답 시간 초과', name: 'PAGE_FETCH');
      _showSnackbar('댓글 목록 로딩 시간 초과');
      if (mounted) setState(() => _isLoadingComments = false);
    } catch (e) {
      log('🚨 [FETCH_ERROR] Exception: $e', name: 'PAGE_FETCH');
      _showSnackbar('댓글 로딩 중 네트워크 오류 발생');
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  // ⭐ [분리 완료] 댓글 작성/답글 작성 로직: CommentService 호출
  Future<void> _submitCommentApi() async {
    final String commentText = _commentController.text.trim();
    final String? parentId = _replyingToCommentId;

    if (commentText.isEmpty) {
      _showSnackbar('내용을 입력해주세요.',duration: const Duration(milliseconds: 1000));
      return;
    }

    try {
      final success = await _commentService.submitComment(
        widget.post.id,
        _currentUserId,
        commentText,
        parentId: parentId,
      );

      if (success) {
        _showSnackbar(parentId != null ? '답글이 성공적으로 작성되었습니다.' : '댓글이 성공적으로 작성되었습니다.',duration: const Duration(milliseconds: 1000));
        _commentController.clear();
        _cancelReplying();
        _fetchComments();
      } else {
        _showSnackbar(parentId != null ? '답글 작성 실패 (서버 오류)' : '댓글 작성 실패 (서버 오류)');
      }
    } on TimeoutException {
      _showSnackbar('작성 요청 시간 초과');
    } catch (e) {
      _showSnackbar('작성 중 네트워크 오류 발생');
    }
  }

  // ⭐ [분리 완료] 게시물 삭제 로직: PostService 호출
  Future<void> _deletePostApi() async {
    try {
      final success = await _postService.deletePost(
        widget.post.id,
        _currentUserId,
        widget.post.category,
      );

      if (success) {
        _showSnackbar('게시물이 성공적으로 삭제되었습니다.');
        Navigator.pop(context, true);
      } else {
        _showSnackbar('게시물 삭제 실패 (서버 오류)');
      }
    } on TimeoutException {
      _showSnackbar('게시물 삭제 요청 시간 초과');
    } catch (e) {
      _showSnackbar('게시물 삭제 중 네트워크 오류 발생');
    }
  }

  // ⭐ [분리 완료] 댓글 삭제 로직: CommentService 호출
  Future<void> _deleteCommentApi(String commentId) async {
    log('▶️ [DELETE_COMMENT_INIT] Comment ID: $commentId, User ID: $_currentUserId', name: 'UI_ACTION_DELETE');
    try {
      final success = await _commentService.deleteComment(commentId, _currentUserId);

      if (success) {
        _showSnackbar('댓글이 성공적으로 삭제되었습니다.');
        _fetchComments();
      } else {
        _showSnackbar('댓글 삭제 실패 (서버 오류)');
      }
    } on TimeoutException {
      _showSnackbar('댓글 삭제 요청 시간 초과');
    } catch (e) {
      _showSnackbar('댓글 삭제 중 네트워크 오류 발생');
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
                  if (!isDeleted && comment.userId == _currentUserId)
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
                    decoration: InputDecoration(
                      hintText: _commentHintText,
                      hintStyle: TextStyle(color: Colors.grey[500]),
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
                  onTap: _submitCommentApi,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    child: const Icon(
                      Icons.send,
                      color: Colors.lightBlue,
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