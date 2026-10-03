class BusinessProfile {
  final String id;
  final String businessName;
  final String businessType;
  final String registrationNumber;
  final String? bio;
  final String? description;
  final String email;
  final String phone;
  final String address;
  final String? websiteUrl;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final bool isVerified;
  final String status;
  /// Admin's reason when [status] is 'Rejected'.
  final String? verificationNote;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessProfile({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.registrationNumber,
    this.bio,
    this.description,
    required this.email,
    required this.phone,
    required this.address,
    this.websiteUrl,
    this.logoUrl,
    this.coverPhotoUrl,
    this.isVerified = false,
    this.status = 'Unverified',
    this.verificationNote,
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
      bio: json['bio'] as String?,
      description: json['description'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      status: json['status'] as String? ?? 'Unverified',
      verificationNote: json['verificationNote'] as String?,
      userId: json['userId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  bool get isRejected => status == 'Rejected';

  /// Human-readable verification state; 'Unverified' means awaiting review.
  String get statusLabel => isVerified
      ? 'Verified'
      : isRejected
          ? 'Rejected'
          : 'Pending verification';

  /// Every field, in the API's shape; used to persist the active profile.
  Map<String, dynamic> toStorageJson() {
    return {
      ...toJson(),
      'id': id,
      'isVerified': isVerified,
      'status': status,
      if (verificationNote != null) 'verificationNote': verificationNote,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'businessType': businessType,
      'registrationNumber': registrationNumber,
      if (bio != null) 'bio': bio,
      if (description != null) 'description': description,
      'email': email,
      'phone': phone,
      'address': address,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
      if (userId != null) 'userId': userId,
    };
  }

  BusinessProfile copyWith({
    String? id,
    String? businessName,
    String? businessType,
    String? registrationNumber,
    String? bio,
    String? description,
    String? email,
    String? phone,
    String? address,
    String? websiteUrl,
    String? logoUrl,
    String? coverPhotoUrl,
    bool? isVerified,
    String? status,
    String? verificationNote,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      bio: bio ?? this.bio,
      description: description ?? this.description,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      verificationNote: verificationNote ?? this.verificationNote,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
