import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import '../../../../core/config/app_config.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  // Shown immediately on send; replaced by the saved copy when the server echoes it.
  final bool pending;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.pending = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt']).toLocal();
    final senderId = json['senderId']?.toString().toLowerCase();
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['content'] ?? '',
      // History sends isMe; live messages are matched on the sender instead.
      isMe:
          json['isMe'] as bool? ??
          (senderId != null &&
              senderId == AppConfig.currentBusinessId.toLowerCase()),
      time: DateFormat.jm().format(createdAt),
    );
  }
}

class ChatPage extends ConsumerStatefulWidget {
  /// Listing of the conversation on screen, so it isn't also shown as a notification.
  static String? openListingId;

  final MaterialListing listing;
  // The other person in this conversation (the seller for a buyer, the buyer
  // for a seller replying from the inbox).
  final String receiverId;
  final String? partnerName;

  const ChatPage({
    super.key,
    required this.listing,
    required this.receiverId,
    this.partnerName,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  HubConnection? _hubConnection;
  bool _isLoading = true;

  String get _partnerName =>
      widget.partnerName ?? widget.listing.companyName ?? 'Unknown Company';
  String get _partnerInitial => _partnerName.isNotEmpty
      ? _partnerName.substring(0, 1).toUpperCase()
      : 'U';

  @override
  void initState() {
    super.initState();
    ChatPage.openListingId = widget.listing.id;
    _initChat();
  }

  Future<void> _initChat() async {
    await _fetchHistory();
    await _connectSignalR();
  }

  Future<void> _fetchHistory() async {
    try {
      // ApiClient refreshes the access token on 401 (it expires after 15 min).
      final response = await ref.read(apiClientProvider).get(
        // Only this conversation (a seller can be chatting with several buyers).
        '/api/chat/history/${widget.listing.id}',
        queryParameters: {'with': widget.receiverId},
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages = data.map((json) => ChatMessage.fromJson(json)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        print('Error fetching history: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectSignalR() async {
    // Read the token on every (re)connect so a refreshed one is picked up.
    final authRepository = ref.read(authRepositoryProvider);

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          "http://10.0.2.2:5252/chatHub",
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                await authRepository.getSavedToken() ?? '',
          ),
        )
        .build();

    _hubConnection!.on("ReceiveMessage", _handleReceiveMessage);

    try {
      await _hubConnection!.start();
      print("SignalR Connected");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }

  void _handleReceiveMessage(List<Object?>? args) {
    if (args == null || args.isEmpty || !mounted) return;
    final msgData = Map<String, dynamic>.from(args[0] as Map);

    // Only messages for this listing and this conversation partner.
    if (msgData['listingId']?.toString().toLowerCase() !=
        widget.listing.id.toLowerCase()) {
      return;
    }
    final partner = widget.receiverId.toLowerCase();
    final senderId = msgData['senderId']?.toString().toLowerCase();
    final receiverId = msgData['receiverId']?.toString().toLowerCase();
    if (senderId != partner && receiverId != partner) return;

    final incoming = ChatMessage.fromJson(msgData);
    if (_messages.any((m) => m.id == incoming.id)) return;

    setState(() {
      if (incoming.isMe) {
        // The server echoes our own message back: replace the optimistic copy
        // instead of adding it again (that showed it a second time, on the
        // receiver's side of the chat).
        final i = _messages.indexWhere(
          (m) => m.pending && m.text == incoming.text,
        );
        if (i >= 0) {
          _messages[i] = incoming;
          return;
        }
      }
      _messages.add(incoming);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    if (ChatPage.openListingId == widget.listing.id) ChatPage.openListingId = null;
    _hubConnection?.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Add locally immediately for responsive UI; the server's echo replaces it.
    final tempId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _messages.add(
        ChatMessage(
          id: tempId,
          text: text,
          isMe: true,
          time: DateFormat.jm().format(DateTime.now()),
          pending: true,
        ),
      );
    });
    _scrollToBottom();

    try {
      if (_hubConnection?.state != HubConnectionState.Connected) {
        await _hubConnection?.start();
      }
      await _hubConnection!.invoke(
        "SendMessage",
        args: [widget.listing.id, widget.receiverId, text],
      );
    } catch (e) {
      // Don't leave a message on screen that was never delivered.
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m.id == tempId));
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Message not sent. Check your connection and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.mintGreen,
              radius: 18,
              child: Text(
                _partnerInitial,
                style: const TextStyle(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _partnerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.ecoGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Contextual Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.slateGray.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.ecoGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.listing.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.listing.isIHave
                            ? '\$${widget.listing.price.toStringAsFixed(0)} / ${widget.listing.priceUnit}'
                            : 'Wanted',
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View Item',
                    style: TextStyle(color: AppColors.ecoGreen),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.forestGreen,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildChatBubble(message);
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.slateGray.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.slateGray,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attachments coming soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.mintGreen),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines:
                            null, // Allows the field to grow vertically if they type a lot
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        // Note: onSubmitted doesn't work well with multiline, but we have the send button
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.forestGreen,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isMe) ...[
                CircleAvatar(
                  backgroundColor: AppColors.mintGreen,
                  radius: 12,
                  child: Text(
                    _partnerInitial,
                    style: const TextStyle(
                      color: AppColors.forestGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isMe
                        ? AppColors.forestGreen
                        : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                      bottomRight: Radius.circular(message.isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.slateGray.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe
                          ? AppColors.white
                          : AppColors.darkCharcoal,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: message.isMe ? 0 : 32,
              right: message.isMe ? 4 : 0,
            ),
            child: Text(
              message.time,
              style: const TextStyle(fontSize: 10, color: AppColors.slateGray),
            ),
          ),
        ],
      ),
    );
  }
}
