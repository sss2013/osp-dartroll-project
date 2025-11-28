import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cultureyo/src/features/community/presentation/pages/board_page.dart';
import 'package:cultureyo/src/features/community/presentation/pages/chat_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';



/// ----------------
/// MainScreen (탭 관리)
/// ----------------
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    ChatPage(),
    BoardPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.white.withOpacity(0.0),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.lightBlue,
              unselectedItemColor: Colors.grey[600],
              currentIndex: _selectedIndex,
              elevation: 0,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message_outlined),
                  activeIcon: Icon(Icons.message),
                  label: '채팅',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article_outlined),
                  activeIcon: Icon(Icons.article),
                  label: '게시판',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: '내 정보',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/// ----------------
/// HomePage (이미지 포함 리스트 스타일 및 정렬 개선)
/// ----------------
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 추천 이벤트 3개 목록 (더미 데이터)
  List<Map<String, String>> upcomingEvents = [
    {"title": "2025 서울 불꽃 축제", "location": "여의도 한강공원", "date": "2025.10.10 ~ 2025.10.10"},
    {"title": "겨울 빛 축제", "location": "에버랜드", "date": "2025.12.01 ~ 2026.02.28"},
    {"title": "전국 푸드 페스티벌", "location": "코엑스", "date": "2025.11.20 ~ 2025.11.24"},
  ];
  bool isLoading = false;
  String? loadError;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    // 최대 너비를 600.0으로 설정하고 중앙 정렬 유지
    final cardMaxWidth = mq.width > 600 ? 600.0 : mq.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "컬쳐요",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 15),
                // 검색 버튼 (Padding 16.0 통일)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegionSelectPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("공연/행사 지역별 검색",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 25),

                // 제목 (Padding 16.0 통일)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "🔥 인기 이벤트",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                if (isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Colors.lightBlue),
                  )),

                if (!isLoading && loadError != null)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("❌ 이벤트 로드 오류", style: TextStyle(color: Colors.red)),
                  )),

                // 추천 이벤트 3개 표시 (이미지+텍스트 리스트 스타일 적용)
                if (!isLoading && loadError == null && upcomingEvents.isNotEmpty)
                  ...upcomingEvents.take(3).map((event) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _eventBox(
                          title: event['title']!,
                          location: event['location']!,
                          date: event['date']!,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  )).toList(),

                if (!isLoading && loadError == null && upcomingEvents.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("🎉 현재 예정된 공연/행사가 없습니다.", style: TextStyle(color: Colors.grey[600])),
                  )),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // RegionSelectPage의 _eventCard와 유사하게 이미지/텍스트가 정렬된 리스트 스타일로 변경
  Widget _eventBox({required String title, required String location, required String date}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("지역 검색 페이지를 이용해 주세요.")),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 썸네일 이미지 영역 (더미 아이콘 사용)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.lightBlue.withOpacity(0.1),
                  child: Icon(Icons.celebration, color: Colors.lightBlue, size: 30),
                ),
              ),
              const SizedBox(width: 12),

              // 텍스트 정보 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(location, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(date, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
/// ----------------
/// RegionSelectPage
/// ----------------
class RegionSelectPage extends StatefulWidget {
  @override
  _RegionSelectPageState createState() => _RegionSelectPageState();
}

class _RegionSelectPageState extends State<RegionSelectPage> {
  String? selectedRegion;
  String? selectedGenre;

  List<Event> eventList = [];
  bool isLoading = false;
  String? lastErrorMessage;

  final List<String> regions = [
    '강원', '경기', '경남', '경북', '광주', '대구', '대전', '부산', '서울', '세종', '울산', '인천', '지역 미정'
  ];

  final List<String> genres = [
    '국악', '기타', '무용/발레', '뮤지컬/오페라', '연극', '음악/콘서트', '전시'
  ];

