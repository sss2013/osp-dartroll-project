import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:cultureyo/src/features/profile/domain/user_service.dart';

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({super.key});

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  String _nickname = "불러오는 중...";
  String _bio = "오늘도 즐거운 하루 되세요!";

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
    });
  }

//내정보 가져오기
  Future<void> _loadUserInfo() async {
    try {
      if (!mounted) return;
      //main.dart에 있는 UserService 가져오기
      final userService = context.read<UserService>();

      final userData = await userService.loadUserName();

      if (mounted && userData.containsKey('name')) {
        setState(() {
          _nickname = userData['name'];
        });
      }
    } catch (e) {
      print("정보 로드 실패: $e");
      if (mounted) {
        setState(() {
          _nickname = "정보 없음";
        });
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "마이 페이지",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.lightBlue.withOpacity(0.2),
                              width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 45,
                          backgroundImage:
                              AssetImage('assets/images/profile_default.png'),
                          child:
                              Icon(Icons.person, size: 45, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nickname,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showBioDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _bio,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoTile(
                    icon: Icons.edit,
                    title: "닉네임 변경",
                    value: _nickname,
                    onTap: _showNicknameDialog,
                  ),
                  _divider(),
                  _infoTile(
                    icon: Icons.article_outlined,
                    title: "사용자 이용 약관",
                    value: "약관 확인하기",
                    onTap: _showTermsDialog,
                    isLink: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: _showDeleteConfirmDialog,
              child: Text(
                "계정 탈퇴",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("계정 탈퇴"),
          content:
              const Text("정말로 계정을 탈퇴하시겠습니까?\n모든 정보가 영구적으로 삭제되며 복구할 수 없습니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("취소", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // 대화상자 닫기
                _deleteAccount(); // 탈퇴 처리 함수 호출
              },
              child: const Text("탈퇴", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      if (!mounted) return;
      final userService = context.read<UserService>();
     await userService.deleteUser();

      // 탈퇴 성공 시 스낵바 표시.
      // 실제 화면 전환은 main.dart에서 onAuthenticationFailed 스트림을 통해 처리됩니다.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("계정이 성공적으로 탈퇴되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("계정 탈퇴 중 오류가 발생했습니다: ${e is DioException ? e.message : e.toString()}")),
        );
      }
    }
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey[100]);

  Widget _infoTile(
      {required IconData icon,
      required String title,
      required String value,
      VoidCallback? onTap,
      bool isLink = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.blueGrey[50],
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.lightBlue, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black54)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isLink ? Colors.lightBlue : Colors.black87)),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
          ]
        ],
      ),
    );
  }

  // lib/src/features/my_info_page.dart

  void _showNicknameDialog() {
    _nicknameController.text = _nickname;

    // 중복 확인 관련 상태 변수
    bool? isNameAvailable;
    String? validationMessage;
    bool isChecking = false;
    final bannedNames = [
      '관리자', '운영자', 'Admin', 'Administrator', 'Root', 'SuperUser', 'System', 'Moderator', 'Mod', 'Staff',
      '씨발', '병신', '개새끼', '좆', 'ㅂㅅ', 'ㅅㅂ', 'ㄲㅈ', '시발', '애미', '애비', 'ㅄ',
      'Test', 'Guest', 'Anonymous', '익명', '유저', 'User'
    ];

    showDialog(
      context: context,
      builder: (context) {
        // 다이얼로그 내부 상태 관리를 위해 StatefulBuilder 사용
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 닉네임 입력 감지하여 유효성 검사 상태 초기화
            _nicknameController.addListener(() {
              if (isNameAvailable != null || validationMessage != null) {
                setDialogState(() {
                  isNameAvailable = null;
                  validationMessage = null;
                });
              }
            });

            Future<void> checkDuplicate() async {
              final newName = _nicknameController.text.trim();

              if (newName == _nickname) {
                setDialogState(() {
                  isNameAvailable = false;
                  validationMessage = "현재 닉네임과 동일합니다.";
                });
                return;
              }
              if (newName.isEmpty) {
                setDialogState(() {
                  isNameAvailable = false;
                  validationMessage = "닉네임을 입력해 주세요.";
                });
                return;
              }
              final lowerBanned = bannedNames.map((e) => e.toLowerCase()).toList();
              if (lowerBanned.any((b) => newName.toLowerCase().contains(b))) {
                setDialogState(() {
                  isNameAvailable = false;
                  validationMessage = '사용할 수 없는 이름입니다.';
                });
                return;
              }

              setDialogState(() => isChecking = true);

              try {
                final userService = context.read<UserService>();
                final isDuplicate = await userService.checkName(newName);
                setDialogState(() {
                  isNameAvailable = !isDuplicate;
                  validationMessage = isDuplicate ? '이미 사용중인 닉네임입니다.' : '사용 가능한 닉네임입니다.';
                });
              } catch (e) {
                setDialogState(() {
                  isNameAvailable = false;
                  validationMessage = '오류가 발생했습니다.';
                });
              } finally {
                setDialogState(() => isChecking = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("닉네임 변경"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          maxLength: 7,
                          decoration: const InputDecoration(
                            hintText: "새로운 닉네임을 입력하세요",
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.lightBlue)),
                            counterText: '',
                          ),
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 58, // TextField 높이와 맞춤
                        child: ElevatedButton(
                          onPressed: isChecking ? null : checkDuplicate,
                          child: isChecking
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('중복확인'),
                        ),
                      ),
                    ],
                  ),
                  if (validationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        validationMessage!,
                        style: TextStyle(
                          color: isNameAvailable == true ? Colors.blue : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("취소", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  // isNameAvailable이 true일 때만 저장 버튼 활성화
                  onPressed: isNameAvailable == true
                      ? () {
                    _updateNickname(_nicknameController.text.trim());
                    Navigator.pop(context);
                  }
                      : null,
                  child: const Text("저장", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateNickname(String newName) async {
    try {
      if (!mounted) return;
      final userService = context.read<UserService>();
      final result = await userService.changeName(newName);
      if (!result) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("닉네임이 이미 사용 중입니다.")));
        return;
      }
      // 갱신
      if (mounted) {
        setState(() {
          _nickname = newName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("닉네임이 변경되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("닉네임 변경 실패: ${e.toString()}")),
        );
      }
    }
  }

  void _showBioDialog() {
    _bioController.text = _bio;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text("자기소개 변경"),
                content: TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                      hintText: "내용 입력", border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("취소")),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue),
                    onPressed: () {
                      setState(() {
                        _bio = _bioController.text;
                      });
                      Navigator.pop(context);
                    },
                    child:
                        const Text("저장", style: TextStyle(color: Colors.white)),
                  )
                ]));
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("서비스 이용 약관",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TermSection(
                          title: "제1조 (개인정보의 처리 목적)",
                          content:
                              "[컬쳐요](이하 '회사' 또는 '서비스')은(는) 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보 보호법 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.\n\n"
                              "1. 회원 가입 및 관리\n"
                              "2. SNS(카카오, 네이버) 계정을 통한 간편 로그인 서비스 제공\n"
                              "3. 회원 식별 및 서비스 이용에 따른 본인 확인\n"
                              "4. 서비스 부정이용 방지 및 비인가 사용 방지",
                        ),
                        _TermSection(
                          title: "제2조 (처리하는 개인정보의 항목)",
                          content:
                              "서비스는 회원가입 및 서비스 이용 과정에서 아래와 같은 개인정보를 수집 및 처리합니다.\n\n"
                              "1. SNS 간편 로그인 시 (카카오, 네이버)\n"
                              "- 필수 항목: SNS 연동 시 제공되는 고유 식별자(Unique ID)\n"
                              "※ 참고: 고유 식별자란 카카오/네이버 등에서 이용자를 구분하기 위해 부여한 난수 형태의 고유번호를 말하며, 비밀번호는 수집하지 않습니다.\n\n"
                              "2. 서비스 이용 과정에서 자동 생성되어 수집되는 항목\n"
                              "- 접속 IP 정보, 서비스 이용 기록, 접속 로그, 기기 정보",
                        ),
                        _TermSection(
                          title: "제3조 (개인정보의 처리 및 보유 기간)",
                          content:
                              "서비스는 법령에 따른 개인정보 보유·이용 기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용 기간 내에서 개인정보를 처리하고 보유합니다.\n\n"
                              "1. 보유 기간: 회원 탈퇴 시까지\n"
                              "2. 단, 관계 법령 위반에 따른 수사·조사 등이 진행 중인 경우에는 해당 수사·조사 종료 시까지 보유할 수 있습니다.",
                        ),
                        _TermSection(
                          title: "제4조 (개인정보의 파기절차 및 방법)",
                          content:
                              "서비스는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.\n\n"
                              "- 파기 방법: 전자적 파일 형태로 기록·저장된 개인정보는 기록을 재생할 수 없도록 파기하며, 종이 문서에 기록·저장된 개인정보는 분쇄기로 분쇄하거나 소각하여 파기합니다.",
                        ),
                        _TermSection(
                          title: "제5조 (정보주체와 법정대리인의 권리·의무 및 그 행사방법)",
                          content:
                              "이용자는 언제든지 개인정보 열람·정정·삭제·처리정지 요구 등의 권리를 행사할 수 있습니다.\n"
                              "회원 탈퇴 기능 또는 앱 내 설정 메뉴를 통해 언제든지 SNS 연동을 해제하거나 계정을 삭제할 수 있습니다.",
                        ),
                        _TermSection(
                          title: "제6조 (개인정보 보호책임자)",
                          content:
                              "서비스는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만 처리 및 피해 구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.",
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TermSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: Colors.black54)),
        ],
      ),
    );
  }
}
