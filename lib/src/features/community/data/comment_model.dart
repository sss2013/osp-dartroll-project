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

  // 💡 [추가] 닉네임 필드 (UI 표시를 위해 임시로 처리)
  final String authorNickname;

  // ⭐ [수정/보강] 좋아요 관련 필드
  final int likes; // 총 좋아요 개수 (API에서 likeCount)
  final bool liked; // 현재 유저의 좋아요 여부 (API에서 liked)

  // ⭐ [신규 추가] 신고 관련 필드
  final int reporteCount; // 서버에서 받은 신고 누적 횟수 (필드명 repoteCount 반영)
  final bool reported; // 현재 유저가 이 댓글을 신고했는지 여부 (필드명 reported 반영)

  // ✅ [수정] 답글 리스트 필드 추가
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

    // ⭐ [수정] 좋아요 필드 초기화
    this.likes = 0,
    this.liked = false,

    // ⭐ [신규 추가] 생성자에도 반영
    this.reporteCount = 0,
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
    'reporteCount': reporteCount,
    'reported': reported,

    // ✅ [추가] toJson에도 반영 (replies는 보통 서버에서 계산되므로 여기서는 null/빈 리스트)
    'replies': replies?.map((e) => e.toJson()).toList(),
  };


  factory Comment.fromJson(Map<String, dynamic> json) {
    final String userId = json['userId'] is String ? json['userId'] as String : 'unknown_user';
    final int parsedReportCount = json['reporteCount'] as int? ?? 0;
    final bool parsedReported = json['reported'] as bool? ?? false;
    final int parsedLikes = json['likes'] as int? ?? 0;
    final bool parsedLiked = json['liked'] as bool? ?? false;

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
      authorNickname: userId.length >= 4 ? '유저_${userId.substring(0, 4)}' : '시스템 유저',

      // ⭐ [신규 추가] 파싱된 값 적용
      likes: parsedLikes,
      liked: parsedLiked,

      // ⭐ [신규 추가] 파싱된 값 적용
      reporteCount: parsedReportCount,
      reported: parsedReported,

      // ✅ [수정 완료] 이제 Comment 모델에 replies 필드가 있으므로 컴파일 오류가 사라집니다.
      // 댓글 목록 API는 평탄화된 목록을 제공한다고 가정하고 일단 null로 초기화합니다.
      replies: null,

      // 만약 API가 계층형으로 답글 리스트를 제공한다면 아래 코드를 사용해야 합니다.
      /*
      replies: (json['replies'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
      */
    );
  }
}