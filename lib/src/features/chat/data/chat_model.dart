// class UserProfile {
//   final String name;
//
//   UserProfile({
//     required this.name,
//   });
//
//   factory UserProfile.fromJson(Map<String, dynamic> json) {
//     return UserProfile(
//       name: json['name']?.toString() ?? json['username']?.toString() ?? '',
//       // profileImageUrl: json['profileImage']?.toString() ?? json['profileImageUrl']?.toString() ?? '',
//     );
//   }
// }
//
// class Message{
//   final String sender;
//   final String text;
//   final DateTime time;
//   Message({required this.sender, required this.text,required this.time});
//
//   factory Message.fromJson(Map<String, dynamic> json) {
//     final rawTime = json['time'] ?? json['createdAt'] ?? json['created_at'] ?? '';
//     DateTime parsedTime;
//     if (rawTime is String && rawTime.isNotEmpty) {
//       try {
//         parsedTime = DateTime.parse(rawTime);
//       } catch (_) {
//         parsedTime = DateTime.now();
//       }
//     } else {
//       parsedTime = DateTime.now();
//     }
//
//     return Message(
//       sender: json['name']?.toString() ?? json['sender']?.toString() ?? '',
//       text: json['text']?.toString() ?? '',
//       time: parsedTime,
//     );
//   }
//
//     Map<String, dynamic> toJson() => {
//       'name': sender,
//       'text': text,
//       'time': time.toIso8601String(),
//     };
// }
//
// class ChatRoom {
//   final String id;
//   final List<String> participants;
//   final List<Message> messages;
//
//   ChatRoom({
//     required this.id,
//     required this.participants,
//     required this.messages,
//   });
//
//   factory ChatRoom.fromJson(Map<String, dynamic> json) {
//     final id = json['id']?.toString() ?? json['_id']?.toString() ?? '';
//     // participants can be list of ids or objects
//     List<UserProfile> participants = [];
//     final rawParts = json['participants'];
//     if (rawParts is List) {
//       participants = rawParts.map<UserProfile>((p) {
//         if (p is Map<String, dynamic>) {
//           return UserProfile.fromJson(p);
//         } else {
//           return UserProfile(name: p?.toString() ?? '');
//         }
//       }).toList();
//     }
//
//     List<Message> messages = [];
//     final rawMsgs = json['messages'] ?? json['chat'] ?? [];
//     if (rawMsgs is List) {
//       messages = rawMsgs.map<Message>((m) {
//         if (m is Map<String, dynamic>) return Message.fromJson(m);
//         return Message(sender: '', text: m.toString(), time: DateTime.now());
//       }).toList();
//       messages.sort((a, b) => a.time.compareTo(b.time));
//     }
//
//     String title = json['title']?.toString() ?? '';
//     if (title.isEmpty) {
//       final names = participants.map((p) => p.name).where((n) => n.isNotEmpty).toList();
//       title = names.isNotEmpty ? names.join(', ') : (json['lastMessage']?.toString() ?? '채팅방');
//     }
//
//     return ChatRoom(id: id, participants: participants, messages: messages);
//   }
//
//   String get lastMessageText => messages.isNotEmpty ? messages.last.text : '';
//   DateTime? get lastMessageTime => messages.isNotEmpty ? messages.last.time : null;
// }