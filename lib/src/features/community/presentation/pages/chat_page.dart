import 'package:cultureyo/src/features/community/service/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class UserProfile {
  final String id;
  final String name;
  final String profileImageUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.profileImageUrl,
  });
}

class Message{
  final String sender;//나중에 UserProfile로 바꾸던지 해야할듯
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
  late final ChatService _chatService;

  @override
  void initState() {// 초기화
    super.initState();
    currentRoom = widget.chatRoom;
    _chatService = context.read<ChatService>();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();//공백제거
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(currentRoom.id, text);
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 전송에 실패했습니다: $e')),
      );
      return;
    }

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
                bool showProfile = true;
                if (index > 0) {
                  final prev = currentRoom.messages[index - 1];
                  if (prev.sender == msg.sender) {
                    showProfile = false; // 같은 사람이면 숨김
                  }
                }
                return Container(//개별 메시지 처리
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment://내가 보낸 메시지는 오른쪽 상대방 메시지는 왼쪽
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //내 메시지는 프로필 안보이게 상대는 보이게
                      Visibility(
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        visible:(!isMe && showProfile),
                        child: GestureDetector(
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.lightBlue,
                            child: Text(
                              msg.sender[0], // 이름의 첫 글자
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          onTap: (){
                            showUserProfile(
                              context,
                              UserProfile(
                                  id: '1', // Todo: sender.~~로 바꾸기
                                  name: msg.sender,
                                  profileImageUrl: 'a'//msg.profileImage,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(//말풍선? 대화칸? 틀
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            //이름표시
                            if (!isMe && showProfile)
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
void showUserProfile(BuildContext context, UserProfile user) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 프로필 사진
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user.profileImageUrl),
              ),
              const SizedBox(height: 12),
              // 이름
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // 1:1 채팅
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // 프로필 닫기
                    // TODO: user.id로 1대1 채팅방으로 이동시키기
                  },
                  child: const Text("1:1 채팅하기"),
                ),
              ),
              const SizedBox(height: 10),
              // 신고 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('신고'),
                        content: Text("${user.name} 님을 신고하시겠습니까?"),
                        actions: [
                          TextButton(
                            child: const Text("취소"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: const Text(
                              "신고하기",
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: 신고 처리 추가
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    "신고하기",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 닫기 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '닫기',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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