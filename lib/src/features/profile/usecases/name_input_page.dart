import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'birthyear_input_page.dart'; // 다음 페이지 import

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});
  @override
  _NameInputPageState createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _controller = TextEditingController();
  final bannedNames = [
    // 시스템/관리 관련
    '관리자', '운영자', 'Admin', 'Administrator', 'Root', 'SuperUser', 'System', 'Moderator', 'Mod', 'Staff',
    // 욕설
    '씨발', '병신', '개새끼', '좆', 'ㅂㅅ', 'ㅅㅂ', 'ㄲㅈ', '시발','애미','애비','ㅄ',
    // 기타
    'Test', 'Guest', 'Anonymous', '익명', '유저', 'User'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                  const Text(
                    '닉네임을 입력해 주세요',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLength: 7,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(7),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9ㄱ-ㅎ가-힣]')),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '닉네임',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final enteredName = _controller.text.trim();
                      final lowerBanned = bannedNames.map((e) => e.toLowerCase()).toList();
                      bool isBanned = lowerBanned.any((b) => enteredName.toLowerCase().contains(b));
                      if (isBanned || enteredName.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: const Text('사용할 수 없는 이름입니다.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BirthYearInputPage(name: _controller.text)),
                      );
                    },
                    child: const Text('다음'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}