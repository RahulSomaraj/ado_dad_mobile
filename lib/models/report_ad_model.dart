class ReportAdModel {
  // Request fields (for creating a report)
  final String reportedUser;
  final String reason;
  final String description;
  final List<String>? evidenceUrls;
  final String relatedAd;

  // Response fields (from API after creation)
  final String? id;
  final ReportedUserDetails? reportedUserDetails;
  final String? reportedBy;
  final ReportedByDetails? reportedByDetails;
  final String? status;
  final String? reviewedBy;
  final String? adminNotes;
  final String? reviewedAt;
  final int? reportCount;
  final String? createdAt;
  final String? updatedAt;

  const ReportAdModel({
    required this.reportedUser,
    required this.reason,
    required this.description,
    this.evidenceUrls,
    required this.relatedAd,
    this.id,
    this.reportedUserDetails,
    this.reportedBy,
    this.reportedByDetails,
    this.status,
    this.reviewedBy,
    this.adminNotes,
    this.reviewedAt,
    this.reportCount,
    this.createdAt,
    this.updatedAt,
  });

  // For creating a report (request payload)
  Map<String, dynamic> toJson() {
    return {
      'reportedUser': reportedUser,
      'reason': reason,
      'description': description,
      'evidenceUrls': evidenceUrls ?? [],
      'relatedAd': relatedAd,
    };
  }

  // For parsing API response
  factory ReportAdModel.fromJson(Map<String, dynamic> json) {
    return ReportAdModel(
      id: json['id'] as String?,
      reportedUser: json['reportedUser'] as String,
      reportedUserDetails: json['reportedUserDetails'] != null
          ? ReportedUserDetails.fromJson(
              json['reportedUserDetails'] as Map<String, dynamic>)
          : null,
      reportedBy: json['reportedBy'] as String?,
      reportedByDetails: json['reportedByDetails'] != null
          ? ReportedByDetails.fromJson(
              json['reportedByDetails'] as Map<String, dynamic>)
          : null,
      reason: json['reason'] as String,
      description: json['description'] as String,
      status: json['status'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      adminNotes: json['adminNotes'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      evidenceUrls: json['evidenceUrls'] != null
          ? List<String>.from(json['evidenceUrls'])
          : null,
      relatedAd: json['relatedAd'] as String,
      reportCount: json['reportCount'] as int?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  ReportAdModel copyWith({
    String? reportedUser,
    String? reason,
    String? description,
    List<String>? evidenceUrls,
    String? relatedAd,
    String? id,
    ReportedUserDetails? reportedUserDetails,
    String? reportedBy,
    ReportedByDetails? reportedByDetails,
    String? status,
    String? reviewedBy,
    String? adminNotes,
    String? reviewedAt,
    int? reportCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return ReportAdModel(
      reportedUser: reportedUser ?? this.reportedUser,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      relatedAd: relatedAd ?? this.relatedAd,
      id: id ?? this.id,
      reportedUserDetails: reportedUserDetails ?? this.reportedUserDetails,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByDetails: reportedByDetails ?? this.reportedByDetails,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reportCount: reportCount ?? this.reportCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReportAdModel(id: $id, reportedUser: $reportedUser, reason: $reason, description: $description, evidenceUrls: $evidenceUrls, relatedAd: $relatedAd, status: $status, reportCount: $reportCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportAdModel &&
        other.id == id &&
        other.reportedUser == reportedUser &&
        other.reason == reason &&
        other.description == description &&
        other.evidenceUrls == evidenceUrls &&
        other.relatedAd == relatedAd &&
        other.status == status &&
        other.reportCount == reportCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        reportedUser.hashCode ^
        reason.hashCode ^
        description.hashCode ^
        evidenceUrls.hashCode ^
        relatedAd.hashCode ^
        status.hashCode ^
        reportCount.hashCode;
  }
}

class ReportedUserDetails {
  final String id;
  final String name;
  final String email;
  final String? phone;

  const ReportedUserDetails({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory ReportedUserDetails.fromJson(Map<String, dynamic> json) {
    return ReportedUserDetails(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
    };
  }
}

class ReportedByDetails {
  final String id;
  final String name;
  final String email;

  const ReportedByDetails({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ReportedByDetails.fromJson(Map<String, dynamic> json) {
    return ReportedByDetails(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
