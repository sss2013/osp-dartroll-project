// dart
import 'package:cultureyo/src/features/profile/domain/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'birthyear_input_page.dart'; // 다음 페이지 import

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});

  @override
  _NameInputPageState createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isChecking = false;
  late final UserService userService;

  final bannedNames = [
    '관리자', '운영자', 'Admin', 'Administrator', 'Root', 'SuperUser', 'System', 'Moderator', 'Mod', 'Staff',
    '씨발', '병신', '개새끼', '좆', 'ㅂㅅ', 'ㅅㅂ', 'ㄲㅈ', '시발', '애미', '애비', 'ㅄ',
    'Test', 'Guest', 'Anonymous', '익명', '유저', 'User'
  ];

  @override
  void initState() {
    super.initState();
    // Provider에서 UserService를 읽어 초기화 (프로젝트에 Provider 사용 중이라면)
    userService = context.read<UserService>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicateName() async {
    final enteredName = _controller.text.trim();
    if (enteredName.isEmpty) {
      _showAlert('닉네임을 입력해 주세요.');
      return;
    }
    final lowerBanned = bannedNames.map((e) => e.toLowerCase()).toList();
    if (lowerBanned.any((b) => enteredName.toLowerCase().contains(b))) {
      _showAlert('사용할 수 없는 이름입니다.');
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      final resp = await userService.checkName(enteredName);
      if (!mounted) return;

      // resp == true -> 이미 사용중, false -> 사용 가능
      final available = resp == false;
      final msg = available ? '사용 가능한 닉네임입니다.' : '이미 사용중인 닉네임입니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('중복 확인 중 오류가 발생했습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }

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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
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
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : _checkDuplicateName,
                          child: _isChecking
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Text('중복확인'),
                        ),
                      ),
                    ],
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
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
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