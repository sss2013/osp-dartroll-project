class Post {
  final String id; // String 타입
  final String category;
  final String title;
  final String content;
  final String author;
  final String region;
  final String subRegion;
  final String genre;
  final int views;
  final int likes;
  final DateTime date;

  Post({
    required this.id, // String
    required this.category,
    required this.title,
    required this.content,
    required this.author,
    required this.region,
    required this.subRegion,
    required this.genre,
    required this.views,
    required this.likes,
    required this.date,
  });
}