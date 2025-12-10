// lib/src/features/chat/data/chat_model.dart

class UserProfile {
  final String name;

  UserProfile({
    required this.name,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
    );
  }
}

class Message {
  final String sender;
  final String text;
  final DateTime time;

  Message({required this.sender, required this.text, required this.time});

  factory Message.fromJson(Map<String, dynamic> json) {
    // 서버 응답 키에 맞게 수정 (senderName, content, timestamp)
    final rawTime = json['timestamp'] ?? json['time'] ?? json['createdAt'] ?? '';
    DateTime parsedTime;
    if (rawTime is String && rawTime.isNotEmpty) {
      try {
        parsedTime = DateTime.parse(rawTime);
      } catch (_) {
        parsedTime = DateTime.now();
      }
    } else {
      parsedTime = DateTime.now();
    }

    return Message(
      sender: json['senderName']?.toString() ?? json['sender']?.toString() ?? '',
      text: json['content']?.toString() ?? json['text']?.toString() ?? '',
      time: parsedTime,
    );
  }
}

class ChatRoom {
  final String id;
  final String title; // title 필드 추가
  final List<UserProfile> participants;
  List<Message> messages; // 이제부터는 상태에 따라 변경될 수 있음
  final String? _lastMessageText;
  final DateTime? _lastMessageTime;

  ChatRoom({
    required this.id,
    required this.title,
    required this.participants,
    required this.messages,
    String? lastMessageText,
    DateTime? lastMessageTime,
  })  : _lastMessageText = lastMessageText,
        _lastMessageTime = lastMessageTime;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    List<UserProfile> participants = [];
    if (json['participants'] is List) {
      participants = (json['participants'] as List)
          .map((p) => UserProfile(name: p.toString()))
          .toList();
    }

    List<Message> messages = [];

    String title = json['title']?.toString() ?? '';
    if (title.isEmpty) {
      final names = participants.map((p) => p.name).where((n) => n.isNotEmpty).toList();
      title = names.isNotEmpty ? names.join(', ') : '채팅방';
    }

    String? lastMessageText;
    DateTime? lastMessageTime;
    if (json['lastMessage'] is Map) {
      lastMessageText = json['lastMessage']['text']?.toString();
      final rawTime = json['lastMessage']['timestamp']?.toString();
      if (rawTime != null) {
        lastMessageTime = DateTime.tryParse(rawTime);
      }
    }

    return ChatRoom(
      id: id,
      title: title,
      participants: participants,
      messages: messages,
      lastMessageText: lastMessageText,
      lastMessageTime: lastMessageTime,
    );
  }

  String get lastMessageText => messages.isNotEmpty ? messages.last.text : _lastMessageText ?? '';
  DateTime? get lastMessageTime => messages.isNotEmpty ? messages.last.time : _lastMessageTime;
}