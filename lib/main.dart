import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ⭐ CẤU HÌNH
const String FIREBASE_URL = 'https://chat-app-hung-default-rtdb.asia-southeast1.firebasedatabase.app';
const String EMAILJS_SERVICE_ID = 'service_xd4p0og';
const String EMAILJS_TEMPLATE_ID = 'template_e75vjj7';
const String EMAILJS_PUBLIC_KEY = '_ARGVipfVQPmHkUTt';
const String EMAIL_NHAN = 'hung.luongtien0707@gmail.com';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _nameController = TextEditingController(text: 'Khach');
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {'user': 'Bot', 'text': 'Go tin nhan de gui den app Nhan tin nhan.'},
  ];

  String _now() {
    final n = DateTime.now();
    return '${n.hour}:${n.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _guiFirebase(String ten, String noiDung) async {
    try {
      final url = '$FIREBASE_URL/messages.json';
      print('GUI DEN: $url');
      final r = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user': ten,
          'text': noiDung,
          'time': '${_now()} ${DateTime.now().day}/${DateTime.now().month}',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      print('STATUS: ${r.statusCode}');
      print('BODY: ${r.body}');
      if (r.statusCode == 200) {
        print('DA LUU FIREBASE OK');
      } else {
        print('LOI FIREBASE: ${r.body}');
      }
    } catch (e) {
      print('EXCEPTION: $e');
    }
  }

  Future<void> _guiEmail(String ten, String noiDung) async {
    try {
      final r = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json', 'origin': 'http://localhost'},
        body: jsonEncode({
          'service_id': EMAILJS_SERVICE_ID,
          'template_id': EMAILJS_TEMPLATE_ID,
          'user_id': EMAILJS_PUBLIC_KEY,
          'template_params': {
            'from_name': ten,
            'message': noiDung,
            'time': '${_now()} ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            'to_email': EMAIL_NHAN,
          },
        }),
      );
      print(r.statusCode == 200 ? 'DA GUI EMAIL' : 'LOI EMAIL: ${r.body}');
    } catch (e) {
      print('LOI EMAIL: $e');
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final ten = _nameController.text.trim().isEmpty ? 'Khach' : _nameController.text.trim();

    setState(() {
      _messages.add({'user': ten, 'text': text});
    });

    _guiFirebase(ten, text);
    _guiEmail(ten, text);

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({'user': 'Bot', 'text': 'Da gui den app Nhan tin nhan'});
      });
      _scrollToBottom();
    });

    _controller.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat (Nguoi gui)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.indigo.shade50,
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ten cua ban',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m['user'] != 'Bot';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.indigo : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(m['user']!,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white70 : Colors.black54)),
                        const SizedBox(height: 2),
                        Text(m['text']!,
                            style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Nhap tin nhan...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.indigo,
                    child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
