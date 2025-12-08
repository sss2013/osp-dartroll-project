// lib/src/features/community/data/comment_model.dart

import 'dart:convert';
// Post 모델은 여기서 필요 없지만, PostDetail 모델이 생기면 필요할 수 있음.

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
  final int likes;
  final int replies;

  // ⭐ [신규 추가] 신고 관련 필드
  final int repoteCount; // 서버에서 받은 신고 누적 횟수 (필드명 repoteCount 반영)
  final bool repoted; // 현재 유저가 이 댓글을 신고했는지 여부 (필드명 repoted 반영)

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
    this.likes = 0,
    this.replies = 0,
    // ⭐ [신규 추가] 생성자에도 반영
    this.repoteCount = 0,
    this.repoted = false,
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
    'likes': likes,
    'replies': replies,
    // ⭐ [신규 추가] toJson에도 반영
    'repoteCount': repoteCount,
    'repoted': repoted,
  };


  factory Comment.fromJson(Map<String, dynamic> json) {
    // 💡 [안전 보강] userId 타입 체크 및 기본값 처리
    final String userId = json['userId'] is String ? json['userId'] as String : 'unknown_user';

    // ⭐ [신규 추가] 신고 필드 파싱 및 기본값 설정
    final int parsedReportCount = json['repoteCount'] as int? ?? 0;
    final bool parsedRepoted = json['repoted'] as bool? ?? false;


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
      likes: json['likes'] ?? 0,
      replies: json['replies'] ?? 0,

      // ⭐ [신규 추가] 파싱된 값 적용
      repoteCount: parsedReportCount,
      repoted: parsedRepoted,
    );
  }
}