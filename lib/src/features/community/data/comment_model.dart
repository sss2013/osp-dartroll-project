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
  final List<String> likeUserIds; // ⭐ [신규] 좋아요를 누른 유저 ID 목록 (서버의 like[] 필드)

  // ⭐ [신규 추가] 신고 관련 필드
  final int reportedCount; // 서버에서 받은 신고 누적 횟수 (필드명 repoteCount 반영)
  final bool reported; // 현재 유저가 이 댓글을 신고했는지 여부 (필드명 reported 반영)

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
    this.likeUserIds = const [], // ⭐ [신규] 기본값 추가

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
    'likeUserIds': likeUserIds, // ⭐ [신규] likeUserIds도 반영

    // ⭐ [신규 추가] toJson에도 반영
    'reportedCount': reportedCount,
    'reported': reported,

    // ✅ [추가] toJson에도 반영
    'replies': replies?.map((e) => e.toJson()).toList(),
  };


  factory Comment.fromJson(Map<String, dynamic> json) {
    final String userId = json['userId'] is String ? json['userId'] as String : 'unknown_user';
    final int parsedReportedCount = json['reportedCount'] as int? ?? 0;
    final bool parsedReported = json['reported'] as bool? ?? false;

    // 1. like[] 배열 파싱 및 String 리스트로 변환 (서버에서 받은 유저 ID 목록)
    final List<dynamic>? rawLikeList = json['like'] as List<dynamic>?;
    final List<String> likeIds = rawLikeList
        ?.map((id) => id.toString())
        .toList() ?? [];

    // 2. 좋아요 개수(likes) 계산
    final int calculatedLikes = likeIds.length;

    // ❌ 서버에서 명시적으로 제공하지 않는 필드 파싱 로직 제거
    // final int parsedLikes = json['likes'] as int? ?? 0;
    // final bool parsedLiked = json['liked'] as bool? ?? false;


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

      // ⭐ [수정] 계산된 값 적용
      likes: calculatedLikes,
      liked: false, // PostDetailPage에서 현재 유저 ID를 이용해 덮어쓸 값입니다. 임시로 false 설정.
      likeUserIds: likeIds, // ⭐ [신규] 파싱된 유저 ID 목록 저장

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
    List<String>? likeUserIds, // ⭐ 추가
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
      likeUserIds: likeUserIds ?? this.likeUserIds, // ⭐ likeUserIds도 복사

      reportedCount: reportedCount ?? this.reportedCount,
      reported: reported ?? this.reported,
      replies: replies ?? this.replies,
    );
  }
}