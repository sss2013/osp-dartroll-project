// post_write_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer'; // 로그 사용
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/features/community/data/performance_detail_model.dart';
import 'package:url_launcher/url_launcher.dart'; // 외부 링크 열기 패키지

class Performance {
  final String id;
  final String idxName;
  final String contentId;
  final String title;

  Performance({
    required this.id,
    required this.idxName,
    required this.contentId,
    required this.title,
  });
}

class PostWritePage extends StatefulWidget {
  final String category;

  const PostWritePage({Key? key, required this.category}) : super(key: key);

  @override
  State<PostWritePage> createState() => _PostWritePageState();
}

class _PostWritePageState extends State<PostWritePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final int titleMaxLength = 80;
  final int contentMaxLength = 500;

  Performance? selectedPerformance;
  // 상세 정보를 저장할 변수
  PerformanceDetail? selectedPerformanceDetail;

  final List<String> regions = [
    '강원', '경기', '경남', '경북', '광주', '대구', '대전', '부산', '서울', '세종', '울산', '인천', '지역 미정'
  ];

  final List<String> genres = [
    '국악', '기타', '무용/발레', '뮤지컬/오페라', '연극', '음악/콘서트', '전시'
  ];

  Timer? _debounce;

  // --- 게시글 작성 (공연 정보 포함) ---
  void _onSubmit() {
    if (titleController.text.isEmpty ||
        contentController.text.isEmpty ||
        selectedPerformance == null ||
        selectedPerformanceDetail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목, 내용, 공연을 모두 선택/입력해주세요')),
      );
      return;
    }

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: widget.category,
      title: titleController.text,
      content: contentController.text,
      author: '닉네임',
      region: selectedPerformanceDetail!.area ?? '지역 미정',
      genre: selectedPerformanceDetail!.genre ?? '장르 미정',
      views: 0,
      likes: 0,
      date: DateTime.now(),

      // Post 모델 확장 필드에 값 저장
      performanceId: selectedPerformance!.id,
      performanceTitle: selectedPerformance!.title,
      performanceUrl: selectedPerformanceDetail!.url,
    );

    Navigator.pop(context, newPost);
  }

  // --- HTML 디코딩 함수 ---
  String htmlDecode(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  // --- 공연 선택 modal ---
  Future<void> _showPerformanceModal() async {
    String? modalRegion;
    String? modalGenre;
    String modalSearch = '';

    List<Map<String, dynamic>> performanceList = [];
    bool isLoading = false;
    String? errorMessage;

    late void Function(void Function()) setModalState;

    Future<void> fetchPerformances() async {
      if (modalRegion == null || modalGenre == null) return;
      if (!mounted) return;

      setModalState(() {
        isLoading = true;
        errorMessage = null;
      });

      final body = {
        'idxName': 'performance',
        'area': modalRegion == '지역 미정' ? 'empty' : modalRegion,
        'genre': modalGenre,
      };

      try {
        final response = await http.post(
          Uri.parse('https://dartroll-nodejs.onrender.com/api/getSimple'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = jsonDecode(response.body);
          final List<dynamic> results = jsonData['results'] ?? [];
          performanceList = results
              .map<Map<String, dynamic>>((item) => {
            'id': item['id'].toString(),
            'title': htmlDecode(item['title'].toString())
          })
              .toList();

          if (performanceList.isEmpty) {
            errorMessage = "해당 조건에 맞는 공연이 없습니다.";
          }

          if (modalSearch.isNotEmpty) {
            performanceList = performanceList
                .where((item) => item['title'].contains(modalSearch))
                .toList();
          }
        } else {
          performanceList = [];
          errorMessage = "서버 오류";
        }
      } catch (e) {
        performanceList = [];
        errorMessage = "서버 오류";
      } finally {
        if (!mounted) return;
        setModalState(() {
          isLoading = false;
        });
      }
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, _setModalState) {
          setModalState = _setModalState;

          List<Map<String, dynamic>> filtered = performanceList
              .where((item) => item['title'].contains(modalSearch))
              .toList();

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    // --- 상단 헤더 ---
                    Container(
                      color: Colors.lightBlue,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final region = await showDialog<String>(
                                      context: context,
                                      builder: (context) => SimpleDialog(
                                        title: const Text('지역 선택'),
                                        children: regions
                                            .map((r) => SimpleDialogOption(
                                          onPressed: () =>
                                              Navigator.pop(context, r),
                                          child: Text(r),
                                        ))
                                            .toList(),
                                      ),
                                    );
                                    if (region != null) {
                                      setModalState(() {
                                        modalRegion = region;
                                      });
                                      fetchPerformances();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(modalRegion ?? '지역 선택'),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final genre = await showDialog<String>(
                                      context: context,
                                      builder: (context) => SimpleDialog(
                                        title: const Text('장르 선택'),
                                        children: genres
                                            .map((g) => SimpleDialogOption(
                                          onPressed: () =>
                                              Navigator.pop(context, g),
                                          child: Text(g),
                                        ))
                                            .toList(),
                                      ),
                                    );
                                    if (genre != null) {
                                      setModalState(() {
                                        modalGenre = genre;
                                      });
                                      fetchPerformances();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(modalGenre ?? '장르 선택'),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              onChanged: (val) {
                                modalSearch = val;
                                if (_debounce?.isActive ?? false)
                                  _debounce!.cancel();
                                _debounce = Timer(
                                    const Duration(milliseconds: 400), () {
                                  fetchPerformances();
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: '공연 제목으로 검색',
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- 하단 리스트 ---
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (modalRegion == null || modalGenre == null)
                          ? const Center(child: Text('지역과 장르를 선택해주세요'))
                          : errorMessage != null
                          ? Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                          : filtered.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            '해당 조건에 맞는 공연이 없습니다.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                          : ListView.separated(
                        physics:
                        const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                              height: 1,
                            ),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4),
                            title: Text(
                              item['title'],
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            tileColor: Colors.white,
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, {
                                  'id': item['id'],
                                  'title': item['title']
                                });
                              },
                              child: const Text('선택'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.grey,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                      8),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (selected != null && mounted) {
      final String rawId = selected['id'];
      final String rawTitle = selected['title'];

      final parts = rawId.split(':');
      String idxName = '';
      String contentId = '';

      if (parts.length == 2) {
        idxName = parts[0];
        contentId = parts[1];
      }

      // ▼▼▼▼▼ 상세 정보 API 호출 및 저장 ▼▼▼▼▼
      try {
        final detailBody = {
          'idxName': idxName,
          'contentId': contentId,
        };

        final detailResponse = await http.post(
          Uri.parse('https://dartroll-nodejs.onrender.com/api/getEventDetail'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(detailBody),
        );

        if (detailResponse.statusCode == 200) {
          final Map<String, dynamic> jsonDetail = jsonDecode(detailResponse.body);
          final detail = PerformanceDetail.fromJson(jsonDetail);
          setState(() {
            selectedPerformanceDetail = detail; // 상세 모델 저장
          });
        } else {
          log('🔍 [API_CHECK] 상세 정보 호출 실패: ${detailResponse.statusCode}', name: 'API_CHECK');
        }

      } catch (e) {
        log('API 호출 에러: $e', name: 'API_CHECK');
      }
      // ▲▲▲▲▲ ▲▲▲▲▲


      setState(() {
        selectedPerformance = Performance(
          id: rawId,
          idxName: idxName,
          contentId: contentId,
          title: rawTitle, // UI 표시용 제목
        );
      });
    }
  }

  // --- 공연 상세 정보 카드 UI 위젯 (X 버튼 제거) ---
  Widget _buildPerformanceCard() {
    final detail = selectedPerformanceDetail;

    if (detail == null) {
      return const SizedBox.shrink();
    }

    final displayTitle = detail.title ?? '제목 없음';
    final url = detail.url;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            if (url != null && url.isNotEmpty) {
              final uri = Uri.parse(url);

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('링크를 열 수 없습니다.')),
                );
              }

            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공연 예매 링크가 없습니다.')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue[50], // 배경색을 연한 파란색으로 변경하여 선택된 느낌 강조
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 제목과 링크 아이콘
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      // 제목
                      Flexible(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // 🗑️ 닫기 버튼 로직 제거됨.
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle hintTextStyle = TextStyle(
      color: Colors.black54, // 밝은 회색 계열
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
    );

    const TextStyle selectedPerformanceTextStyle = TextStyle(
      color: Colors.black, // 선택된 값은 진하게
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text(
          '게시글 작성',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 공연 선택 필드 (돋보기 버튼)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          // 🚨 [수정 완료]: height 고정값 제거 및 수직 패딩 조정
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selectedPerformance?.title ?? '공연을 선택해주세요',
                            maxLines: 3, // 최대 3줄까지 허용
                            overflow: TextOverflow.ellipsis,
                            style: selectedPerformance != null
                                ? selectedPerformanceTextStyle
                                : hintTextStyle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: ElevatedButton(
                          onPressed: _showPerformanceModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shadowColor: Colors.grey,
                            elevation: 3,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Center(
                            child: Icon(Icons.search, size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. 제목 입력 필드
                  TextField(
                    controller: titleController,
                    maxLength: titleMaxLength,
                    decoration: InputDecoration(
                      hintText: '제목을 입력해주세요 ($titleMaxLength자 제한)',
                      hintStyle: hintTextStyle,
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. 내용 입력 필드
                  TextField(
                    controller: contentController,
                    maxLength: contentMaxLength,
                    maxLines: null,
                    minLines: 10,
                    decoration: InputDecoration(
                      hintText: '내용을 입력해주세요 ($contentMaxLength자 제한)',
                      hintStyle: hintTextStyle,
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12), // 내용 필드와 카드 사이 간격 추가

                  // ▼▼▼▼▼ 공연 상세 카드 위젯 ▼▼▼▼▼
                  _buildPerformanceCard(),
                  // ▲▲▲▲▲ ▲▲▲▲▲

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image, color: Colors.black),
              label: const Text('사진 업로드',
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('완료', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}