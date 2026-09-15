class BusinessProfile {
  final String id;
  final String businessName;
  final String businessType;
  final String registrationNumber;
  final String? description;
  final String email;
  final String phone;
  final String address;
  final String? websiteUrl;
  final String? logoUrl;
  final bool isVerified;
  final String status;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessProfile({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.registrationNumber,
    this.description,
    required this.email,
    required this.phone,
    required this.address,
    this.websiteUrl,
    this.logoUrl,
    this.isVerified = false,
    this.status = 'Unverified',
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: json['id']?.toString() ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      description: json['description'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      status: json['status'] as String? ?? 'Unverified',
      userId: json['userId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'businessType': businessType,
      'registrationNumber': registrationNumber,
      'description': description,
      'email': email,
      'phone': phone,
      'address': address,
      'websiteUrl': websiteUrl,
      'logoUrl': logoUrl,
      if (userId != null) 'userId': userId,
    };
  }
}
