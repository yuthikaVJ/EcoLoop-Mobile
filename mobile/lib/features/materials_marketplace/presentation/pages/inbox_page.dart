import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    // Ideally, the backend would have an endpoint `GET /api/chat/inbox` 
    // Since we didn't build it yet, I will mock it or add it later if we need a full list.
    // For now, I'll just show a coming soon or mock list until backend is updated.
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(child: Text('No messages yet!'))
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return ListTile(
                      title: Text('Chat about ${chat['listingTitle']}'),
                      subtitle: Text(chat['lastMessage'] ?? ''),
                      onTap: () {
                        // We would navigate to chat page here
                      },
                    );
                  },
                ),
    );
  }
}
