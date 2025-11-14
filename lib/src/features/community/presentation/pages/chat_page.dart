import 'package:flutter/material.dart';

class Message{
  final String sender;
  final String text;
  final DateTime time;
  Message({required this.sender,required this.text,required this.time});
}

class ChatRoom {
  final String id;
  final String title;
  final List<String> participants;
  final List<Message> messages;

  ChatRoom({
    required this.id,
    required this.title,
    required this.participants,
    required this.messages,
  });
}



class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // 더미 채팅방 데이터
  String _formatDateTime(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return '$year년$month월$day일 $hour:$minute';
  }
  List<ChatRoom> chatRooms = [//Message 부분이 많이 필요없음 마지막 1개만 있으면 됨
    ChatRoom(
      id: 'room1',
      title: '구미라면 축제',
      participants: ['나', '이훈이', '맹구'],
      messages: [
        Message(sender: '맹구', text: '다들 시간 맞춰 도착하실 거죠? >.<',time: DateTime.now()),
        Message(sender: '이훈이', text: '어디에서 모이기로 했죠?',time: DateTime.now()),
        Message(sender: '나', text: '구미역입니당',time: DateTime.now()),
      ],
    ),
    ChatRoom(
      id: 'room2',
      title: '구미 K-POP 콘서트',
      participants: ['나', '김철수', '신짱구'],
      messages: [
        Message(sender: '김철수', text: '저 금오공대 앞이에요 다들 어디에요?',time: DateTime.now()),
        Message(sender: '신짱구', text: '저 지금 버스안입니다.',time: DateTime.now()),
        Message(sender: '나', text: '아.. 죄송해요 지금 출발합니다',time: DateTime.now()),
      ],
    ),
    ChatRoom(
      id: 'room3',
      title: '브래멘 음악대 - 구미',
      participants: ['나', '봉미선'],
      messages: [
        Message(sender: '봉미선', text: '저 롯데마트 앞에 노란 모자쓴 5살 아이랑 같이 있어요',time: DateTime.now()),
        Message(sender: '나', text: '저기 보이네요',time: DateTime.now()),
        Message(sender: '봉미선', text: '오늘 아이들이 너무 잘 놀아서 저도 즐거웠어요.',time: DateTime.now()),
        Message(sender: '봉미선', text: '다음에 또 뵐 수 있으면 좋겠네요 :)',time: DateTime.now()),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: (){Navigator.push(context,MaterialPageRoute(builder: (_)=>ChatSearchPage(allRooms: chatRooms),));}, icon: const Icon(Icons.search))],
        title: Align(
          alignment: Alignment.centerLeft,
          child: const Text(
            '채팅',
            style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatRooms[index];
          final lastMsg = room.messages.isNotEmpty
              ? room.messages.last.text
              : "메시지가 없습니다";
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.lightBlue,
              child: Text(room.title[0], style: const TextStyle(color: Colors.white)),
              //backgroundImage: NetworkImage(),
            ),
            title: Text(room.title),
            subtitle: Text(lastMsg),
            trailing: Text( _formatDateTime(room.messages.last.time), style: TextStyle(color: Colors.grey[600], fontSize: 12),),
            onTap: () async {
              final updatedRoom = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomPage(chatRoom: room),
                ),
              );
              if (updatedRoom != null && updatedRoom is ChatRoom) {
                setState(() {
                  chatRooms[index] = updatedRoom;
                });
              }
            },
          );
        },
      ),
    );
  }
}


class ChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom;
  const ChatRoomPage({super.key, required this.chatRoom});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late ChatRoom currentRoom;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();//텍스트 입력창
  String _formatDateTime(DateTime date) {
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  @override
  void initState() {// 초기화
    super.initState();
    currentRoom = widget.chatRoom;
  }

  void _sendMessage() {
    final text = _controller.text.trim();//공백제거
    if (text.isEmpty) return;

    setState(() {
      currentRoom.messages.add(Message(sender: '나', text: text,time: DateTime.now()));//메세지를 추가 지금은 그냥 리스트에 추가
    });
    WidgetsBinding.instance.addPostFrameCallback((_){
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,duration: Duration(milliseconds: 900),curve: Curves.easeOut,);//스크롤 내리기
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentRoom.title),//채팅방 제목
        backgroundColor: Colors.lightBlue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: currentRoom.messages.length,//리스트 수
              itemBuilder: (context, index) {
                final msg = currentRoom.messages[index];//채팅방의 메세지를 가져옴
                final isMe = msg.sender == '나';
                return Container(//개별 메시지 처리
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment://내가 보낸 메시지는 오른쪽 상대방 메시지는 왼쪽
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //내 메시지는 프로필 안보이게 상대는 보이게
                      if (!isMe)
                        GestureDetector(
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.lightBlue,
                            child: Text(
                              msg.sender[0], // 이름의 첫 글자
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          onTap: (){
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('프로필'),
                                  content: const Text('일단 눌림'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // 닫기
                                      },
                                      child: const Text('닫기'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(width: 8),
                      Flexible(//말풍선? 대화칸? 틀
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            //이름표시
                            if (!isMe)
                              Padding(
                                padding:
                                const EdgeInsets.only(left: 4, bottom: 2),
                                child: Text(
                                  msg.sender,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            //실제 말풍선박스
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: isMe//'나' 파란색 상대방은 회색
                                    ? Colors.lightBlue
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.only(//한쪽 모서리만 각지게
                                  topLeft: isMe ? const Radius.circular(24):const Radius.circular(4)  ,
                                  topRight: const Radius.circular(24),
                                  bottomLeft: const Radius.circular(24),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4,),
                                  Text(_formatDateTime(msg.time),style: TextStyle(color: isMe ? Colors.white70 : Colors.black54,fontSize: 7),)
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          //대화 입력창
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "메시지를 입력하세요...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.lightBlue),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

//@override
//void dispose() {//종료
//Navigator.pop(context, currentRoom); //종료할 때 갱신된 객체를 반환  Navigator.pop().. 종료할때 쓰는건데 종료할 때 종료할~~ 아무튼 뭔가 이상함.. 나중에 채팅 연결할 때 생각해볼 것 보내면서 바로 연동하는게 맞나?
//super.dispose();
//}

//return WillPopScope(
//onWillPop: () async {
//Navigator.pop(context, currentRoom);
//return false; // 직접 pop 했으므로 기본 pop 막기
//} child: Sca~~~
}

class ProfilePageInChat extends StatefulWidget {//채팅방에서 이름을 눌렀을 때 나올 위젯
  @override
  State<ProfilePageInChat> createState() => _ProfilePageInChat();
}

class _ProfilePageInChat extends State<ProfilePageInChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
      ],),
      appBar: AppBar(title: Text('')),
    );
  }
}

//채팅방 검색
class ChatSearchPage extends StatefulWidget {
  final List<ChatRoom> allRooms;
  const ChatSearchPage({super.key, required this.allRooms});
  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  TextEditingController _controller = TextEditingController();
  List<ChatRoom> filtered = [];
  @override
  void initState() {
    super.initState();
    filtered = widget.allRooms; // 초기 전체 표시
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: "채팅방 이름 검색...",
              border: InputBorder.none,
            ),
            onChanged: (value) {//입력이 올 때마다 갱신
              setState(() {
                filtered = widget.allRooms
                    .where((room) =>
                    room.title.toLowerCase().contains(value.trim().toLowerCase()))
                    .toList();
              });
            },
          ),
        ),
        body: filtered.isEmpty ? const Center(child: Text('검색 결과가 없습니다.'),)
            :ListView.builder(itemCount: filtered.length,
          itemBuilder: (context, i){
            final room = filtered[i];
            return ListTile(title: Text(room.title),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomPage(chatRoom: room),
                ),),);
          },
        )
    );
  }
}