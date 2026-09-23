class BusinessPost {
  final String id;
  final String businessProfileId;
  final String title;
  final String? content;
  final String type; // 'I HAVE' or 'I NEED'
  final String? materialCategory;
  final String? quantity;
  final DateTime createdAt;

  const BusinessPost({
    required this.id,
    required this.businessProfileId,
    required this.title,
    this.content,
    this.type = 'I HAVE',
    this.materialCategory,
    this.quantity,
    required this.createdAt,
  });

  factory BusinessPost.fromJson(Map<String, dynamic> json) {
    return BusinessPost(
      id: json['id']?.toString() ?? '',
      businessProfileId: json['businessProfileId']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      type: json['type'] as String? ?? 'I HAVE',
      materialCategory: json['materialCategory'] as String?,
      quantity: json['quantity'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessProfileId': businessProfileId,
      'title': title,
      'content': content,
      'type': type,
      'materialCategory': materialCategory,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
