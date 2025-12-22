// lib/src/features/community/data/comment_model.dart

import 'dart:convert';

// 💡 서버 응답 필드에 맞춘 댓글 모델
class Comment {
  final String id; // DB의 _id
  final String postId;
  final String userId;
  final String text;
  final String? parentId; // 답글 기능을 위한 부모 댓글 ID
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 💡 닉네임 필드
  final String authorNickname;

  // ⭐ [수정/보강] 좋아요 관련 필드
  final int likes; // 총 좋아요 개수 (likeUserIds.length로 계산)
  final bool liked; // 현재 유저의 좋아요 여부 (PostDetailPage에서 계산하여 덮어쓸 값)

  // ⭐ [신규 추가] 신고 관련 필드
  final int reportedCount;
  final bool reported;

  // ✅ 답글 리스트 필드
  final List<Comment>? replies;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.text,
    this.parentId,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.authorNickname,

    // ⭐ [수정] 기본값 명시: fromJson에서 계산값을 넘겨주므로 기본값은 유지합니다.
    this.likes = 0,
    this.liked = false,

    // ⭐ [신규 추가] 생성자에도 반영
    this.reportedCount = 0,
    this.reported = false,

    // ✅ [추가] 생성자에 반영
    this.replies,
  });

  Map<String, dynamic> toJson() => {
    '_id': id,
    'postId': postId,
    'userId': userId,
    'text': text,
    'parentId': parentId,
    'isDeleted': isDeleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'authorNickname': authorNickname,

    // ⭐ [추가] toJson에도 반영
    'likes': likes,
    'liked': liked,

    // ⭐ [신규 추가] toJson에도 반영
    'reportedCount': reportedCount,
    'reported': reported,

    // ✅ [추가] toJson에도 반영
    'replies': replies?.map((e) => e.toJson()).toList(),
  };


  factory Comment.fromJson(Map<String, dynamic> json) {
    final String userId = json['userId'] is String ? json['userId'] as String : 'unknown_user';
    final int parsedLikes = json['likeCount'] as int? ?? 0;
    final int parsedReportedCount = json['reportedCount'] as int? ?? 0;
    final bool parsedReported = json['reported'] as bool? ?? false;
    final String actualAuthorNickname = json['authorNickname'] as String? ?? '익명 사용자';

    return Comment(
      id: json['_id'] as String,
      postId: json['postId'] as String,
      userId: userId,
      text: json['text'] as String,
      parentId: json['parentId'] as String?,
      isDeleted: json['isDeleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),

      // ⚠️ 닉네임은 userId를 이용해 임시 데이터로 처리
      authorNickname: actualAuthorNickname,

      // ⭐ [수정] 계산된 값 적용
      likes: parsedLikes,
      liked: false, // PostDetailPage에서 현재 유저 ID를 이용해 덮어쓸 값입니다. 임시로 false 설정.

      // ⭐ [신규 추가] 파싱된 값 적용
      reportedCount: parsedReportedCount,
      reported: parsedReported,

      // ✅ 답글 리스트
      replies: null,
    );
  }

  // ⭐ [신규 추가] 특정 필드만 업데이트할 때 사용하는 메서드 (특히 liked 상태)
  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? text,
    String? parentId,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorNickname,
    int? likes,
    bool? liked,
    int? reportedCount,
    bool? reported,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      parentId: parentId ?? this.parentId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorNickname: authorNickname ?? this.authorNickname,

      // ⭐ 좋아요 관련 필드
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,

      reportedCount: reportedCount ?? this.reportedCount,
      reported: reported ?? this.reported,
      replies: replies ?? this.replies,
    );
  }
}