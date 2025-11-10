import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/features/community/dummy_posts.dart';
import 'package:flutter/material.dart';

import 'post_detail_page.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({Key? key}) : super(key: key);

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String selectedRegion = '전국';
  String selectedSubRegion = '전체';
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

  int currentPage = 1;
  final int postsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Post> _filteredPosts(String category) {
    final filtered = dummyPosts.where((post) {
      final regionMatch =
          selectedRegion == '전국' || post.region == selectedRegion;
      final subRegionMatch =
          selectedSubRegion == '전체' || post.subRegion == selectedSubRegion;
      final genreMatch = selectedGenre == '전체' || post.genre == selectedGenre;
      return post.category == category &&
          regionMatch &&
          subRegionMatch &&
          genreMatch;
    }).toList();

    final startIndex = (currentPage - 1) * postsPerPage;
    final endIndex = (startIndex + postsPerPage) > filtered.length
        ? filtered.length
        : (startIndex + postsPerPage);
    return filtered.sublist(startIndex, endIndex);
  }

  int _getFilteredCount(String category) {
    return dummyPosts.where((post) {
      final regionMatch =
          selectedRegion == '전국' || post.region == selectedRegion;
      final subRegionMatch =
          selectedSubRegion == '전체' || post.subRegion == selectedSubRegion;
      final genreMatch = selectedGenre == '전체' || post.genre == selectedGenre;
      return post.category == category &&
          regionMatch &&
          subRegionMatch &&
          genreMatch;
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

    String subRegion = '전체';
    if (region != '전국') {
      final selectedSub = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('세부지역 선택'),
          children: subRegions[region]!
              .map((sub) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, sub),
            child: Text(sub),
          ))
              .toList(),
        ),
      );

      if (selectedSub != null) subRegion = selectedSub;
    }

    setState(() {
      selectedRegion = region;
      selectedSubRegion = subRegion;
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
    if (selectedRegion == '전국') return '지역: 전국';
    if (selectedSubRegion == '전체') return '지역: $selectedRegion';
    return '지역: $selectedRegion > $selectedSubRegion';
  }

  String getGenreDisplayText() {
    return '장르: $selectedGenre';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
          // 필터 영역 (개선: 한 줄에 두 버튼)
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

          // 게시글 리스트 영역
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
    );
  }

  Widget _buildPostList(String category) {
    final posts = _filteredPosts(category);
    final totalPages = (_getFilteredCount(category) / postsPerPage).ceil();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index == posts.length) {
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