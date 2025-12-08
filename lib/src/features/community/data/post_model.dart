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
  // isLiked 필드 제거됨

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

    // 1. 좋아요 개수 (likes): 배열의 길이
    final int calculatedLikes = likeListDynamic.length;

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
      // isLiked 필드 제거됨

      performanceId: json['performanceId'] as String?,
      performanceTitle: json['performanceTitle'] as String?,
    );
  }
}