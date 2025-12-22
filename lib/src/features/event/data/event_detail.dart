import 'package:html_unescape/html_unescape.dart';

class EventDetail {
  final String area;
  final String div;
  final String place;
  final String startDate;
  final String sigungu;
  final String gpsY;
  final String gpsX;
  final String imgUrl;
  final String placeUrl;
  final String url;
  final String price;
  final String title;
  final String phone;
  final String endDate;
  final String genre;
  final String placeAddr;

  EventDetail({
    required this.area,
    required this.div,
    required this.place,
    required this.startDate,
    required this.sigungu,
    required this.gpsY,
    required this.gpsX,
    required this.imgUrl,
    required this.placeUrl,
    required this.url,
    required this.price,
    required this.title,
    required this.phone,
    required this.endDate,
    required this.genre,
    required this.placeAddr,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    final unescape = HtmlUnescape();
    return EventDetail(
      area: unescape.convert(json['area'] ?? ''),
      div: unescape.convert(json['div'] ?? ''),
      place: unescape.convert(json['place'] ?? ''),
      startDate: json['startDate'] ?? '',
      sigungu: unescape.convert(json['sigungu'] ?? ''),
      gpsY: json['gpsY']?.toString() ?? '',
      gpsX: json['gpsX']?.toString() ?? '',
      imgUrl: json['imgUrl'] ?? '',
      placeUrl: json['placeUrl'] ?? '',
      url: json['url'] ?? '',
      price: unescape.convert(json['price'] ?? ''),
      title: unescape.convert(json['title'] ?? ''),
      phone: json['phone'] ?? '',
      endDate: json['endDate'] ?? '',
      genre: unescape.convert(json['genre'] ?? ''),
      placeAddr: unescape.convert(json['placeAddr'] ?? ''),
    );
  }
}