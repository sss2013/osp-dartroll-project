// post_model.dart
class Post {
  final String id; // String 타입
  final String category;
  final String title;
  final String content;
  final String author;
  final String region;
  final String genre;
  final int views;
  final int likes;
  final DateTime date;

  // ▼▼▼▼▼ [추가된 필드] 공연 상세 카드 표시를 위한 데이터 ▼▼▼▼▼
  final String? performanceId;     // 예: 'performance:308250'
  final String? performanceTitle;  // 공연 제목
  final String? performanceUrl;    // 공연 링크 (예매 URL)
  // ▲▲▲▲▲ ▲▲▲▲▲

  Post({
    required this.id, // String
    required this.category,
    required this.title,
    required this.content,
    required this.author,
    required this.region,
    required this.genre,
    required this.views,
    required this.likes,
    required this.date,

    // ▼▼▼▼▼ [추가된 필드] 초기화 ▼▼▼▼▼
    this.performanceId,
    this.performanceTitle,
    this.performanceUrl,
    // ▲▲▲▲▲ ▲▲▲▲▲
  });
}