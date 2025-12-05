// lib/src/features/community/presentation/pages/board_page.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 💡 [추가] Provider 사용을 위해 임포트
import 'package:dio/dio.dart'; // 💡 [추가] DioException 처리를 위해 임포트

// ⭐ [추가] PostService import
import 'package:cultureyo/src/features/community/service/post_service.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';

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

  // 💡 [변경] PostService 인스턴스를 직접 생성하지 않고, Provider로 주입받을 변수로 선언
  late PostService _postService;

  String selectedRegion = '전체';
  String selectedGenre = '전체';

  final int postsPerPage = 5;

  final List<String> regions = [
    '전체', '강원', '경기', '경남', '경북', '광주', '대구', '대전', '부산', '서울', '세종', '울산', '인천', '지역 미정'
  ];

  final List<String> genres = [
    '전체', '국악', '기타', '무용/발레', '뮤지컬/오페라', '연극', '음악/콘서트', '전시', '행사/축제', '교육/체험'
  ];

  int currentPage = 1;

  List<Post> posts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          currentPage = 1;
        });
        _fetchPosts();
      }
    });

    // 🚨 [변경] _fetchPosts()를 initState에서 제거하고 didChangeDependencies()로 옮김
    // _fetchPosts();
  }

  // 💡 [추가] Service 인스턴스를 context를 통해 가져오는 메서드
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context.read를 사용하여 Service 인스턴스를 가져옵니다.
    _postService = context.read<PostService>();

    // 최초 목록 로드 실행 (initState의 역할을 대신)
    if (posts.isEmpty && !isLoading) {
      _fetchPosts();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ⭐ [수정] _fetchPosts 함수: DioException 처리 구조 추가
  Future<void> _fetchPosts() async {
    // 💡 _postService가 초기화되지 않았다면 바로 리턴 (안전 장치)
    if (!mounted || _postService == null) return;

    setState(() {
      isLoading = true;
    });

    final String category = _tabController.index == 0 ? 'review' : 'matching';

    log('🔍 [CALL_SERVICE] Fetching posts for category: $category', name: 'BOARD_PAGE');

    try {
      // ⭐ PostService의 fetchPosts 함수 호출
      final fetchedPosts = await _postService.fetchPosts(category);

      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });

    } on DioException catch (e) { // 💡 [추가] DioException 처리
      log('🚨 [DIO_ERROR] Failed to fetch posts: ${e.message}', name: 'BOARD_PAGE');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시물 로드 실패: ${e.message}')),
        );
      }
      setState(() {
        posts = [];
        isLoading = false;
      });
    } catch (e) {
      log('🚨 [SERVICE_ERROR] Failed to fetch posts: $e', name: 'BOARD_PAGE');
      setState(() {
        posts = [];
        isLoading = false;
      });
    }
  }

  // ----------------------------------------------------
  // [유지] 기존 로컬 필터링, 페이지네이션, 지역/장르 선택, UI 구성 로직은 그대로 유지
  // ----------------------------------------------------

  List<Post> _filteredPosts(String category) {
    // ... 로직 유지 ...
    final filtered = posts.where((post) {
      final regionMatch =
          selectedRegion == '전체' || post.region == selectedRegion;
      final genreMatch = selectedGenre == '전체' || post.genre == selectedGenre;

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
    // ... 로직 유지 ...
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
    // ... 로직 유지 ...
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
    // ... build 로직 유지 ...
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
    // ... _buildPostList 로직 유지 ...
    final posts = _filteredPosts(category);
    final totalPages = (_getFilteredCount(category) / postsPerPage).ceil();

    final bottomPadding = MediaQuery.of(context).padding.bottom + 72.0;

    if (posts.isEmpty && currentPage == 1) {
      return const Center(child: Text("게시물이 없습니다."));
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index == posts.length) {
          if (totalPages <= 1) return const SizedBox.shrink();

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
          onTap: () async {
            try {
              // 1. ⭐ [수정] PostService의 increaseViewCount 함수 호출 (Dio/Provider 사용)
              await _postService.increaseViewCount(post.id, post.category);

              // 2. 상세 페이지로 이동하며 복귀를 기다림 (await)
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
              );

              // 3. 상세 페이지에서 돌아왔을 때 목록을 새로고침하여 조회수 갱신
              _fetchPosts();

            } on DioException catch (e) {
              log('🚨 [DIO_ERROR] Failed to increase view count: ${e.message}', name: 'BOARD_PAGE_VIEW');
              if(mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('조회수 증가 실패: ${e.message}')),
                );
              }
            } catch (e) {
              log('🚨 [SERVICE_ERROR] Failed to increase view count: $e', name: 'BOARD_PAGE_VIEW');
            }
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