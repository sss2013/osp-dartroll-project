// lib/src/features/community/data/post_model.dart

class Post {
  final String id;
  final String category; // 'review' 또는 'matching'
  final String title;
  final String content;
  final String author;
  final String authorId;
  final String region;
  final String genre;
  final int views;
  final int likes;
  final DateTime date;

  // ⭐ [신고 기능 추가]
  final bool reported;
  final int reporteCount;

  // 공연 정보 확장 필드
  final String? performanceId;
  final String? performanceTitle;
  final String? performanceUrl;

  Post({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.author,
    required this.authorId,
    required this.region,
    required this.genre,
    required this.views,
    required this.likes,
    required this.date,
    // ⭐ [신고 필드 필수]
    required this.reported,
    required this.reporteCount,
    this.performanceId,
    this.performanceTitle,
    this.performanceUrl,
  });

  factory Post.fromApiJson(Map<String, dynamic> json, {String? category}) {

    final String postId = json['_id']?.toString() ?? 'unknown_id';

    DateTime postDate;
    final dateString = json['createdAt'] as String?;
    try {
      postDate = (dateString != null && dateString.isNotEmpty)
          ? DateTime.parse(dateString)
          : DateTime.now();
    } catch (e) {
      postDate = DateTime.now();
    }

    final String finalCategory = category ?? json['tap'] as String? ?? 'review';
    final String extractedAuthorId = json['userId'] as String? ?? 'unknown_user';

    // ⭐ [핵심 로직] 좋아요 배열 처리 및 개수만 계산
    final List<dynamic> likeListDynamic = json['like'] is List ? json['like'] as List<dynamic> : [];
    final int calculatedLikes = likeListDynamic.length;

    // ⭐ [신규 로직] 신고 관련 필드 파싱
    final bool isReported = json['reported'] as bool? ?? false;
    final int calculatedReporteCount = json['reporteCount'] as int? ?? 0;

    return Post(
      id: postId,
      category: finalCategory,

      title: json['title'] as String? ?? '제목 없음',
      content: json['content'] as String? ?? '',
      region: json['area'] as String? ?? '지역 미정',
      genre: json['genre'] as String? ?? '장르 미정',
      performanceUrl: json['url'] as String?,
      date: postDate,

      authorId: extractedAuthorId,

      author: json['author'] as String? ?? '익명',
      views: json['views'] as int? ?? 0,

      likes: calculatedLikes,

      // ⭐ [파싱 반영] 신고 필드 반영
      reported: isReported,
      reporteCount: calculatedReporteCount,

      performanceId: json['performanceId'] as String?,
      performanceTitle: json['performanceTitle'] as String?,
    );
  }
}

/// 게시글 신고 API 응답 모델
class PostReportStatus {
  final bool reported;
  final int reporteCount;

  PostReportStatus({
    required this.reported,
    required this.reporteCount,
  });

  factory PostReportStatus.fromJson(Map<String, dynamic> json) {
    return PostReportStatus(
      reported: json['reported'] as bool? ?? false,
      reporteCount: json['reporteCount'] as int? ?? 0,
    );
  }
}