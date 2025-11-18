// post_write_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cultureyo/src/features/community/data/post_model.dart';

class Performance {
  final String id;
  final String title;

  Performance({required this.id, required this.title});
}

class PostWritePage extends StatefulWidget {
  final String category; // review / friend

  const PostWritePage({Key? key, required this.category}) : super(key: key);

  @override
  State<PostWritePage> createState() => _PostWritePageState();
}

class _PostWritePageState extends State<PostWritePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final int titleMaxLength = 80;
  final int contentMaxLength = 500;

  Performance? selectedPerformance; // 공연 ID + 제목 저장

  final List<String> regions = [
    '강원', '경기', '경남', '경북', '광주', '대구', '대전', '부산', '서울', '세종', '울산', '인천', '지역 미정'
  ];

  final List<String> genres = [
    '국악', '기타', '무용/발레', '뮤지컬/오페라', '연극', '음악/콘서트', '전시'
  ];

  Timer? _debounce; // 검색 debounce용

  // --- 게시글 작성 ---
  void _onSubmit() {
    if (titleController.text.isEmpty ||
        contentController.text.isEmpty ||
        selectedPerformance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목, 내용, 공연을 모두 입력해주세요')),
      );
      return;
    }

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: widget.category,
      title: titleController.text,
      content: contentController.text,
      author: '닉네임',
      region: '전체',
      subRegion: '전체',
      genre: '전체',
      views: 0,
      likes: 0,
      date: DateTime.now(),
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

    List<Map<String, dynamic>> performanceList = []; // ID + title 저장
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
            errorMessage = "해당 조건에 맞는 공연정보가 존재하지 않습니다.";
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

    final selected = await showDialog<Performance>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, _setModalState) {
          setModalState = _setModalState;

          List<Map<String, dynamic>> filtered = performanceList
              .where((item) => item['title'].contains(modalSearch))
              .toList();

          return Dialog(
            backgroundColor: Colors.white,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
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
                                  shadowColor: Colors.grey,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
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
                                  shadowColor: Colors.grey,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
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
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                          ),
                          child: TextField(
                            onChanged: (val) {
                              modalSearch = val;

                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();
                              _debounce =
                                  Timer(const Duration(milliseconds: 400), () {
                                    fetchPerformances();
                                  });
                            },
                            decoration: const InputDecoration(
                              hintText: '공연 제목으로 검색',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : (modalRegion == null || modalGenre == null)
                        ? const Center(
                        child: Text('지역과 장르를 선택해주세요'))
                        : errorMessage != null
                        ? Center(child: Text(errorMessage!))
                        : filtered.isEmpty
                        ? const Center(
                        child: Text('검색 조건에 맞는 공연이 없습니다.'))
                        : ListView.separated(
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
                          title: Text(
                            item['title'],
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight:
                              FontWeight.normal,
                            ),
                          ),
                          tileColor: Colors.white,
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                  context,
                                  Performance(
                                      id: item['id'],
                                      title: item['title']));
                            },
                            child: const Text('선택'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.grey,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(8),
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
          );
        },
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        selectedPerformance = selected;
      });
    }
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selectedPerformance?.title ??
                                '공연을 선택해주세요',
                            style: const TextStyle(
                              color: Colors.black,
                            ),
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
                            shape: RoundedRectangleBorder(
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
                  TextField(
                    controller: titleController,
                    maxLength: titleMaxLength,
                    decoration: InputDecoration(
                      hintText: '제목을 입력해주세요 ($titleMaxLength자 제한)',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLength: contentMaxLength,
                    maxLines: null,
                    minLines: 10,
                    decoration: InputDecoration(
                      hintText: '내용을 입력해주세요 ($contentMaxLength자 제한)',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
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