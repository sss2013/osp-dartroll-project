import 'package:html_unescape/html_unescape.dart';

class Event {
  final String id;
  final String area;
  final String startDate;
  final String endDate;
  final String title;
  final String place;
  final String thumbnail;
  final String sigungu;

  Event({
    required this.id,
    required this.area,
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.place,
    required this.thumbnail,
    required this.sigungu,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final unescape = HtmlUnescape();
    return Event(
      id: json['id']?.toString() ?? '',
      area: json['area'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      title: unescape.convert(json['title'] ?? ''),
      place: unescape.convert(json['place'] ?? ''),
      thumbnail: json['thumbnail'] ?? '',
      sigungu: json['sigungu'] ?? '',
    );
  }
}