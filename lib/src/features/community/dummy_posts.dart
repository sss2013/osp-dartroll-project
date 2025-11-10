import 'package:cultureyo/src/features/community/data/post_model.dart';

final List<Post> dummyPosts = List.generate(15, (index) {
  return Post(
    id: (index + 1).toString(), // int -> String 변환
    category: index % 2 == 0 ? 'review' : 'friend',
    title: '공연 제목 ${index + 1}',
    content: '이 글의 내용 예시입니다. ${index + 1}',
    author: '닉네임${(index % 5) + 1}',
    region: ['서울', '부산', '대구'][index % 3],
    subRegion: '세부지역${(index % 2) + 1}',
    genre: ['뮤지컬', '연극', '콘서트'][index % 3],
    views: 10 + index,
    likes: 2 + index,
    date: DateTime.now().subtract(Duration(days: index)),
  );
});