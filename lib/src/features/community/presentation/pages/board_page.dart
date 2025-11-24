// lib/src/features/community/presentation/pages/board_page.dart

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // http 패키지 추가
import 'package:cultureyo/src/features/community/data/post_model.dart';
// import 'package:cultureyo/src/features/community/dummy_posts.dart'; // 🗑️ 더미 데이터 삭제

import 'post_detail_page.dart';
import 'post_write_page.dart';
import '../../../home.dart';

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

  final List<String> regions = [
    '전체', '강원', '경기', '경남', '경북', '광주', '대구', '대전', '부산', '서울', '세종', '울산', '인천', '지역 미정'
  ];

  final List<String> genres = [
    '전체', '국악', '기타', '무용/발레', '뮤지컬/오페라', '연극', '음악/콘서트', '전시'
  ];

  int currentPage = 1;

  // 💡 [변경] 실제 데이터를 저장할 리스트
  List<Post> posts = [];
  bool isLoading = false; // 로딩 상태 관리

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 탭 변경 시 데이터를 다시 불러오기 위한 리스너
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // 탭이 변경되면 페이지를 1로 초기화하고 데이터 새로고침
        setState(() {
          currentPage = 1;
        });
        _fetchPosts();
      }
    });

    // 초기 데이터 로드
    _fetchPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 💡 [추가] API 호출 함수
  Future<void> _fetchPosts() async {
    setState(() {
      isLoading = true;
    });

    // 현재 탭에 따라 category 결정
    final String category = _tabController.index == 0 ? 'review' : 'matching';

    // 기존 디자인의 로컬 필터링/페이지네이션을 유지하기 위해
    // 한 번에 넉넉한 양(limit=100)을 가져옵니다.
    // (서버 API가 총 개수 정보를 안 주기 때문에 이 방식이 UI 유지에 유리함)
    final url = 'https://dartroll-nodejs.onrender.com/api/post/getAll?page=0&limit=100&tap=$category';

    log('🔍 [API_REQUEST] Fetching posts: $url', name: 'BOARD_PAGE');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        log('✅ [API_RESPONSE] Count: ${jsonList.length}', name: 'BOARD_PAGE');

        setState(() {
          posts = jsonList.map((json) {
            // 서버 응답에 category 정보가 없을 수 있으므로 현재 탭 정보를 주입
            return Post.fromApiJson(json as Map<String, dynamic>, category: category);
          }).toList();

          isLoading = false;
        });
      } else {
        log('🚨 [API_ERROR] Status: ${response.statusCode}', name: 'BOARD_PAGE');
        setState(() {
          posts = [];
          isLoading = false;
        });
      }
    } catch (e) {
      log('🚨 [API_EXCEPTION] $e', name: 'BOARD_PAGE');
      setState(() {
        posts = [];
        isLoading = false;
      });
    }
  }

  // 기존 로컬 필터링 로직 유지 (받아온 API 데이터를 기준으로 필터링)
  List<Post> _filteredPosts(String category) {
    // 이미 API에서 category(tap)별로 받아왔지만, 안전을 위해 한 번 더 검사하거나
    // 현재 탭의 데이터만 보여주도록 함 (posts 리스트는 현재 탭 데이터로 갱신됨)
    final filtered = posts.where((post) {
      final regionMatch =
          selectedRegion == '전체' || post.region == selectedRegion;
      final genreMatch = selectedGenre == '전체' || post.genre == selectedGenre;

      // API에서 이미 해당 카테고리만 가져왔으므로 post.category 체크는 사실상 pass임
      return post.category == category && regionMatch && genreMatch;
    }).toList();

    // 최신순 정렬 (date 기준)
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
    // 💡 [변경] 글쓰기 완료 후 돌아왔을 때 API 재호출로 갱신
    // 반환값을 받지 않고(void), 돌아오면 무조건 갱신
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostWritePage(
          category: _tabController.index == 0 ? 'review' : 'matching',
        ),
      ),
    );

    // 글 작성 후 돌아오면 목록 새로고침
    _fetchPosts();
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
              // 💡 [변경] 로딩 중이면 인디케이터 표시
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildPostList('review'),
                  _buildPostList('matching'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
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
    // 💡 [API 참고] 실제 서버 페이징을 쓰지 않고, 가져온 데이터를 로컬에서 페이징 처리하여
    // 기존의 페이지네이션 UI (1, 2, 3 숫자 버튼)를 그대로 유지함
    final totalPages = (_getFilteredCount(category) / postsPerPage).ceil();

    final bottomPadding = MediaQuery.of(context).padding.bottom + 72.0;

    if (posts.isEmpty && currentPage == 1) {
      return const Center(child: Text("게시물이 없습니다."));
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding),
      // posts.length + 1은 페이지네이션 버튼 공간 확보
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index == posts.length) {
          // 페이지네이션 버튼
          if (totalPages <= 1) return const SizedBox.shrink(); // 1페이지 뿐이면 숨김

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
                    // 태그 (지역/장르) - 서버 데이터 반영
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
                    // 제목
                    Text(
                      post.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // 하단 정보 (임의 값 포함)
                    Row(
                      children: [
                        Text('작성자: ${post.author}'), // 임의값 (익명)
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye, size: 16),
                            const SizedBox(width: 4),
                            Text('${post.views}'), // 임의값 (0)
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(Icons.thumb_up, size: 16),
                            const SizedBox(width: 4),
                            Text('${post.likes}'), // 임의값 (0)
                          ],
                        ),
                        const Spacer(),
                        Text(
                          post.date.toLocal().toString().split(' ')[0].replaceAll('-', '.'),
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