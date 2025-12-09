import 'package:cultureyo/src/features/event/data/event_detail.dart';
import 'package:cultureyo/src/features/event/service/event_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cultureyo/src/features/community/presentation/pages/board_page.dart';
import 'package:cultureyo/src/features/chat/presentation/chat_page.dart';
import 'event/data/event.dart';
import 'package:provider/provider.dart';
import 'my_info_page.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    BoardPage(),
    // ChatPage(),
    MyInfoPage(),
  ];

  final Color _primaryBlue = Colors.blue[200]!;
  final Color _secondaryBlue = Colors.blue[300]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              border: Border(
                top: BorderSide(
                    color: _primaryBlue.withOpacity(0.2), width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: _secondaryBlue,
              unselectedItemColor: Colors.grey[400],
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
                  activeIcon: Icon(Icons.article),
                  label: '게시판',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article_outlined),
                  activeIcon: Icon(Icons.message),
                  label: '채팅',
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Event> upcomingEvents = [];
  bool isLoading = false;
  String? loadError;
  late final eventService = context.read<EventService>();

  final Color _primaryBlue = Colors.blue[200]!;
  final Color _lightBlueBg = Colors.blue[50]!;

  @override
  void initState() {
    super.initState();
    _loadRandomEvents();
  }

  Future<void> _loadRandomEvents() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final allEvents =
      await eventService.postGetEvents(area: "서울", genre: "전시");
      allEvents.shuffle();
      setState(() {
        upcomingEvents = allEvents.take(3).toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loadError = "이벤트 로딩 실패";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _searchButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegionSelectPage()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined),
            SizedBox(width: 12),
            Text(
              "지역별 공연/행사 선택하러 가기",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery
        .of(context)
        .size;
    final cardMaxWidth = mq.width > 600 ? 600.0 : mq.width;

    return Scaffold(
      backgroundColor: _lightBlueBg,
      appBar: AppBar(
        title: const Text("컬쳐요",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _searchButton(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                            colors: [Colors.blue[100]!, Colors.blue[200]!]),
                      ),
                      child: const Center(
                          child: Text("광고 배너 영역",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold))),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("🔥 인기 이벤트",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                            child:
                            CircularProgressIndicator(color: _primaryBlue)))
                  else
                    if (loadError != null)
                      const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                              child: Text("❌ 이벤트 로드 오류",
                                  style: TextStyle(color: Colors.red))))
                    else
                      if (upcomingEvents.isNotEmpty)
                        ...upcomingEvents
                            .map((e) =>
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8),
                                child: _eventCardWidget(e)))
                            .toList()
                      else
                        const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                                child: Text("🎉 현재 예정된 공연/행사가 없습니다.",
                                    style: TextStyle(color: Colors.grey)))),

                  // ▼▼▼ 수정된 부분: 하단에 충분한 여백 추가 (네비게이션 바 높이 + 여유분) ▼▼▼
                  const SizedBox(height: 100),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _eventCardWidget(Event e) {
    return GestureDetector(
      onTap: () async {
        final parts = e.id.split(':');
        final contentId = parts.length > 1 ? parts[1] : e.id;
        String idxName = parts.length > 1 ? parts[0] : "performance";

        EventDetail? detail;
        try {
          detail = await eventService.postGetEventDetail(
              contentId: contentId, idxName: idxName);
        } catch (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("상세 정보를 불러오지 못했습니다.")));
          }
          return;
        }
        if (mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EventDetailPage(detail: detail!)));
        }
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.blue[100]!, width: 1),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: e.thumbnail.isNotEmpty
                    ? Image.network(
                  e.thumbnail,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[400]),
                      ),
                )
                    : Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported,
                      color: Colors.grey[400]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text(e.place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text("${e.startDate} ~ ${e.endDate}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.blue[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegionSelectPage extends StatefulWidget {
  const RegionSelectPage({super.key});

  @override
  _RegionSelectPageState createState() => _RegionSelectPageState();
}

class _RegionSelectPageState extends State<RegionSelectPage> {
  String? selectedRegion;
  String? selectedGenre;
  List<Event> eventList = [];
  bool isLoading = false;
  String? lastErrorMessage;
  late final eventService = context.read<EventService>();

  final List<String> regions = ['강원', '경기', '경남', '경북', '광주', '대구', '대전', '부산', '서울', '세종', '울산', '인천', '지역 미정'];
  final List<String> genres = [
    '행사/축제', '교육/체험', '국악', '기타', '무용/발레', '뮤지컬/오페라', '연극', '음악/콘서트', '전시'
  ];

  final Color _primaryBlue = Colors.blue[200]!;
  final Color _secondaryBlue = Colors.blue[300]!;
  final Color _lightBlueBg = Colors.blue[50]!;

  Future<void> _loadEvents() async {
    if (selectedRegion == null || selectedGenre == null) return;
    setState(() {
      isLoading = true;
      lastErrorMessage = null;
      eventList = [];
    });
    try {
      final list = await eventService.postGetEvents(area: selectedRegion!, genre: selectedGenre!);
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

  Widget _dropdownContainer({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(Icons.arrow_drop_down, color: _primaryBlue),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                  e,
                  style: const TextStyle(color: Colors.black87, fontSize: 14)
              ),
            ),
          )).toList(),          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _eventCard(Event e) {
    return GestureDetector(
      onTap: () async {
        final parts = e.id.split(':');
        final contentId = parts.length > 1 ? parts[1] : e.id;
        String idxName = parts.length > 1 ? parts[0] : "performance";

        EventDetail? detail;
        try {
          detail = await eventService.postGetEventDetail(contentId: contentId, idxName: idxName);
        } catch (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("상세 정보를 불러오지 못했습니다.")));
          }
          return;
        }
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(detail: detail!)));
        }
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.blue[100]!, width: 1),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: e.thumbnail.isNotEmpty
                  ? Image.network(e.thumbnail, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400])))
                  : Container(width: 90, height: 90, color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400])),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(e.place, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text("${e.startDate} ~ ${e.endDate}", style: TextStyle(color: _secondaryBlue, fontSize: 12, fontWeight: FontWeight.w500))
            ]))
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBlueBg,
      appBar: AppBar(
        title: const Text("공연/행사 선택", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), child: Column(children: [
          Row(children: [
            Expanded(child: _dropdownContainer(label: "지역 선택", value: selectedRegion, items: regions, onChanged: (v) { setState(() => selectedRegion = v); _loadEvents(); })),
            const SizedBox(width: 16),
            Expanded(child: _dropdownContainer(label: "장르 선택", value: selectedGenre, items: genres, onChanged: (v) { setState(() => selectedGenre = v); _loadEvents(); })),
          ]),
          const SizedBox(height: 24),
          if (isLoading) ...[Center(child: CircularProgressIndicator(color: _primaryBlue)), const SizedBox(height: 12)],
          if (!isLoading && lastErrorMessage != null) ...[Text("오류 발생: $lastErrorMessage", style: const TextStyle(color: Colors.red)), const SizedBox(height: 8)],
          if ((!isLoading && (selectedRegion == null || selectedGenre == null))) Column(children: [const SizedBox(height: 60), Icon(Icons.touch_app_outlined, size: 60, color: _primaryBlue.withOpacity(0.5)), const SizedBox(height: 16), Text("지역과 장르를 선택해주세요.", style: TextStyle(color: Colors.grey[600], fontSize: 16))]),
          if (!isLoading && eventList.isEmpty && selectedRegion != null && selectedGenre != null && lastErrorMessage == null) Column(children: [const SizedBox(height: 60), Icon(Icons.event_busy_outlined, size: 60, color: Colors.grey[400]), const SizedBox(height: 16), Text("조건에 맞는 공연이 없습니다.", style: TextStyle(color: Colors.grey[600], fontSize: 16)), const SizedBox(height: 8), Text("다른 조건으로 선택해보세요.", style: TextStyle(color: Colors.grey[500]))]),
          if (!isLoading && eventList.isNotEmpty) Column(children: eventList.map((e) => _eventCard(e)).toList()),
        ])),
      ),
    );
  }
}


