// lib/src/features/community/data/post_model.dart

class Post {
  final String id;
  final String category; // 'review' 또는 'matching'
  final String title;
  final String content;
  final String author;
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
  // category(tap)는 API 응답에 포함되지 않을 수 있으므로,
  // 호출 시점에 주입받거나(optional) 기본값을 사용합니다.
  factory Post.fromApiJson(Map<String, dynamic> json, {String? category}) {

    // 1. 고유 ID: "_id" 사용
    final String postId = json['_id']?.toString() ?? 'unknown_id';

    // 2. 날짜 파싱: "createdAt" 사용
    DateTime postDate;
    final dateString = json['createdAt'] as String?;
    try {
      postDate = (dateString != null && dateString.isNotEmpty)
          ? DateTime.parse(dateString)
          : DateTime.now();
    } catch (e) {
      postDate = DateTime.now();
    }

    // 3. 카테고리: 인자로 받은 category가 있으면 최우선 사용, 없으면 json['tap'], 없으면 기본값
    final String finalCategory = category ?? json['tap'] as String? ?? 'review';

    return Post(
      id: postId,
      category: finalCategory,

      // API 응답 필드 매핑
      title: json['title'] as String? ?? '제목 없음',
      content: json['content'] as String? ?? '',
      region: json['area'] as String? ?? '지역 미정', // API의 'area'를 'region'으로 매핑
      genre: json['genre'] as String? ?? '장르 미정',
      performanceUrl: json['url'] as String?,
      date: postDate,

      // 💡 [임의 채움] 디자인 유지를 위한 더미 데이터
      author: json['author'] as String? ?? '익명',
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,

      performanceId: json['performanceId'] as String?,
      performanceTitle: json['performanceTitle'] as String?,
    );
  }
}