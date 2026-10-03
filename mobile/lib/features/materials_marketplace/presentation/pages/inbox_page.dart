import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import 'chat_page.dart';

/// One conversation: a listing + the other business (from GET /api/chat/inbox).
class _Conversation {
  final MaterialListing listing;
  final String otherId;
  final String otherName;
  final String lastMessage;
  final bool lastMessageIsMe;
  final DateTime lastMessageAt;

  _Conversation.fromJson(Map<String, dynamic> json)
    : listing = MaterialListing(
        id: json['listingId'].toString(),
        businessId: json['listingBusinessId']?.toString(),
        title: json['listingTitle'] as String? ?? 'Listing',
        category: json['listingCategory'] as String? ?? '',
        quantity: json['listingQuantity'] as String? ?? '',
        unit: json['listingUnit'] as String? ?? '',
        location: json['listingLocation'] as String? ?? '',
        price: (json['listingPrice'] as num?)?.toDouble() ?? 0,
        priceUnit: json['listingPriceUnit'] as String? ?? '',
        companyName: json['listingSeller'] as String?,
        isVerifiedSeller: false,
        isIHave: (json['listingType'] as num?)?.toInt() != 1,
        status: (json['listingStatus'] as num?)?.toInt() ?? 0,
        datePosted: DateTime.now(),
        imageUrl: json['listingImageUrl'] as String? ?? '',
      ),
      otherId = json['otherBusinessId'].toString(),
      otherName = json['otherBusinessName'] as String? ?? 'Unknown',
      lastMessage = json['lastMessage'] as String? ?? '',
      lastMessageIsMe = json['lastMessageIsMe'] == true,
      lastMessageAt = DateTime.parse(json['lastMessageAt'] as String).toLocal();
}

/// Inbox: every chat you're part of, as buyer or seller, so the seller can see
/// and reply to messages from buyers.
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  bool _isLoading = true;
  String? _error;
  List<_Conversation> _chats = [];

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    setState(() => _error = null);
    try {
      // ApiClient refreshes the access token on 401 (it expires after 15 min).
      final response = await ref
          .read(apiClientProvider)
          .get('/api/chat/inbox')
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('Could not load messages (${response.statusCode}).');
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _chats = data
            .map((x) => _Conversation.fromJson(x as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _open(_Conversation chat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          listing: chat.listing,
          receiverId: chat.otherId,
          partnerName: chat.otherName,
        ),
      ),
    );
    if (mounted) _fetchInbox();
  }

  String _when(DateTime at) {
    final now = DateTime.now();
    if (at.year == now.year && at.month == now.month && at.day == now.day) {
      return DateFormat.jm().format(at);
    }
    return DateFormat.MMMd().format(at);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.forestGreen,
              onRefresh: _fetchInbox,
              child: _error != null || _chats.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 160),
                        Icon(
                          _error != null
                              ? Icons.cloud_off_outlined
                              : Icons.chat_bubble_outline,
                          size: 56,
                          color: AppColors.slateGray,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _error ?? 'No messages yet',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.slateGray),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _chats.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return ListTile(
                          onTap: () => _open(chat),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.mintGreen,
                            child: Text(
                              chat.otherName.isNotEmpty
                                  ? chat.otherName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            chat.otherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat.listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ecoGreen,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${chat.lastMessageIsMe ? 'You: ' : ''}${chat.lastMessage}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Text(
                            _when(chat.lastMessageAt),
                            style: const TextStyle(
                              color: AppColors.slateGray,
                              fontSize: 12,
                            ),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
    );
  }
}
