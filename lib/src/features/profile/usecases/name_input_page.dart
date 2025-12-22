// lib/src/features/profile/usecases/name_input_page.dart
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
  late final UserService userService;

  bool _isChecking = false;
  // 1. 중복 검사 결과와 메시지를 관리할 상태 변수 추가
  bool? _isNameAvailable;
  String? _validationMessage;

  final bannedNames = [
    '관리자', '운영자', 'Admin', 'Administrator', 'Root', 'SuperUser', 'System', 'Moderator', 'Mod', 'Staff',
    '씨발', '병신', '개새끼', '좆', 'ㅂㅅ', 'ㅅㅂ', 'ㄲㅈ', '시발', '애미', '애비', 'ㅄ',
    'Test', 'Guest', 'Anonymous', '익명', '유저', 'User'
  ];

  @override
  void initState() {
    super.initState();
    userService = context.read<UserService>();
    // 4. 닉네임이 변경될 때마다 검사 상태를 초기화
    _controller.addListener(() {
      if (_isNameAvailable != null || _validationMessage != null) {
        setState(() {
          _isNameAvailable = null;
          _validationMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicateName() async {
    final enteredName = _controller.text.trim();
    if (enteredName.isEmpty) {
      setState(() {
        _isNameAvailable = false;
        _validationMessage = '닉네임을 입력해 주세요.';
      });
      return;
    }
    final lowerBanned = bannedNames.map((e) => e.toLowerCase()).toList();
    if (lowerBanned.any((b) => enteredName.toLowerCase().contains(b))) {
      setState(() {
        _isNameAvailable = false;
        _validationMessage = '사용할 수 없는 이름입니다.';
      });
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      final isDuplicate = await userService.checkName(enteredName);
      if (!mounted) return;

      setState(() {
        _isNameAvailable = !isDuplicate; // 중복이면 false, 아니면 true
        _validationMessage = isDuplicate ? '이미 사용중인 닉네임입니다.' : '사용 가능한 닉네임입니다.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNameAvailable = false;
          _validationMessage = '오류가 발생했습니다. 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  // _showAlert 메서드는 더 이상 사용하지 않으므로 삭제 가능
  // void _showAlert(String message) { ... }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                  const Text(
                    '닉네임을 입력해 주세요',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            counterText: '', // maxLength 카운터 숨기기
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 58, // TextField 높이와 맞춤
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
                  // 2. 중복 검사 결과 메시지 표시 UI
                  if (_validationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            _isNameAvailable == true ? Icons.check_circle : Icons.error,
                            color: _isNameAvailable == true ? Colors.blue : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _validationMessage!,
                            style: TextStyle(
                              color: _isNameAvailable == true ? Colors.blue : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 3. _isNameAvailable이 true일 때만 '다음' 버튼 활성화
                  ElevatedButton(
                    onPressed: _isNameAvailable == true
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BirthYearInputPage(name: _controller.text.trim())),
                      );
                    }
                        : null, // 비활성화 상태
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