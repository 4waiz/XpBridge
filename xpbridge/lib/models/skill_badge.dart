enum SkillBadgeType {
  level10Achieved,
  fiveCompletedMissions,
  premiumMentorEndorsement,
  topCollaborationContributor,
}

enum SkillBadgeVerificationStatus { verified, blockchainReady, pending }

class SkillBadge {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final DateTime issuedAt;
  final SkillBadgeType badgeType;
  final String earnedFrom;
  final SkillBadgeVerificationStatus verificationStatus;
  final String tokenIdOrReference;
  final bool isTransferable;

  const SkillBadge({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.issuedAt,
    required this.badgeType,
    required this.earnedFrom,
    required this.verificationStatus,
    required this.tokenIdOrReference,
    this.isTransferable = false,
  });

  SkillBadge copyWith({
    String? id,
    String? studentId,
    String? title,
    String? description,
    DateTime? issuedAt,
    SkillBadgeType? badgeType,
    String? earnedFrom,
    SkillBadgeVerificationStatus? verificationStatus,
    String? tokenIdOrReference,
    bool? isTransferable,
  }) {
    return SkillBadge(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      issuedAt: issuedAt ?? this.issuedAt,
      badgeType: badgeType ?? this.badgeType,
      earnedFrom: earnedFrom ?? this.earnedFrom,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      tokenIdOrReference: tokenIdOrReference ?? this.tokenIdOrReference,
      isTransferable: isTransferable ?? this.isTransferable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'title': title,
      'description': description,
      'issuedAt': issuedAt.toIso8601String(),
      'badgeType': badgeType.name,
      'earnedFrom': earnedFrom,
      'verificationStatus': verificationStatus.name,
      'tokenIdOrReference': tokenIdOrReference,
      'isTransferable': isTransferable,
    };
  }

  factory SkillBadge.fromMap(Map<String, dynamic> map) {
    SkillBadgeType parseType(dynamic value) {
      if (value is String) {
        switch (value) {
          case 'fiveCompletedMissions':
            return SkillBadgeType.fiveCompletedMissions;
          case 'premiumMentorEndorsement':
            return SkillBadgeType.premiumMentorEndorsement;
          case 'topCollaborationContributor':
            return SkillBadgeType.topCollaborationContributor;
          case 'level10Achieved':
          default:
            return SkillBadgeType.level10Achieved;
        }
      }
      return SkillBadgeType.level10Achieved;
    }

    SkillBadgeVerificationStatus parseVerification(dynamic value) {
      if (value is String) {
        switch (value) {
          case 'verified':
            return SkillBadgeVerificationStatus.verified;
          case 'pending':
            return SkillBadgeVerificationStatus.pending;
          case 'blockchainReady':
          default:
            return SkillBadgeVerificationStatus.blockchainReady;
        }
      }
      return SkillBadgeVerificationStatus.blockchainReady;
    }

    return SkillBadge(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      issuedAt:
          DateTime.tryParse(map['issuedAt'] as String? ?? '') ?? DateTime.now(),
      badgeType: parseType(map['badgeType']),
      earnedFrom: map['earnedFrom'] as String? ?? '',
      verificationStatus: parseVerification(map['verificationStatus']),
      tokenIdOrReference: map['tokenIdOrReference'] as String? ?? '',
      isTransferable: map['isTransferable'] as bool? ?? false,
    );
  }
}
