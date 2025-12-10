import 'package:cultureyo/src/features/chat/data/chat_model.dart';
import 'package:cultureyo/src/features/chat/service/chat_service.dart';
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
      appBar: AppBar(
        title: const Text(
          '채팅',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        actions: [
          // 검색 버튼은 FutureBuilder 안으로 이동하여 데이터 로드 후 활성화
        ],
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
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.lightBlue,
                  child: Text(
                    room.title.isNotEmpty ? room.title[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(room.title),
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
  late final ChatService _chatService;
  late IO.Socket _socket;
  bool _isLoadingMessages = true;
  String _myUsername='';

  @override
  void initState() {
    super.initState();
    currentRoom = widget.chatRoom;
    _chatService = context.read<ChatService>();

    final participants = currentRoom.participants.map((p) => p.name).toList();
    _myUsername = participants.firstWhere(
          (name) => !currentRoom.title.contains(name),
      orElse: () => '나', // 만약 못찾으면 기본값
    );

    _fetchMessages();
    _initSocket();
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
        appBar: AppBar(
          title: Text(currentRoom.title),
          backgroundColor: Colors.lightBlue,
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
                                    backgroundColor: Colors.grey.shade300,
                                    child: Text(msg.sender.isNotEmpty
                                        ? msg.sender[0]
                                        : '?'),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.lightBlue
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        msg.text,
                                        style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black87),
                                      ),
                                    ),
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
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: "메시지를 입력하세요...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
      ),
    );
  }
}
