import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
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
      home: LogIn(),
    );
  }
}

class LogIn extends StatefulWidget {
  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();

  void _login() {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String pw = _pwController.text.trim();

      if (email == "test@test.com" && pw == "1234") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 성공! 🎉")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("이메일 또는 비밀번호가 잘못되었습니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "로그인해서 계속 이용하세요",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '이메일',
                        prefixIcon: Icon(Icons.email, color: Colors.lightBlue[50]),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력하세요';
                        }
                        if (!value.contains('@')) {
                          return '유효한 이메일을 입력하세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _pwController,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        prefixIcon: Icon(Icons.lock, color: Colors.lightBlue[50]),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력하세요';
                        }
                        if (value.length < 4) {
                          return '비밀번호는 4자리 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        padding: EdgeInsets.symmetric(
                            horizontal: 100.0, vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 6,
                      ),
                      child: Text(
                        "로그인",
                        style: TextStyle(fontSize: 18.0, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("회원가입 기능은 준비 중입니다 🙂")),
                        );
                      },
                      child: Text(
                        "계정이 없으신가요? 회원가입",
                        style: TextStyle(color: Colors.lightBlue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
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
    LocationPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 유리 효과
      body: _pages[_selectedIndex],

      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // 흐림 효과
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
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: '게시판',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
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

/// 예시용 페이지
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

                // 지역 선택 버튼 → 새로운 화면으로 이동
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("지역 선택",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                            color: isSelected ? Colors.lightBlue[900] : Colors.black87,
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Divider(),
            // ✅ 첫 번째 행사
            ListTile(
              leading: const Icon(Icons.event_available, color: Colors.lightBlue),
              title: const Text("2025 금오문화축제"),
              subtitle: const Text("11월 15일 - 금오공대 대운동장"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailPage(
                      title: "2025 금오문화축제",
                      location: "금오공대 대운동장",
                      date: "2025년 11월 15일",
                      time: "오후 2시 ~ 9시",
                      description:
                      "금오공과대학교에서 열리는 대규모 문화축제입니다. 공연, 푸드트럭, 불꽃놀이 등 다채로운 프로그램이 진행됩니다.",
                    ),
                  ),
                );
              },
            ),

            // ✅ 두 번째 행사
            ListTile(
              leading: const Icon(Icons.music_note, color: Colors.lightBlue),
              title: const Text("겨울 콘서트"),
              subtitle: const Text("12월 5일 - 구미문화예술회관"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailPage(
                      title: "겨울 콘서트",
                      location: "구미문화예술회관",
                      date: "2025년 12월 5일",
                      time: "오후 7시 ~ 9시",
                      description:
                      "겨울을 따뜻하게 물들일 클래식 콘서트입니다. 지역 오케스트라와 유명 연주자가 함께하는 특별한 무대",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailPage extends StatelessWidget {
  final String title;
  final String location;
  final String date;
  final String time;
  final String description;

  const EventDetailPage({
    super.key,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ 왼쪽 화살표 제거
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.lightBlue),
                        const SizedBox(width: 8),
                        Text(location,
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.date_range, color: Colors.lightBlue),
                        const SizedBox(width: 8),
                        Text(date, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.lightBlue),
                        const SizedBox(width: 8),
                        Text(time, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black87, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text("되돌아가기",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  final List<Map<String, String>> chatList = [ {
    "name": "이름1", "message": "오늘 저녁에 뭐해?", "time": "오후 6:20"},
    {"name": "이름2", "message": "사진 잘 봤어요", "time": "오후 5:47"},
    {"name": "이름3", "message": "내일 회의 가능?", "time": "오전 9:30"},
  ];

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white,
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
        itemCount: chatList.length, itemBuilder: (context, index) {
        final chat = chatList[index];
        return ListTile(
          leading: CircleAvatar(backgroundColor: Colors.lightBlue,
            child: Text(
              chat['name']![0], style: TextStyle(color: Colors.white),),),
          title: Text(chat['name']!),
          subtitle: Text(chat['message']!),
          trailing: Text(
            chat['time']!, style: TextStyle(color: Colors.grey[600],
              fontSize: 12),),
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
      body: Center(
        child: Text(
          "위치 페이지 (추후 내용 추가)",
          style: TextStyle(color: Colors.grey, fontSize: 16),
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

            // 사용자 정보
            _accountItem("사용자명", "홍길동"),
            _accountItem("이메일", "example@email.com"),
            _accountItem("휴대폰", "010-1234-5678"),

            SizedBox(height: 10),
            Divider(),

            // 비밀번호 변경
            ListTile(
              title: Text("비밀번호 변경"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),

            // 계정 삭제
            ListTile(
              title: Text("계정 삭제하기",
                  style: TextStyle(color: Colors.red)),
              trailing: Icon(Icons.delete, color: Colors.red),
              onTap: () {},
            ),

            Spacer(),

            // 로그아웃 버튼
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

  // 재사용 카드 위젯
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
