import 'package:flutter/material.dart';

class MyInfoPage extends StatelessWidget {
  const MyInfoPage({super.key});

  final Color _primaryBlue = const Color(0xFF90CAF9); 
  final Color _lightBlueBg = const Color(0xFFE3F2FD); 
  final Color _borderColor = const Color(0xFFBBDEFB); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBlueBg, 
      appBar: AppBar(
        title: const Text(
          "내 정보",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryBlue,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryBlue, width: 2), 
                    color: Colors.white,
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    backgroundImage: AssetImage("assets/images/profile_default.png"),
                    child: null, 
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 이름
              const Text(
                "사용자 이름",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "문화생활을 즐기는 여행자", 
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),

              const SizedBox(height: 32),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24), 
                  side: BorderSide(color: _borderColor, width: 1),
                ),
                elevation: 0, 
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "계정 정보",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      _infoItem(
                        icon: Icons.email_outlined,
                        label: "이메일",
                        value: "example@email.com",
                      ),
                      _divider(),

                      _infoItem(
                        icon: Icons.person_outline,
                        label: "닉네임",
                        value: "닉네임을 설정하세요",
                      ),
                      _divider(),

                      _infoItem(
                        icon: Icons.phone_outlined,
                        label: "전화번호",
                        value: "등록된 번호 없음",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, 
                    foregroundColor: Colors.red[300], 
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.red[100]!), 
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("로그아웃 되었습니다."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text(
                    "로그아웃",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.grey[100]),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _lightBlueBg, 
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _primaryBlue, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              )
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[300]), 
      ],
    );
  }
}