class EventDetailPage extends StatelessWidget {
  final EventDetail detail;
  final Color _primaryBlue = Colors.blue[200]!;
  final Color _secondaryBlue = Colors.blue[300]!;
  final Color _lightBlueBg = Colors.blue[50]!;

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
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw Exception('Could not launch $uri');
  }

  String _checkValue(String value) => value.isEmpty ? '정보 없음' : value;

  Widget _detailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _primaryBlue, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          ]),
        ),
      ]),
    );
  }

  Widget _linkRow({required String label, required String url}) {
    if (url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
          onTap: () async {
            try {
              await _launchUrl(url);
            } catch (e) {}
          },
          child: Row(
            children: [
              Icon(Icons.link, color: _secondaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: _secondaryBlue, decoration: TextDecoration.underline, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double lat = double.tryParse(detail.gpsY) ?? 0.0;
    final double lng = double.tryParse(detail.gpsX) ?? 0.0;
    final bool hasValidLocation = lat != 0.0 && lng != 0.0;

    return Scaffold(
      backgroundColor: _lightBlueBg,
      appBar: AppBar(
        title: Text(_checkValue(detail.title), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryBlue,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.blue[100]!, width: 1),
            ),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.imgUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(detail.imgUrl, height: 300, width: double.infinity, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 24),
                  Text(_checkValue(detail.title), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 24),
                  Divider(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 24),
                  _detailRow(icon: Icons.calendar_month_outlined, label: "기간", value: "${_formatDate(detail.startDate)} ~ ${_formatDate(detail.endDate)}"),
                  _detailRow(icon: Icons.place_outlined, label: "장소", value: _checkValue(detail.place)),
                  _detailRow(icon: Icons.location_on_outlined, label: "주소", value: _checkValue(detail.placeAddr)),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 24),
                  _detailRow(icon: Icons.category_outlined, label: "장르", value: _checkValue(detail.genre)),
                  _detailRow(icon: Icons.monetization_on_outlined, label: "가격", value: _checkValue(detail.price)),
                  _detailRow(icon: Icons.phone_outlined, label: "연락처", value: _checkValue(detail.phone)),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 24),
                  const Text("상세 정보 링크", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _linkRow(label: '주최측 홈페이지 바로가기', url: detail.url),
                  _linkRow(label: '장소/예매 페이지 바로가기', url: detail.placeUrl),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 24),
                  const Text("행사 위치", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  if (hasValidLocation)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 240,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(20)
                        ),
                        child: FlutterMap(
                          options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15),
                          children: [
                            TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.cultureyo.app'),
                            MarkerLayer(markers: [Marker(point: LatLng(lat, lng), width: 48, height: 48, child: Icon(Icons.location_on, color: _secondaryBlue, size: 48))]),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 240,
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue[100]!)),
                      child: Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 48, color: _primaryBlue),
                          const SizedBox(height: 12),
                          Text("위치 정보가 제공되지 않습니다.", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        ],
                      )),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}