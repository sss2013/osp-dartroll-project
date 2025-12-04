// lib/src/features/community/presentation/pages/post_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:url_launcher/url_launcher.dart'; // 💡 [추가] 링크 열기 패키지

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late int likes;

  @override
  void initState() {
    super.initState();
    likes = widget.post.likes;
  }

  Widget _buildCategoryBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // 💡 [추가] 공연 상세 카드 위젯
  Widget _buildPerformanceCard(BuildContext context) {
    // Post 모델에 저장된 값이 없으면 카드를 표시하지 않음
    if (widget.post.performanceTitle == null || widget.post.performanceUrl == null) {
      return const SizedBox.shrink();
    }

    final displayTitle = widget.post.performanceTitle!;
    final url = widget.post.performanceUrl!;

    return Padding(
      // 내용 아래에 위치하므로 상단에 패딩을 줍니다.
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // 💡 [구현] 탭 시 외부 브라우저로 링크 열기
          onTap: () async {
            if (url.isNotEmpty) {
              final uri = Uri.parse(url);

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('링크를 열 수 없습니다.')),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue[50], // 배경색을 연한 파란색으로 설정
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
        ),
      ),
    );
  }

  Widget _buildCommentItem(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6), // 댓글간 여백
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 사용자 아이콘 + 닉네임 + 작성일
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                child: Icon(Icons.person, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '닉네임${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '2025-11-09',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 2. 댓글 내용
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              '댓글 내용 예시입니다. ${index + 1}',
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          // 3. 답글/추천/신고
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Row(
              children: [
                // 답글 버튼
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('답글(2)', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                // 추천 버튼
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.thumb_up, size: 14),
                        SizedBox(width: 4),
                        Text('3', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // 신고 버튼 + 아이콘
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.report, size: 14, color: Colors.red),
                  label: const Text('신고하기', style: TextStyle(fontSize: 12, color: Colors.red)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    minimumSize: const Size(0, 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '게시글 상세',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 박스
                  Wrap(
                    spacing: 4,
                    children: [
                      _buildCategoryBox(widget.post.region),
                      _buildCategoryBox(widget.post.genre),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 제목
                  Text(
                    widget.post.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  // 작성자 / 조회 / 추천 / 날짜
                  Row(
                    children: [
                      Expanded(
                        child: Text('작성자: ${widget.post.author}'),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye, size: 16),
                          const SizedBox(width: 4),
                          Text('${widget.post.views}'),
                          const SizedBox(width: 12),
                          const Icon(Icons.thumb_up, size: 16),
                          const SizedBox(width: 4),
                          Text('$likes'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${widget.post.date.year}.${widget.post.date.month.toString().padLeft(2, '0')}.${widget.post.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // 글 내용
                  Text(widget.post.content, style: const TextStyle(fontSize: 16)),

                  // 🚨 [핵심 수정] 내용 바로 아래에 공연 카드 표시
                  _buildPerformanceCard(context),

                  const SizedBox(height: 16),

                  // 추천 버튼
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          likes += 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.thumb_up, size: 20, color: Colors.black),
                            SizedBox(width: 6),
                            Text(
                              '추천하기',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  // 댓글
                  const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) => _buildCommentItem(index),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // 댓글 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    enabled: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}