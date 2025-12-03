// lib/src/features/community/data/post_model.dart

class Post {
  final String id;
  final String category; // 'review' 또는 'matching'
  final String title;
  final String content;
  final String author;
  final String authorId; // ⭐ 작성자 고유 ID 필드
  final String region;
  final String genre;
  final int views;
  final int likes;
  final DateTime date;

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
    required this.authorId, // ⭐ 생성자 업데이트
    required this.region,
    required this.genre,
    required this.views,
    required this.likes,
    required this.date,
    this.performanceId,
    this.performanceTitle,
    this.performanceUrl,
  });

  // 💡 [API 응답 처리]
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
      likes: json['likes'] as int? ?? 0,

      performanceId: json['performanceId'] as String?,
      performanceTitle: json['performanceTitle'] as String?,
    );
  }
}

// ==========================================
// ⭐️ 이 Performance 클래스가 PostService에 필요합니다!
// ==========================================
class Performance {
  final String id; // API에서 받은 고유 ID (e.g., "performance:308250")
  final String idxName; // 장르 접두사 (e.g., "performance", "festival")
  final String contentId; // 고유 번호 (e.g., "308250")
  final String title; // 공연 제목

  Performance({
    required this.id,
    required this.idxName,
    required this.contentId,
    required this.title,
  });
}