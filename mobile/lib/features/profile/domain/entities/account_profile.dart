/// Personal details of the signed-in account. Business details (industry,
/// registration, description...) live in Business Hub profiles instead.
class AccountProfile {
  final String id;
  // The backend stores the account's display name in `businessName`.
  final String businessName;
  final String? email;
  final String? logoUrl;
  final String? phoneNumber;
  final String? address;
  final DateTime createdAt;
  final bool isVerified;

  AccountProfile({
    required this.id,
    required this.businessName,
    this.email,
    this.logoUrl,
    this.phoneNumber,
    this.address,
    required this.createdAt,
    required this.isVerified,
  });

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      email: json['email'] as String?,
      logoUrl: json['logoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isVerified: json['isVerified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}
