enum ApplicationStatus {
  pending,
  accepted,
  rejected,
  interviewing,
  hired,
  completed,
}

class Application {
  final String id;
  final String studentId;
  final String startupId;
  final String studentName;
  final String startupName;
  final String? roleTitle;
  final ApplicationStatus status;
  final String? message;
  final DateTime appliedAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? reflectionDid;
  final String? reflectionLearned;
  final List<String> skillsPracticed;
  final int? hoursSpent;
  final String? deliverableUrl;
  final String? deliverableType;
  final int? mentorRating;
  final String? mentorFeedbackText;
  final List<String> strengths;
  final List<String> growthAreas;
  final List<String> endorsedSkills;
  final DateTime? feedbackAt;

  const Application({
    required this.id,
    required this.studentId,
    required this.startupId,
    required this.studentName,
    required this.startupName,
    this.roleTitle,
    required this.status,
    this.message,
    required this.appliedAt,
    this.updatedAt,
    this.completedAt,
    this.reflectionDid,
    this.reflectionLearned,
    this.skillsPracticed = const [],
    this.hoursSpent,
    this.deliverableUrl,
    this.deliverableType,
    this.mentorRating,
    this.mentorFeedbackText,
    this.strengths = const [],
    this.growthAreas = const [],
    this.endorsedSkills = const [],
    this.feedbackAt,
  });

  Application copyWith({
    String? id,
    String? studentId,
    String? startupId,
    String? studentName,
    String? startupName,
    String? roleTitle,
    ApplicationStatus? status,
    String? message,
    DateTime? appliedAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? reflectionDid,
    String? reflectionLearned,
    List<String>? skillsPracticed,
    int? hoursSpent,
    String? deliverableUrl,
    String? deliverableType,
    int? mentorRating,
    String? mentorFeedbackText,
    List<String>? strengths,
    List<String>? growthAreas,
    List<String>? endorsedSkills,
    DateTime? feedbackAt,
  }) {
    return Application(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      startupId: startupId ?? this.startupId,
      studentName: studentName ?? this.studentName,
      startupName: startupName ?? this.startupName,
      roleTitle: roleTitle ?? this.roleTitle,
      status: status ?? this.status,
      message: message ?? this.message,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      reflectionDid: reflectionDid ?? this.reflectionDid,
      reflectionLearned: reflectionLearned ?? this.reflectionLearned,
      skillsPracticed: skillsPracticed ?? this.skillsPracticed,
      hoursSpent: hoursSpent ?? this.hoursSpent,
      deliverableUrl: deliverableUrl ?? this.deliverableUrl,
      deliverableType: deliverableType ?? this.deliverableType,
      mentorRating: mentorRating ?? this.mentorRating,
      mentorFeedbackText: mentorFeedbackText ?? this.mentorFeedbackText,
      strengths: strengths ?? this.strengths,
      growthAreas: growthAreas ?? this.growthAreas,
      endorsedSkills: endorsedSkills ?? this.endorsedSkills,
      feedbackAt: feedbackAt ?? this.feedbackAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'startupId': startupId,
      'studentName': studentName,
      'startupName': startupName,
      'roleTitle': roleTitle,
      'status': status.name,
      'message': message,
      'appliedAt': appliedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'reflectionDid': reflectionDid,
      'reflectionLearned': reflectionLearned,
      'skillsPracticed': skillsPracticed,
      'hoursSpent': hoursSpent,
      'deliverableUrl': deliverableUrl,
      'deliverableType': deliverableType,
      'mentorRating': mentorRating,
      'mentorFeedbackText': mentorFeedbackText,
      'strengths': strengths,
      'growthAreas': growthAreas,
      'endorsedSkills': endorsedSkills,
      'feedbackAt': feedbackAt?.toIso8601String(),
    };
  }

  factory Application.fromMap(Map<String, dynamic> map) {
    ApplicationStatus parseStatus(dynamic value) {
      if (value is String) {
        switch (value) {
          case 'pending':
            return ApplicationStatus.pending;
          case 'accepted':
            return ApplicationStatus.accepted;
          case 'rejected':
            return ApplicationStatus.rejected;
          case 'interviewing':
            return ApplicationStatus.interviewing;
          case 'hired':
          case 'inProgress':
            return ApplicationStatus.hired;
          case 'completed':
            return ApplicationStatus.completed;
        }
      }
      if (value is int &&
          value >= 0 &&
          value < ApplicationStatus.values.length) {
        return ApplicationStatus.values[value];
      }
      return ApplicationStatus.pending;
    }

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Application(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      startupId: map['startupId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      startupName: map['startupName'] as String? ?? '',
      roleTitle: map['roleTitle'] as String?,
      status: parseStatus(map['status']),
      message: map['message'] as String?,
      appliedAt: parseDate(map['appliedAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']),
      completedAt: parseDate(map['completedAt']),
      reflectionDid: map['reflectionDid'] as String?,
      reflectionLearned: map['reflectionLearned'] as String?,
      skillsPracticed: stringList(map['skillsPracticed']),
      hoursSpent: map['hoursSpent'] as int?,
      deliverableUrl: map['deliverableUrl'] as String?,
      deliverableType: map['deliverableType'] as String?,
      mentorRating: map['mentorRating'] as int?,
      mentorFeedbackText: map['mentorFeedbackText'] as String?,
      strengths: stringList(map['strengths']),
      growthAreas: stringList(map['growthAreas']),
      endorsedSkills: stringList(map['endorsedSkills']),
      feedbackAt: parseDate(map['feedbackAt']),
    );
  }
}
