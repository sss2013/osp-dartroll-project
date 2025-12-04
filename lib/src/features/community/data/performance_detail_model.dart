// lib/src/features/community/data/performance_detail_model.dart

class PerformanceDetail {
  final String? area;
  final String? div; // 상세 내용 (Content Snippet으로 사용 예정)
  final String? place;
  final String? startDate;
  final String? sigungu;
  final String? gpsY;
  final String? gpsX;
  final String? imgUrl; // 썸네일 이미지 URL
  final String? placeUrl; // 공연장 정보 링크
  final String? url; // 공연 정보 링크 (탭 시 새 창 열기용)
  final String? price;
  final String? title;
  final String? phone;
  final String? endDate;
  final String? genre;
  final String? placeAddr; // 지역/위치

  PerformanceDetail({
    this.area,
    this.div,
    this.place,
    this.startDate,
    this.sigungu,
    this.gpsY,
    this.gpsX,
    this.imgUrl,
    this.placeUrl,
    this.url,
    this.price,
    this.title,
    this.phone,
    this.endDate,
    this.genre,
    this.placeAddr,
  });

  // JSON Map을 Dart 객체로 변환하는 팩토리 생성자
  factory PerformanceDetail.fromJson(Map<String, dynamic> json) {
    // 모든 필드를 String? 으로 안전하게 변환하여 사용합니다.
    return PerformanceDetail(
      area: json['area']?.toString(),
      div: json['div']?.toString(),
      place: json['place']?.toString(),
      startDate: json['startDate']?.toString(),
      sigungu: json['sigungu']?.toString(),
      gpsY: json['gpsY']?.toString(),
      gpsX: json['gpsX']?.toString(),
      imgUrl: json['imgUrl']?.toString(),
      placeUrl: json['placeUrl']?.toString(),
      url: json['url']?.toString(),
      price: json['price']?.toString(),
      title: json['title']?.toString(),
      phone: json['phone']?.toString(),
      endDate: json['endDate']?.toString(),
      genre: json['genre']?.toString(),
      placeAddr: json['placeAddr']?.toString(),
    );
  }
}