  Future<void> _loadEvents() async {
    if (selectedRegion == null || selectedGenre == null) {
      return;
    }

    setState(() {
      isLoading = true;
      lastErrorMessage = null;
      eventList = [];
    });

    try {
      final list = await EventApiService.postGetEvents(
        area: selectedRegion!,
        genre: selectedGenre!,
      );

      setState(() {
        eventList = list;
      });
    } catch (e) {
      setState(() {
        lastErrorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _dropdownContainer({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(label),
          icon: const Icon(Icons.arrow_drop_down),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _eventCard(Event e) {
    return GestureDetector(
      onTap: () async {
        final parts = e.id.split(':');
        final contentId = parts.length > 1 ? parts[1] : e.id;

        EventDetail? detail;
        try {
          detail = await EventApiService.postGetEventDetail(contentId: contentId);
        } catch (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("상세 정보를 불러오지 못했습니다.")),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailPage(detail: detail!),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: e.thumbnail.isNotEmpty
                    ? Image.network(
                  e.thumbnail,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported),
                  ),
                )
                    : Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text(e.place, style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 4),
                    Text("${e.startDate} ~ ${e.endDate}", style: TextStyle(color: Colors.black45)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("공연/행사 검색", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            children: [
              SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _dropdownContainer(
                      label: "지역",
                      value: selectedRegion,
                      items: regions,
                      onChanged: (v) {
                        setState(() => selectedRegion = v);
                        _loadEvents();
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _dropdownContainer(
                      label: "장르",
                      value: selectedGenre,
                      items: genres,
                      onChanged: (v) {
                        setState(() => selectedGenre = v);
                        _loadEvents();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),

              if (isLoading) ...[
                const Center(child: CircularProgressIndicator()),
                SizedBox(height: 12),
              ],

              if (!isLoading && lastErrorMessage != null) ...[
                Text("오류 발생: $lastErrorMessage", style: TextStyle(color: Colors.red)),
                SizedBox(height: 8),
              ],

              if (!isLoading && selectedRegion == null || selectedGenre == null)
                Column(
                  children: [
                    SizedBox(height: 40),
                    Icon(Icons.info_outline, size: 48, color: Colors.lightBlue[400]),
                    SizedBox(height: 8),
                    Text("지역과 장르를 선택해주세요.", style: TextStyle(color: Colors.black54)),
                  ],
                ),

              if (!isLoading && eventList.isEmpty && selectedRegion != null && selectedGenre != null && lastErrorMessage == null)
                Column(
                  children: [
                    SizedBox(height: 40),
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text("조건에 맞는 공연이 없습니다.", style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 12),
                    Text("다른 조건으로 검색해보세요.", style: TextStyle(color: Colors.black38)),
                  ],
                ),

              if (!isLoading && eventList.isNotEmpty)
                Column(children: eventList.map((e) => _eventCard(e)).toList()),
            ],
          ),
        ),
      ),
    );
  }
}
/// ----------------
/// Models & API Service (POST JSON)
/// ----------------
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
  static const String baseUrl = "https://dartroll-nodejs.onrender.com";

  /// POST /api/getEvent
  static Future<List<Event>> postGetEvents({
    required String area,
    required String genre,
  }) async {
    final uri = Uri.parse("$baseUrl/api/getEvent");
    final body = {
      "idxName": "performance",
      "area": area,
      "genre": genre,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("서버 응답 에러: ${res.statusCode}");
    }

    final decodedBody = jsonDecode(res.body);

    if (decodedBody is Map<String, dynamic>) {
      final dynamic rawData = decodedBody['results'];

      if (rawData is List) {
        final events = rawData.map<Event>((e) {
          if (e is Map<String, dynamic>) return Event.fromJson(e);
          return Event.fromJson(Map<String, dynamic>.from(e));
        }).toList();

        return events;
      } else {
        return [];
      }
    }
    else if (decodedBody is List) {
      return decodedBody.map<Event>((e) => Event.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return [];
  }

  /// POST /api/getEventDetail
  static Future<EventDetail> postGetEventDetail({
    required String contentId,
  }) async {
    final uri = Uri.parse("$baseUrl/api/getEventDetail");
    final body = {
      "idxName": "performance",
      "contentId": contentId,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("서버 응답 에러: ${res.statusCode}");
    }

    final decodedBody = jsonDecode(res.body);

    if (decodedBody is Map<String, dynamic>) {
      final dynamic rawDetailData = decodedBody['detail'] ?? decodedBody['data'];

      if (rawDetailData is Map<String, dynamic>) {
        return EventDetail.fromJson(rawDetailData);
      }

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

/// EventDetailPage

class EventDetailPage extends StatelessWidget {
  final EventDetail detail;

  EventDetailPage({super.key, required this.detail});

  String _formatDate(String raw) {
    if (raw.isEmpty) return '정보 없음';

    raw = raw.replaceAll('-', '');

    if (raw.length != 8) return raw;

    final y = raw.substring(0, 4);
    final m = raw.substring(4, 6);
    final d = raw.substring(6, 8);

    return "$y년 $m월 $d일";
  }


  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  String _checkValue(String value) {
    return value.isEmpty ? '정보 없음' : value;
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.lightBlue, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 4),
              SizedBox(
                width: 250,
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _linkRow({required String label, required String url}) {
    if (url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () async {
          try {
            await _launchUrl(url);
          } catch (e) {}
        },
        child: Text(
          '• $label',
          style: const TextStyle(
            color: Colors.lightBlue,
            decoration: TextDecoration.underline,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double lat = double.tryParse(detail.gpsY) ?? 0.0;
    final double lng = double.tryParse(detail.gpsX) ?? 0.0;
    final bool hasValidLocation = lat != 0.0 && lng != 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:
        Text(_checkValue(detail.title), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 이미지
                  if (detail.imgUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        detail.imgUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// 제목
                  Text(
                    _checkValue(detail.title),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const Divider(height: 30),

                  /// 기본 정보
                  _detailRow(
                    icon: Icons.calendar_month,
                    label: "기간",
                    value: "${_formatDate(detail.startDate)} ~ ${_formatDate(detail.endDate)}",
                  ),

                  _detailRow(
                    icon: Icons.place,
                    label: "장소",
                    value: _checkValue(detail.place),
                  ),
                  _detailRow(
                    icon: Icons.location_on,
                    label: "주소",
                    value: _checkValue(detail.placeAddr),
                  ),

                  const Divider(height: 30),

                  /// ✅ 추가 정보
                  _detailRow(
                    icon: Icons.category,
                    label: "장르",
                    value: _checkValue(detail.genre),
                  ),
                  _detailRow(
                    icon: Icons.monetization_on,
                    label: "가격",
                    value: _checkValue(detail.price),
                  ),
                  _detailRow(
                    icon: Icons.phone,
                    label: "연락처",
                    value: _checkValue(detail.phone),
                  ),

                  const Divider(height: 30),

                  /// URL
                  const Text(
                    "상세 정보 링크",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _linkRow(label: '주최측 URL 바로가기', url: detail.url),
                  _linkRow(label: '장소 URL 바로가기', url: detail.placeUrl),

                  const Divider(height: 30),

                  /// 지도
                  const Text(
                    "행사 위치 지도",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (hasValidLocation)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(lat, lng),
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              userAgentPackageName: 'com.cultureyo.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(lat, lng),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "위치 정보가 제공되지 않은 행사입니다.",
                          style:
                          TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("계정"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _accountItem("사용자명", "홍길동"),
            _accountItem("이메일", "example@email.com"),
            _accountItem("휴대폰", "010-1234-5678"),

            SizedBox(height: 10),
            Divider(),

            ListTile(
              title: Text("비밀번호 변경"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),

            ListTile(
              title: Text("계정 삭제하기",
                  style: TextStyle(color: Colors.red)),
              trailing: Icon(Icons.delete, color: Colors.red),
              onTap: () {},
            ),

            Spacer(),

            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "로그아웃",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _accountItem(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
      ],
    ),
  );
}

/// ProfilePage
/// ----------------
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "내 정보",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.lightBlue,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            SizedBox(height: 15),
            Text(
              "홍길동",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("test@test.com", style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 30),
            _settingCard(
              icon: Icons.settings,
              title: "계정",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AccountPage()),
                );
              },
            ),

            SizedBox(height: 10),
            _settingCard(
              icon: Icons.notifications,
              title: "알림 설정",
              onTap: () {},
            ),
            SizedBox(height: 10),
            _settingCard(
              icon: Icons.color_lens,
              title: "테마 변경",
              onTap: () {},
            ),
            SizedBox(height: 10),
            _settingCard(
              icon: Icons.security,
              title: "개인정보 보호",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.lightBlue),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
