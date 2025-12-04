import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
// http는 이제 UI 계층에서 직접적으로 사용되지 않지만,
// PerformanceService 내에서는 여전히 사용됩니다. (코드 일관성을 위해 여기서는 제거)
// import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// 💡 [임포트 추가] 서비스 계층
import 'package:cultureyo/src/features/community/service/post_service.dart';
import 'package:cultureyo/src/features/community/service/performance_service.dart';

// 이 경로는 사용자님의 프로젝트 구조에 맞게 조정되었을 수 있습니다.
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/features/community/data/performance_detail_model.dart';


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
  PerformanceDetail? selectedPerformanceDetail;

  final List<String> regions = [
    '강원', '경기', '경남', '경북', '광주', '대구', '대전', '부산', '서울', '세종', '울산', '인천', '지역 미정'
  ];

  // 장르 항목에 '행사/축제'와 '교육/체험' 추가
  final List<String> genres = [
    '국악', '기타', '무용/발레', '뮤지컬/오페라', '연극', '음악/콘서트', '전시',
    '행사/축제',
    '교육/체험'
  ];

  Timer? _debounce;

  // 💡 [서비스 인스턴스]
  final PostService _postService = PostService();
  final PerformanceService _performanceService = PerformanceService();

  // 선택된 장르에 따라 idxName을 결정하는 헬퍼 함수
  String _getIdxName(String selectedGenre) {
    if (selectedGenre == '행사/축제') {
      return 'festival';
    } else if (selectedGenre == '교육/체험') {
      return 'experience';
    } else {
      // 그 외의 모든 기존 장르는 'performance' 유지
      return 'performance';
    }
  }


  // 게시물 작성 API 호출 로직 (PostService 사용)
  Future<void> _createPostApi() async {
    // 1. 필수 데이터 확인
    if (selectedPerformanceDetail == null || selectedPerformance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공연 정보가 올바르게 선택되지 않았습니다.')),
      );
      return;
    }

    final PerformanceDetail detail = selectedPerformanceDetail!;
    final String performanceUrl = detail.url ?? '';

    // 2. Prefix에 따라 최종 장르값 결정
    String finalGenre = detail.genre ?? '장르 미정';
    final String prefix = selectedPerformance!.idxName; // festival, experience, performance

    if (prefix == 'festival') {
      finalGenre = '행사/축제';
    } else if (prefix == 'experience') {
      finalGenre = '교육/체험';
    }

    // 3. userId와 content 필드명 적용
    String currentUserId = 'testUser123'; // 임시 테스트 ID 사용

    // 4. 서버로 전송할 요청 본문
    final Map<String, dynamic> requestBody = {
      "title": titleController.text,
      "userId": currentUserId, // 테스트 userId 반영
      "area": detail.area ?? '지역 미정',
      "genre": finalGenre, // 최종 결정된 장르 값 사용
      "content": contentController.text, // content -> context로 필드명 변경
      "url": performanceUrl,
      "tap": widget.category,
    };

    try {
      // 💡 [변경] PostService의 createPost 함수 호출
      final String? postId = await _postService.createPost(requestBody);

      if (mounted) {
        if (postId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시물이 성공적으로 작성되었습니다.')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시물 작성 실패: 서버 응답 오류가 발생했습니다.')),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물 작성 요청 시간이 초과되었습니다. 서버 상태를 확인해주세요.')),
        );
      }
    } catch (e) {
      // PostService에서 throw된 Exception 처리
      log('🚨 [게시물 작성 에러] Exception: $e', name: 'POST_WRITE');
      if (mounted) {
        // 간결한 오류 메시지 추출
        final errorMessage = e.toString().contains(':') ? e.toString().split(':')[1].trim() : '네트워크 오류';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시물 작성 중 오류가 발생했습니다: $errorMessage')),
        );
      }
    }
  }

  // --- HTML 디코딩 함수 (유지) ---
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
    _createPostApi();
  }
  String htmlDecode(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  // 💡 [수정] 공연 선택 modal 내 API 호출 로직 (PerformanceService 사용)
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

      final String currentIdxName = _getIdxName(modalGenre!);

      try {
        // 💡 [변경] PerformanceService를 사용하여 목록 조회
        final List<Map<String, dynamic>> results = await _performanceService.fetchSimplePerformances(
          idxName: currentIdxName,
          area: modalRegion!,
          genre: modalGenre!,
        );

        // title 디코딩 및 리스트 업데이트
        performanceList = results
            .map<Map<String, dynamic>>((item) => {
          'id': item['id'].toString(), // 'prefix:number' 형태를 유지
          'title': htmlDecode(item['title']?.toString() ?? '제목 없음')
        }).toList();

        if (performanceList.isEmpty) {
          errorMessage = "해당 조건에 맞는 공연이 없습니다.";
        }

        // 검색 필터링 로직은 UI 계층(Modal)에서 처리
        if (modalSearch.isNotEmpty) {
          performanceList = performanceList
              .where((item) => item['title'].contains(modalSearch))
              .toList();
        }

      } on TimeoutException {
        performanceList = [];
        errorMessage = "서버 응답 시간 초과";
      } catch (e) {
        performanceList = [];
        // Service에서 발생한 Exception 메시지를 사용
        final errorDetail = e.toString().contains(':') ? e.toString().split(':')[1].trim() : '네트워크 오류';
        errorMessage = "공연 목록 조회 오류: $errorDetail";
        log('🚨 [API_ERROR] Exception: $e', name: 'PERFORMANCE_FETCH');
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
                                      // 💡 [UI 수정] Flexible로 감싸서 텍스트 오버플로우 방지
                                      Flexible(
                                        child: Text(
                                          modalRegion ?? '지역 선택',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
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
                                        children: genres // 💡 확장된 genres 리스트 사용
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
                                      // 💡 [UI 수정] Flexible로 감싸서 텍스트 오버플로우 방지
                                      Flexible(
                                        child: Text(
                                          modalGenre ?? '장르 선택',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
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
        // 💡 [변경] PerformanceService를 사용하여 상세 정보 조회
        final detail = await _performanceService.fetchEventDetail(
          idxName: idxName,
          contentId: contentId,
        );

        if (mounted) {
          setState(() {
            selectedPerformanceDetail = detail; // 상세 모델 저장
          });
        }
      } on TimeoutException {
        log('API 호출 에러: 상세 정보 요청 시간 초과', name: 'API_CHECK');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공연 상세 정보 조회 시간이 초과되었습니다.')),
          );
        }
      } catch (e) {
        log('API 호출 에러: $e', name: 'API_CHECK');
        if (mounted) {
          final errorDetail = e.toString().contains(':') ? e.toString().split(':')[1].trim() : '네트워크 오류';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('공연 상세 정보 조회 오류: $errorDetail')),
          );
        }
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

  // --- 공연 상세 정보 카드 UI 위젯 (유지) ---
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
            color: Colors.blue[50],
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
                // 닫기 버튼 로직 제거됨.
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
      color: Colors.black54,
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
    );

    const TextStyle selectedPerformanceTextStyle = TextStyle(
      color: Colors.black,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selectedPerformance?.title ?? '공연을 선택해주세요',
                            maxLines: 3,
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
                  const SizedBox(height: 12),

                  // 4. 공연 상세 카드 위젯
                  _buildPerformanceCard(),

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