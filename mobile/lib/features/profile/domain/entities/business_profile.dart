class BusinessProfile {
  final String id;
  final String businessName;
  final String? email;
  final String? logoUrl;
  final String? phoneNumber;
  final String? address;
  final String? industryType;
  final String? description;
  final DateTime createdAt;
  final bool isVerified;

  BusinessProfile({
    required this.id,
    required this.businessName,
    this.email,
    this.logoUrl,
    this.phoneNumber,
    this.address,
    this.industryType,
    this.description,
    required this.createdAt,
    required this.isVerified,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      email: json['email'] as String?,
      logoUrl: json['logoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      industryType: json['industryType'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isVerified: json['isVerified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'address': address,
      'industryType': industryType,
      'description': description,
    };
  }
}
