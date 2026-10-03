/// One side of an AI match: a marketplace post.
class MatchListing {
  final String id;
  final bool isIHave;
  final String title;
  final String category;
  final String quantity;
  final String unit;
  final String location;
  final String? imageUrl;
  final String? seller;
  final bool sellerIsVerified;
  final String ownerBusinessId;

  const MatchListing({
    required this.id,
    required this.isIHave,
    required this.title,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.location,
    this.imageUrl,
    this.seller,
    this.sellerIsVerified = false,
    required this.ownerBusinessId,
  });

  String get typeLabel => isIHave ? 'I HAVE' : 'I NEED';
  String get amount => '$quantity $unit'.trim();

  factory MatchListing.fromJson(Map<String, dynamic> json) => MatchListing(
        id: json['id'].toString(),
        isIHave: json['type'] == 'I_HAVE',
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        quantity: json['quantity'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        location: json['location'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        seller: json['seller'] as String?,
        sellerIsVerified: json['sellerIsVerified'] as bool? ?? false,
        ownerBusinessId: json['ownerBusinessId'].toString(),
      );
}

/// A potential I HAVE / I NEED pair found by the AI. The user decides.
class MatchSuggestion {
  final String id;
  final double score;
  final List<String> reasons;
  final List<String> warnings;
  final double? quantityCoverage;
  final double? distanceKm;
  final String myDecision; // PENDING | CONNECTED
  final String otherDecision;
  final MatchListing myListing;
  final MatchListing otherListing;

  const MatchSuggestion({
    required this.id,
    required this.score,
    required this.reasons,
    required this.warnings,
    this.quantityCoverage,
    this.distanceKm,
    required this.myDecision,
    required this.otherDecision,
    required this.myListing,
    required this.otherListing,
  });

  bool get isConnected => myDecision == 'CONNECTED';
  int get scorePercent => (score * 100).round();

  factory MatchSuggestion.fromJson(Map<String, dynamic> json) => MatchSuggestion(
        id: json['id'].toString(),
        score: (json['score'] as num).toDouble(),
        reasons: List<String>.from(json['reasons'] as List? ?? const []),
        warnings: List<String>.from(json['warnings'] as List? ?? const []),
        quantityCoverage: (json['quantityCoverage'] as num?)?.toDouble(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        myDecision: json['myDecision'] as String? ?? 'PENDING',
        otherDecision: json['otherDecision'] as String? ?? 'PENDING',
        myListing: MatchListing.fromJson(json['myListing'] as Map<String, dynamic>),
        otherListing: MatchListing.fromJson(json['otherListing'] as Map<String, dynamic>),
      );
}

/// Latest AI workflow for one of my posts.
class MatchWorkflowStatus {
  final String state;
  final String? outcome;
  final String? reason;
  final int suggestionCount;

  const MatchWorkflowStatus({required this.state, this.outcome, this.reason, this.suggestionCount = 0});

  bool get isRunning => !const {'USER_APPROVAL', 'CONNECTED', 'SAFE_FAILURE'}.contains(state);

  factory MatchWorkflowStatus.fromJson(Map<String, dynamic> json) => MatchWorkflowStatus(
        state: json['state'] as String? ?? 'MATCHING',
        outcome: json['outcome'] as String?,
        reason: json['reason'] as String?,
        suggestionCount: json['suggestionCount'] as int? ?? 0,
      );
}

/// The latest AI check for one of my posts (state is null if never checked).
class MatchActivity {
  final String listingId;
  final String title;
  final bool isIHave;
  final String? state;
  final String? outcome;
  final String? reason;
  final int suggestionCount;

  const MatchActivity({
    required this.listingId,
    required this.title,
    required this.isIHave,
    this.state,
    this.outcome,
    this.reason,
    this.suggestionCount = 0,
  });

  bool get isChecking =>
      state != null && !const {'USER_APPROVAL', 'CONNECTED', 'SAFE_FAILURE'}.contains(state);

  factory MatchActivity.fromJson(Map<String, dynamic> json) => MatchActivity(
        listingId: json['listingId'].toString(),
        title: json['title'] as String? ?? '',
        isIHave: json['type'] == 'I_HAVE',
        state: json['state'] as String?,
        outcome: json['outcome'] as String?,
        reason: json['reason'] as String?,
        suggestionCount: json['suggestionCount'] as int? ?? 0,
      );
}
