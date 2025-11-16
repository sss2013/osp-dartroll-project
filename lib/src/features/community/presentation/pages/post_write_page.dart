// post_write_page.dart
import 'package:flutter/material.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';

class PostWritePage extends StatefulWidget {
  final String category; // review / friend

  const PostWritePage({Key? key, required this.category}) : super(key: key);

  @override
  State<PostWritePage> createState() => _PostWritePageState();
}

class _PostWritePageState extends State<PostWritePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final int titleMaxLength = 80; // 제목 글자 제한
  final int contentMaxLength = 500; // 내용 글자 제한

  // 선택된 공연
  String? selectedPerformance;

  // 지역/장르/서브지역 데이터
  String selectedRegion = '전국';
  String selectedGenre = '전체';

  final List<String> regions = [
    '전국', '서울', '경기', '인천', '대전', '세종', '충남', '충북',
    '광주', '전남', '전북', '대구', '경북', '부산', '울산', '경남', '강원', '제주'
  ];

  final Map<String, List<String>> subRegions = {
    '서울': ['전체', '세부지역1', '세부지역2'],
    '경기': ['전체', '세부지역1', '세부지역2'],
    '인천': ['전체', '세부지역1', '세부지역2'],
    '대전': ['전체', '세부지역1', '세부지역2'],
    '세종': ['전체', '세부지역1', '세부지역2'],
    '충남': ['전체', '세부지역1', '세부지역2'],
    '충북': ['전체', '세부지역1', '세부지역2'],
    '광주': ['전체', '세부지역1', '세부지역2'],
    '전남': ['전체', '세부지역1', '세부지역2'],
    '전북': ['전체', '세부지역1', '세부지역2'],
    '대구': ['전체', '세부지역1', '세부지역2'],
    '경북': ['전체', '세부지역1', '세부지역2'],
    '부산': ['전체', '세부지역1', '세부지역2'],
    '울산': ['전체', '세부지역1', '세부지역2'],
    '경남': ['전체', '세부지역1', '세부지역2'],
    '강원': ['전체', '세부지역1', '세부지역2'],
    '제주': ['전체', '세부지역1', '세부지역2'],
  };

  final List<String> genres = ['전체', '뮤지컬', '연극', '콘서트', '클래식'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색 흰색
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text(
          '게시글 작성',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  // 공연 선택 영역
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.zero, // 제목/내용 입력칸과 동일
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selectedPerformance ?? '공연을 선택해주세요',
                            style: TextStyle(
                              color: Colors.black, // 제목 입력칸과 동일하게 진하게
                              fontWeight: FontWeight.normal,
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Center( // 아이콘 중앙 정렬
                            child: Icon(
                              Icons.search,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 제목 입력칸
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
                  // 내용 입력칸
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
                  const SizedBox(height: 60), // 하단 버튼 공간 확보
                ],
              ),
            ),
          ),
          // 사진 업로드 버튼
          Positioned(
            left: 12,
            bottom: 12,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image, color: Colors.black),
              label: const Text('사진 업로드', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 완료 버튼
          Positioned(
            right: 12,
            bottom: 12,
            child: ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('완료', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      region: selectedRegion,
      subRegion: '전체',
      genre: selectedGenre,
      views: 0,
      likes: 0,
      date: DateTime.now(),
    );

    Navigator.pop(context, newPost);
  }

  Future<void> _showPerformanceModal() async {
    final performances = [
      {'title': '뮤지컬 A', 'genre': '뮤지컬', 'region': '서울', 'date': '2025-11-20'},
      {'title': '연극 B', 'genre': '연극', 'region': '경기', 'date': '2025-11-21'},
      {'title': '콘서트 C', 'genre': '콘서트', 'region': '부산', 'date': '2025-11-22'},
      {'title': '클래식 D', 'genre': '클래식', 'region': '서울', 'date': '2025-11-23'},
      {'title': '뮤지컬 E', 'genre': '뮤지컬', 'region': '인천', 'date': '2025-11-24'},
      {'title': '연극 F', 'genre': '연극', 'region': '경기', 'date': '2025-11-25'},
    ];

    String modalRegion = selectedRegion;
    String modalGenre = selectedGenre;
    String modalSearch = '';

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = performances.where((p) {
            final matchRegion =
            (modalRegion == '전국' || p['region'] == modalRegion);
            final matchGenre = (modalGenre == '전체' || p['genre'] == modalGenre);
            final matchSearch = p['title']!.contains(modalSearch);
            return matchRegion && matchGenre && matchSearch;
          }).toList();

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
                                    Text(modalRegion),
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
                                    Text(modalGenre),
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
                            borderRadius: BorderRadius.zero,
                          ),
                          child: TextField(
                            onChanged: (val) {
                              setModalState(() {
                                modalSearch = val;
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
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final perf = filtered[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(perf['title']!,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                          '${perf['genre']} • ${perf['region']} • ${perf['date']}'),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context, perf['title']);
                                  },
                                  child: const Text('선택'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shadowColor: Colors.grey,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
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

    if (selected != null) {
      setState(() {
        selectedPerformance = selected;
      });
    }
  }
}
