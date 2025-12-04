// lib/src/features/community/presentation/pages/board_page.dart

import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/features/community/dummy_posts.dart';
import 'package:flutter/material.dart';
import 'post_detail_page.dart';
import 'post_write_page.dart';
import '../../../home.dart';

// 💡 _buildPostCard 위젯은 PostDetailPage로 이동했으므로 여기서는 제거합니다.

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String selectedRegion = '전체';
  String selectedGenre = '전체';

  final int postsPerPage = 5;

  // 💡 [통일된 지역 목록]
  final List<String> regions = [
    '전체', '강원', '경기', '경남', '경북', '광주', '대구', '대전', '부산', '서울', '세종', '울산', '인천', '지역 미정'
  ];

  // 💡 [통일된 장르 목록]
  final List<String> genres = [
    '전체', '국악', '기타', '무용/발레', '뮤지컬/오페라', '연극', '음악/콘서트', '전시'
  ];

  int currentPage = 1;

  // 로컬 상태 리스트 (글쓰기 기능 테스트용)
  late List<Post> posts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    posts = [...dummyPosts]; // 기존 더미 데이터 복사
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Post> _filteredPosts(String category) {
    final filtered = posts.where((post) {
      final regionMatch =
          selectedRegion == '전체' || post.region == selectedRegion;
      final genreMatch = selectedGenre == '전체' || post.genre == selectedGenre;

      return post.category == category && regionMatch && genreMatch;
    }).toList();

    // 최신순 정렬
    filtered.sort((a, b) => b.date.compareTo(a.date));

    final startIndex = (currentPage - 1) * postsPerPage;
    final endIndex = (startIndex + postsPerPage) > filtered.length
        ? filtered.length
        : (startIndex + postsPerPage);

    if (startIndex >= filtered.length) return [];

    return filtered.sublist(startIndex, endIndex);
  }

  int _getFilteredCount(String category) {
    return posts.where((post) {
      final regionMatch =
          selectedRegion == '전체' || post.region == selectedRegion;
      final genreMatch = selectedGenre == '전체' || post.genre == selectedGenre;

      return post.category == category && regionMatch && genreMatch;
    }).length;
  }

  Future<void> _selectRegion() async {
    final region = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('지역 선택'),
        children: regions
            .map((r) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, r),
          child: Text(r),
        ))
            .toList(),
      ),
    );

    if (region == null) return;

    setState(() {
      selectedRegion = region;
      currentPage = 1;
    });
  }

  Future<void> _selectGenre() async {
    final genre = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('장르 선택'),
        children: genres
            .map((g) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, g),
          child: Text(g),
        ))
            .toList(),
      ),
    );

    if (genre != null) {
      setState(() {
        selectedGenre = genre;
        currentPage = 1;
      });
    }
  }

  String getRegionDisplayText() {
    return '지역: $selectedRegion';
  }

  String getGenreDisplayText() {
    return '장르: $selectedGenre';
  }

  void _onWritePost() async {
    final newPost = await Navigator.push<Post?>(
      context,
      MaterialPageRoute(
        builder: (_) => PostWritePage(
          category: _tabController.index == 0 ? 'review' : 'friend',
        ),
      ),
    );

    if (newPost != null) {
      setState(() {
        posts.insert(0, newPost); // 맨 앞에 추가 -> 최신순
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text(
          '게시판',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '리뷰 게시판'),
                Tab(text: '친구 찾기 게시판'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: _selectRegion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            getRegionDisplayText(),
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
                    onPressed: _selectGenre,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            getGenreDisplayText(),
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
          ),
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostList('review'),
                  _buildPostList('friend'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        // FloatingActionButton의 하단 패딩은 그대로 유지
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: FloatingActionButton(
          onPressed: _onWritePost,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          mini: true,
          child: const Icon(Icons.edit),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPostList(String category) {
    final posts = _filteredPosts(category);
    final totalPages = (_getFilteredCount(category) / postsPerPage).ceil();

    // 🚨 [수정]: 페이지네이션 가림 현상을 막기 위해 하단 패딩 조정
    // 72.0은 FloatingActionButton의 크기 및 여백을 고려한 충분한 여유 공간
    final bottomPadding = MediaQuery.of(context).padding.bottom + 72.0;

    return ListView.builder(
      // 🚨 [수정]: ListView의 패딩에 계산된 하단 패딩 적용
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index == posts.length) {
          // 페이지네이션 버튼
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalPages,
                    (i) {
                  final page = i + 1;
                  return TextButton(
                    onPressed: () {
                      setState(() {
                        currentPage = page;
                      });
                    },
                    child: Text(
                      '$page',
                      style: TextStyle(
                        fontWeight:
                        page == currentPage ? FontWeight.bold : FontWeight.normal,
                        color: page == currentPage ? Colors.blue : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        final post = posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Card(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기존 태그 (지역/장르)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            post.region,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            post.genre,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 🚨 [수정]: 제목 1줄 제한 및 생략
                    Text(
                      post.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('작성자: ${post.author}'),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye, size: 16),
                            const SizedBox(width: 4),
                            Text('${post.views}'),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(Icons.thumb_up, size: 16),
                            const SizedBox(width: 4),
                            Text('${post.likes}'),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${post.date.toLocal().toString().split(' ')[0].replaceAll('-', '.')}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}