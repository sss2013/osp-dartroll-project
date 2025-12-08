import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    return Event(
      id: json['id']?.toString() ?? '',
      area: json['area'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      title: json['title'] ?? '',
      place: json['place'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      sigungu: json['sigungu'] ?? '',
    );
  }
}

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
    return EventDetail(
      area: json['area'] ?? '',
      div: json['div'] ?? '',
      place: json['place'] ?? '',
      startDate: json['startDate'] ?? '',
      sigungu: json['sigungu'] ?? '',
      gpsY: json['gpsY']?.toString() ?? '',
      gpsX: json['gpsX']?.toString() ?? '',
      imgUrl: json['imgUrl'] ?? '',
      placeUrl: json['placeUrl'] ?? '',
      url: json['url'] ?? '',
      price: json['price'] ?? '',
      title: json['title'] ?? '',
      phone: json['phone'] ?? '',
      endDate: json['endDate'] ?? '',
      genre: json['genre'] ?? '',
      placeAddr: json['placeAddr'] ?? '',
    );
  }
}

class EventApiService {
  static String baseUrl = dotenv.env['API_URL'] ?? "https://dartroll-nodejs.onrender.com";
  
  static Future<List<Event>> postGetEvents({required String area, required String genre}) async {
    final uri = Uri.parse("$baseUrl/api/getEvent");
    
    String idxName = "performance";
    String apiGenre = genre;

    if (genre == "행사/축제") {
      idxName = "festival";
    } else if (genre == "교육/체험") {
      idxName = "experience";
    }

    final body = {
      "idxName": idxName,
      "area": area,
      "genre": apiGenre
    };

    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (res.statusCode != 200) throw Exception("서버 응답 에러: ${res.statusCode}");

    final decodedBody = jsonDecode(res.body);

    if (decodedBody is Map<String, dynamic>) {
      final dynamic rawData = decodedBody['results'];
      if (rawData is List) {
        return rawData.map<Event>((e) {
          if (e is Map<String, dynamic>) return Event.fromJson(e);
          return Event.fromJson(Map<String, dynamic>.from(e));
        }).toList();
      } else {
        return [];
      }
    } else if (decodedBody is List) {
      return decodedBody.map<Event>((e) => Event.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }
  
  static Future<EventDetail> postGetEventDetail({required String contentId, String idxName = "performance"}) async {
    final uri = Uri.parse("$baseUrl/api/getEventDetail");

    final body = {
      "idxName": idxName,
      "contentId": contentId
    };

    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (res.statusCode != 200) throw Exception("서버 응답 에러: ${res.statusCode}");

    final decodedBody = jsonDecode(res.body);

    if (decodedBody is Map<String, dynamic>) {
      final dynamic rawDetailData = decodedBody['detail'] ?? decodedBody['data'];
      if (rawDetailData is Map<String, dynamic>) return EventDetail.fromJson(rawDetailData);
      try {
        return EventDetail.fromJson(decodedBody);
      } catch (e) {
        throw Exception("상세 정보 파싱 실패: 서버 응답 구조 확인 필요");
      }
    } else {
      throw Exception("상세 응답 형식 오류: 응답이 Map 형태가 아닙니다.");
    }
  }
}
