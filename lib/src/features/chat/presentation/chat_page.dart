import 'package:cultureyo/src/features/chat/data/chat_model.dart';
import 'package:cultureyo/src/features/chat/service/chat_service.dart';
import 'package:cultureyo/src/features/profile/domain/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// --- 채팅방 목록 페이지 ---
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatService _chatService;
  late Future<List<ChatRoom>> _chatRoomsFuture;

  @override
  void initState() {
    super.initState();
    _chatService = context.read<ChatService>();
    _loadChatRooms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }


  void _loadChatRooms() {
    setState(() {
      _chatRoomsFuture = _chatService.findMyRoom();
    });
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('a hh:mm', 'ko_KR').format(date);
    } else {
      // 이전에 받은 메시지: "yy.MM.dd" 형식
      return DateFormat('yy.MM.dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [ChatPage] 배경색
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          '채팅',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue[200],
        centerTitle: true,
        actions: const [],
      ),
      body: FutureBuilder<List<ChatRoom>>(
        future: _chatRoomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('채팅방이 없습니다.'));
          }

          final chatRooms = snapshot.data!;
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              return Padding(
                // 항목 간 수직 간격 줄임
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                // 카드 형식 적용
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.lightBlue,
                      child: Text(
                        room.title.isNotEmpty ? room.title[0] : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      room.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      room.lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatDateTime(room.lastMessageTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomPage(chatRoom: room),
                        ),
                      );
                      // 채팅방에서 돌아왔을 때 목록을 새로고침
                      _loadChatRooms();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 개별 채팅방 페이지 ---
class ChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomPage({super.key, required this.chatRoom});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late ChatRoom currentRoom;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  late ChatService _chatService;
  late UserService _userService;
  late IO.Socket _socket;
  bool _isLoadingMessages = true;
  String _myUsername='';

  @override
  void initState() {
    super.initState();
    currentRoom = widget.chatRoom;
    _chatService = context.read<ChatService>();
    _userService = context.read<UserService>();
    _initializeChat();
  }

  Future<void > _initializeChat() async {
    await _loadUserName();
    _initSocket();
    await _fetchMessages();
  }

  Future<void> _loadUserName() async {
    try {
      final username = await _userService.loadUserName();
      if (mounted) {
        setState(() {
          _myUsername = username['name'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 정보를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  void _initSocket() {
    _socket = IO.io(
        'https://dartroll-nodejs-sub.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      if (kDebugMode) {
        print('Socket connected');
      }
      _socket.emit('joinRoom',currentRoom.id);
    });

    _socket.on('receiveMessage', (data) {
      final message = Message.fromJson(data);
      if (message.sender != _myUsername) {
        if (mounted) {
          setState(() {
            currentRoom.messages.add(message);
          });
        }
        _scrollToBottom(animated: true);
      }
    });

    _socket.onDisconnect((_) {
      if( kDebugMode) {
        print('Socket disconnected');
      }
    });

    _socket.onError((data)=>
    {
      if (kDebugMode) print('Socket error: $data')
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final messages = await _chatService.getMessages(currentRoom.id);
      if (!mounted) return;
      setState(() {
        currentRoom.messages = messages;
        _isLoadingMessages = false;
      });
      _scrollToBottom(animated: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지를 불러오는 데 실패했습니다.')),
      );
    }
  }

  void _sendMessage()  {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final messageData = {
      'senderName': _myUsername,
      'roomId': currentRoom.id,
      'content':text,
    };

    _socket.emit('sendMessage', messageData);

    final tempMessage = Message(
        sender: _myUsername,
        text: text,
        time: DateTime.now()
    );

    // 낙관적 UI 업데이트
    setState(() {
      currentRoom.messages.add(tempMessage);
    });
    _textController.clear();
    _scrollToBottom(animated: true);
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  String _formatMessageTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, currentRoom);
        return true;
      },
      child: Scaffold(
        // [ChatRoomPage] 배경색
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          backgroundColor: Colors.blue[200],
          title: Text(
            currentRoom.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: currentRoom.messages.length,
                itemBuilder: (context, index) {
                  final msg = currentRoom.messages[index];
                  final isMe = msg.sender == _myUsername;

                  bool showProfile = true;
                  if (index > 0) {
                    final prev = currentRoom.messages[index - 1];
                    if (prev.sender == msg.sender) {
                      showProfile = false;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe)
                          Visibility(
                            visible: showProfile,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: CircleAvatar(
                              radius: 18,
                              // 상대방 프로필 배경색 흰색
                              backgroundColor: Colors.white,
                              child: Text(msg.sender.isNotEmpty
                                  ? msg.sender[0]
                                  : '?'),
                            ),
                          ),
                        const SizedBox(width: 8),

                        // 메시지 버블 및 시간 영역
                        Flexible(
                          child: Row( // 시간과 버블을 좌우로 배치
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [

                              // 내 메시지 시간
                              if (isMe)
                                Padding(
                                  padding:
                                  const EdgeInsets.only(right: 4),
                                  child: Text(
                                    _formatMessageTime(msg.time),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 10),
                                  ),
                                ),

                              // 메시지 버블 Container
                              Flexible( // 줄 바꿈 및 최대 너비 제한
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    // 내 채팅/상대방 채팅 모두 흰색 배경
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: const TextStyle(
                                      // 내 채팅/상대방 채팅 모두 검정색 글자
                                        color: Colors.black87),
                                  ),
                                ),
                              ),

                              // 상대방 메시지 시간
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    _formatMessageTime(msg.time),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 10),
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
            SafeArea(
              // 🌟 🌟 🌟 [수정 부분]: 댓글 입력창 디자인 통일
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                // 1. Container 배경색: 게시판과 동일하게 Colors.blue[200]
                color: Colors.blue[200],
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "메시지를 입력하세요...",
                          // 2. TextField 스타일: 둥근 테두리 및 흰색 채우기
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 3. 전송 버튼: 게시판 디자인과 유사하게 흰색 배경의 동그란 버튼
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.lightBlue,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}