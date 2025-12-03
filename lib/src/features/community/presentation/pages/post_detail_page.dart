import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart'; // DioException 처리를 위해 필요
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/features/community/data/comment_model.dart';
import 'package:cultureyo/src/features/community/service/post_service.dart';
import 'package:cultureyo/src/features/community/service/comment_service.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart'; // AuthManager import
import 'package:url_launcher/url_launcher.dart';
import 'post_edit_page.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late Post _currentPost;
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  final TextEditingController _commentController = TextEditingController();

  // ⭐️ [변경] PostService와 CommentService 인스턴스를 저장할 변수
  late PostService _postService;
  late CommentService _commentService;
  late AuthManager _authManager;

  String? _replyingToCommentId;
  String? _replyingToAuthor;

  // 💡 [변경] 인증된 사용자의 ID를 가져올 변수
  String _currentUserId = 'anonymous_user';

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;

    // ⭐️ Post-frame callback에서 서비스 초기화 및 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _fetchComments();
    });
  }

  // ⭐️ [추가] Provider를 통해 서비스 인스턴스를 초기화하는 함수
  void _initializeServices() {
    _postService = context.read<PostService>();
    _commentService = context.read<CommentService>();
    _authManager = context.read<AuthManager>();

    // AuthManager에서 현재 로그인된 사용자 ID를 가져옴 (로그인 상태를 가정)
    // AuthManager에 currentUser getter가 있고, 그 안에 userId 속성이 있다고 가정합니다.
    _currentUserId = _authManager.currentUser?.userId ?? 'anonymous_user';
    log('✅ Current User ID initialized: $_currentUserId', name: 'POST_DETAIL_AUTH');
  }


  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ⭐️ [수정] 댓글 목록 조회: CommentService 사용
  Future<void> _fetchComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      // ⭐️ CommentService 호출로 대체
      final fetchedComments = await _commentService.fetchComments(_currentPost.id);

      setState(() {
        _comments = fetchedComments;
        _isLoadingComments = false;
      });
      log('✅ [COMMENTS] Fetched ${_comments.length} comments.', name: 'POST_DETAIL');

    } on DioException catch (e) {
      log('🚨 [COMMENTS_ERROR] DioException: ${e.message}', name: 'POST_DETAIL');
      _showSnackbar('댓글 로드 실패: 네트워크 오류');
      setState(() {
        _isLoadingComments = false;
        _comments = [];
      });
    } catch (e) {
      log('🚨 [COMMENTS_ERROR] Unknown Exception: $e', name: 'POST_DETAIL');
      _showSnackbar('댓글 로드 중 알 수 없는 오류 발생');
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  // ⭐️ [수정] 댓글/답글 작성: CommentService 사용
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      _showSnackbar('댓글 내용을 입력해주세요.');
      return;
    }

    try {
      // ⭐️ CommentService 호출로 대체
      final success = await _commentService.submitComment(
        _currentPost.id,
        _currentUserId, // AuthManager에서 가져온 사용자 ID 사용
        text,
        parentId: _replyingToCommentId,
      );

      if (success) {
        _commentController.clear();
        _resetReplyState();
        // 작성 후 댓글 목록 새로고침
        await _fetchComments();
        _showSnackbar(_replyingToCommentId == null ? '댓글이 작성되었습니다.' : '답글이 작성되었습니다.');
      } else {
        _showSnackbar('댓글 작성에 실패했습니다. (서버 오류)');
      }
    } on DioException catch (e) {
      log('🚨 [SUBMIT_ERROR] DioException: ${e.message}', name: 'POST_DETAIL');
      _showSnackbar('댓글 작성 실패: ${e.message}');
    } catch (e) {
      log('🚨 [SUBMIT_ERROR] Unknown Exception: $e', name: 'POST_DETAIL');
      _showSnackbar('댓글 작성 중 오류 발생');
    }
  }

  // ⭐️ [수정] 게시글 삭제: PostService 사용
  Future<void> _deletePost() async {
    final confirmed = await _showConfirmDialog('게시글 삭제', '정말로 이 게시글을 삭제하시겠습니까?');
    if (!confirmed) return;

    try {
      // ⭐️ PostService 호출로 대체
      await _postService.deletePost(
        postId: _currentPost.id,
        category: _currentPost.category,
      );

      if (mounted) {
        _showSnackbar('게시글이 성공적으로 삭제되었습니다.');
        // 삭제 성공 시 게시판 목록으로 돌아감 (true를 반환하여 새로고침 유도)
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      log('🚨 [DELETE_ERROR] DioException: ${e.message}', name: 'POST_DETAIL');
      if (e.response?.statusCode == 403) {
        _showSnackbar('삭제 권한이 없습니다. 작성자만 삭제할 수 있습니다.');
      } else {
        _showSnackbar('게시글 삭제에 실패했습니다: ${e.message}');
      }
    } catch (e) {
      log('🚨 [DELETE_ERROR] Unknown Exception: $e', name: 'POST_DETAIL');
      _showSnackbar('게시글 삭제 중 알 수 없는 오류 발생');
    }
  }

  // ⭐️ [수정] 댓글 삭제: CommentService 사용
  void _deleteComment(Comment comment) async {
    final confirmed = await _showConfirmDialog('댓글 삭제', '정말로 이 댓글을 삭제하시겠습니까?');
    if (!confirmed) return;

    try {
      // ⭐️ CommentService 호출로 대체
      final success = await _commentService.deleteComment(
        comment.id,
        _currentUserId, // AuthManager에서 가져온 사용자 ID 사용
      );

      if (success) {
        _showSnackbar('댓글이 삭제되었습니다.');
        _fetchComments(); // 목록 새로고침
      } else {
        _showSnackbar('댓글 삭제에 실패했습니다. (서버 오류 또는 권한 없음)');
      }
    } on DioException catch (e) {
      log('🚨 [COMMENT_DELETE_ERROR] DioException: ${e.message}', name: 'POST_DETAIL');
      _showSnackbar('댓글 삭제 실패: ${e.message}');
    } catch (e) {
      log('🚨 [COMMENT_DELETE_ERROR] Unknown Exception: $e', name: 'POST_DETAIL');
      _showSnackbar('댓글 삭제 중 오류 발생');
    }
  }

  // --- 기존 헬퍼 함수 및 UI 로직 유지 ---

  void _startReply(String commentId, String author) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthor = author;
      _commentController.text = '@$author '; // 답글 대상 멘션
    });
    FocusScope.of(context).requestFocus(FocusNode()); // 키보드 포커스
  }

  void _resetReplyState() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthor = null;
    });
  }

  void _onEditPost() async {
    // 편집 페이지로 이동 후 복귀 시 수정 여부를 받음
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostEditPage(postToEdit: _currentPost),
      ),
    );

    // 수정 완료 시 (result가 true일 경우) 상세 정보를 새로고침합니다.
    if (result == true) {
      // 💡 [개선 필요] PostService에 상세 정보를 다시 불러오는 기능이 없으므로,
      // 현재는 수정된 내용(content)이 포함된 _currentPost 객체를 업데이트한다고 가정합니다.
      // 실제로는 서버에서 상세 정보를 다시 받아와야 완전하지만, 현재는 UI만 업데이트합니다.

      // 임시로 content만 업데이트하고 댓글 목록 새로고침
      // (PostEditPage에서 수정된 Post 객체를 반환하도록 개선하는 것이 이상적입니다.)
      // 하지만 현재는 Pop(true)만 하므로, API에서 다시 목록을 불러오는 방식으로 대체하거나,
      // 여기서는 단순히 content만 임시로 업데이트합니다.
      setState(() {
        // 실제 앱에서는 _postService.fetchPostDetail(_currentPost.id)와 같은 API를 호출하여 최신 데이터를 가져와야 합니다.
        // 현재는 PostEditPage에서 pop(true)만 하므로, 목록 페이지로 돌아가 새로고침하도록 유도합니다.
      });
      _showSnackbar('게시글 수정이 완료되었습니다. (데이터 갱신을 위해 목록 페이지에서 돌아옴)');
      Navigator.pop(context, true); // 목록 페이지로 돌아가 새로고침하도록 유도
    }
  }

  // SnackBar 헬퍼 함수
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

  // Custom Confirmation Dialog (alert 대신 사용)
  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // ... (기존 _buildPerformanceCard 함수는 그대로 유지) ...
  Widget _buildPerformanceCard() {
    final post = _currentPost;

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
  Widget build(BuildContext context) {
    // 💡 [개선] 현재 로그인된 사용자가 작성자인지 확인
    final isAuthor = _currentPost.authorId == _currentUserId;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Text(
          _currentPost.category == 'review' ? '리뷰 상세' : '친구 찾기 상세',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // ⭐️ [변경] 수정/삭제 버튼을 Action으로 이동
        actions: [
          if (isAuthor)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _onEditPost,
            ),
          if (isAuthor)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deletePost, // ⭐️ [변경] PostService 사용
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 댓글 입력창 공간 확보
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 게시글 정보 카드
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPost.title,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Text('작성자: ${_currentPost.author}'),
                            const Spacer(),
                            Text(_currentPost.date.toLocal().toString().split(' ')[0]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.remove_red_eye, size: 16),
                                const SizedBox(width: 4),
                                Text('${_currentPost.views}'),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                const Icon(Icons.thumb_up, size: 16),
                                const SizedBox(width: 4),
                                Text('${_currentPost.likes}'),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        // 본문 내용
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _currentPost.content,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 공연 상세 링크
                _buildPerformanceCard(),
                const SizedBox(height: 16),

                // 댓글 섹션
                Text('댓글 (${_comments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _isLoadingComments
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCommentList(),
              ],
            ),
          ),

          // 댓글 입력창 (Positioned)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCommentInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    // 부모 댓글과 답글 분리
    final parentComments = _comments.where((c) => c.parentId == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parentComments.map((parentComment) {
        final replies = _comments.where((c) => c.parentId == parentComment.id).toList();
        return _buildCommentItem(parentComment, replies);
      }).toList(),
    );
  }

  Widget _buildCommentItem(Comment comment, List<Comment> replies) {
    // 💡 [개선] 댓글의 작성자 ID와 현재 사용자 ID를 대조
    final isCommentAuthor = comment.authorId == _currentUserId;

    return Padding(
      padding: EdgeInsets.only(left: comment.parentId != null ? 30.0 : 0.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comment.author,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        comment.date.toLocal().toString().split(' ')[0],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.text, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 답글 버튼
                      GestureDetector(
                        onTap: () => _startReply(comment.id, comment.author),
                        child: const Text('답글', style: TextStyle(color: Colors.blue, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      // 삭제 버튼 (작성자에게만 표시)
                      if (isCommentAuthor)
                        GestureDetector(
                          onTap: () => _deleteComment(comment), // ⭐️ [변경] CommentService 사용
                          child: const Text('삭제', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 답글 리스트
          if (replies.isNotEmpty)
            ...replies.map((reply) => _buildCommentItem(reply, [])).toList(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12, width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingToCommentId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  Text('답글 작성: @$_replyingToAuthor', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _resetReplyState,
                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitComment, // ⭐️ [변경] CommentService 사용
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}