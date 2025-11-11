import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:cultureyo/src/features/community/presentation/pages/board_page.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: InterestSelectPage(),
    );
  }
}

/// 관심사 선택 페이지
class InterestSelectPage extends StatelessWidget {
  final List<String> interests = [
    "음악",
    "전시",
    "연극",
    "체험",
    "공예",
    "기타",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("관심사 선택"),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 15,
          runSpacing: 15,
          children: interests.map((interest) {
            return ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, interest); // 선택한 값 반환
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              ),
              icon: const Icon(Icons.star, color: Colors.white),
              label: Text(
                interest,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 메인 화면
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    ChatPage(),
    BoardPage(),  // 기존 push 대신 여기 포함
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex], // 선택된 탭 화면 표시
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
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
              boxShadow: const [
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
              onTap: (index) {
                setState(() => _selectedIndex = index); // 그냥 인덱스 변경
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: '대화',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.view_list_outlined),
                  activeIcon: Icon(Icons.view_list),
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


/// 예시용 홈 페이지
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> regions = ["서울", "부산", "대구", "광주", "대전", "기타"];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final cardMaxWidth = mq.width > 700 ? 700.0 : mq.width * 0.92;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "컬쳐요",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegionSelectPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "지역 선택",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                _eventBox("2025 서울 불꽃 축제", "여의도 한강공원", "2025.10.08"),
                const SizedBox(height: 10),
                _eventBox("겨울 빛 축제", "강원도 홍천 수목원", "2025.12.02"),
                const SizedBox(height: 10),
                _eventBox("전국 푸드 페스티벌", "부산 해운대 광장", "2025.11.21"),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventBox(String title, String location, String date) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(location, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

/// 지역 선택 페이지
class RegionSelectPage extends StatefulWidget {
  @override
  _RegionSelectPageState createState() => _RegionSelectPageState();
}

class _RegionSelectPageState extends State<RegionSelectPage> {
  String? selectedRegion;
  String? selectedInterest;
  final List<String> regions = ["서울", "부산", "대구", "광주", "대전", "기타"];
  final List<String> interests = ["공연", "전시", "축제", "콘서트", "연극", "체험"];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final cardMaxWidth = mq.width > 700 ? 700.0 : mq.width * 0.92;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "지역 선택",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // 지역 선택 카드
                _sectionCard(
                  title: "지역 선택",
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: regions.map((region) {
                      final isSelected = region == selectedRegion;
                      return ChoiceChip(
                        label: Text(region),
                        selected: isSelected,
                        selectedColor: Colors.lightBlueAccent[100],
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.lightBlue[900] : Colors.black87,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedRegion = region;
                            selectedInterest = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                // 관심사 선택 카드 (지역 선택했을 때만 표시)
                if (selectedRegion != null)
                  _sectionCard(
                    title: "관심사 선택",
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: interests.map((interest) {
                        final isSelected = interest == selectedInterest;
                        return ChoiceChip(
                          label: Text(interest),
                          selected: isSelected,
                          selectedColor: Colors.lightBlueAccent[100],
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color:
                            isSelected ? Colors.lightBlue[900] : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() {
                              selectedInterest = interest;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 18),
                // 결과 카드 (지역 + 관심사 선택했을 때만 표시)
                if (selectedInterest != null) _resultCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _resultCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${selectedRegion!}의 ${selectedInterest!} 추천 행사",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.event_available, color: Colors.lightBlue),
              title: Text("2025 금오문화축제"),
              subtitle: Text("11월 15일 - 금오공대 대운동장"),
            ),
            const ListTile(
              leading: Icon(Icons.music_note, color: Colors.lightBlue),
              title: Text("겨울 콘서트"),
              subtitle: Text("12월 5일 - 구미문화예술회관"),
            ),
          ],
        ),
      ),
    );
  }
}

/// 채팅 페이지
class ChatPage extends StatelessWidget {
  final List<Map<String, String>> chatList = [
    {"name": "이름1", "message": "오늘 저녁에 뭐해?", "time": "오후 6:20"},
    {"name": "이름2", "message": "사진 잘 봤어요", "time": "오후 5:47"},
    {"name": "이름3", "message": "내일 회의 가능?", "time": "오전 9:30"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "채팅",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: ListView.builder(
        itemCount: chatList.length,
        itemBuilder: (context, index) {
          final chat = chatList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.lightBlue,
              child: Text(chat['name']![0],
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(chat['name']!),
            subtitle: Text(chat['message']!),
            trailing: Text(chat['time']!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${chat['name']}님과의 채팅방으로 이동")),
              );
            },
          );
        },
      ),
    );
  }
}

/// 설정 페이지
class SettingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> settings = [
    {"icon": Icons.notifications, "title": "알림 설정"},
    {"icon": Icons.color_lens, "title": "테마 변경"},
    {"icon": Icons.security, "title": "개인정보 보호"},
    {"icon": Icons.logout, "title": "로그아웃"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "설정",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: settings.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = settings[index];
          return ListTile(
            leading: Icon(item['icon'], color: Colors.lightBlue),
            title: Text(item['title']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          );
        },
      ),
    );
  }
}

/// 위치 페이지
class LocationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "위치",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: const Center(
        child: Text(
          "위치 페이지 (추후 내용 추가)",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}

/// 내 정보 페이지
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
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.lightBlue,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 15),
            const Text(
              "홍길동",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("test@test.com", style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 30),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.settings, color: Colors.lightBlue),
                title: const Text("설정으로 이동"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
