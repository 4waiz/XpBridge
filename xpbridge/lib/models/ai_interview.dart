enum AiInterviewStatus { pending, inProgress, completed }

enum AiInterviewRecommendation { strongFit, possibleFit, needsReview }

class AiInterviewResponse {
  final String question;
  final String responseText;
  final bool usedTextFallback;
  final bool skipped;

  const AiInterviewResponse({
    required this.question,
    required this.responseText,
    required this.usedTextFallback,
    required this.skipped,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'responseText': responseText,
      'usedTextFallback': usedTextFallback,
      'skipped': skipped,
    };
  }

  factory AiInterviewResponse.fromMap(Map<String, dynamic> map) {
    return AiInterviewResponse(
      question: map['question'] as String? ?? '',
      responseText: map['responseText'] as String? ?? '',
      usedTextFallback: map['usedTextFallback'] as bool? ?? true,
      skipped: map['skipped'] as bool? ?? false,
    );
  }
}

class AiInterview {
  final String id;
  final String applicationId;
  final String missionId;
  final String studentId;
  final String startupId;
  final List<String> questions;
  final List<AiInterviewResponse> responses;
  final DateTime? completedAt;
  final int? communicationScore;
  final int? confidenceScore;
  final int? relevanceScore;
  final String? summary;
  final AiInterviewRecommendation? recommendation;
  final AiInterviewStatus status;

  const AiInterview({
    required this.id,
    required this.applicationId,
    required this.missionId,
    required this.studentId,
    required this.startupId,
    required this.questions,
    this.responses = const [],
    this.completedAt,
    this.communicationScore,
    this.confidenceScore,
    this.relevanceScore,
    this.summary,
    this.recommendation,
    this.status = AiInterviewStatus.pending,
  });

  AiInterview copyWith({
    String? id,
    String? applicationId,
    String? missionId,
    String? studentId,
    String? startupId,
    List<String>? questions,
    List<AiInterviewResponse>? responses,
    DateTime? completedAt,
    int? communicationScore,
    int? confidenceScore,
    int? relevanceScore,
    String? summary,
    AiInterviewRecommendation? recommendation,
    AiInterviewStatus? status,
  }) {
    return AiInterview(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      missionId: missionId ?? this.missionId,
      studentId: studentId ?? this.studentId,
      startupId: startupId ?? this.startupId,
      questions: questions ?? this.questions,
      responses: responses ?? this.responses,
      completedAt: completedAt ?? this.completedAt,
      communicationScore: communicationScore ?? this.communicationScore,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      summary: summary ?? this.summary,
      recommendation: recommendation ?? this.recommendation,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'applicationId': applicationId,
      'missionId': missionId,
      'studentId': studentId,
      'startupId': startupId,
      'questions': questions,
      'responses': responses.map((item) => item.toMap()).toList(),
      'completedAt': completedAt?.toIso8601String(),
      'communicationScore': communicationScore,
      'confidenceScore': confidenceScore,
      'relevanceScore': relevanceScore,
      'summary': summary,
      'recommendation': recommendation?.name,
      'status': status.name,
    };
  }

  factory AiInterview.fromMap(Map<String, dynamic> map) {
    AiInterviewStatus parseStatus(dynamic value) {
      if (value is String) {
        switch (value) {
          case 'pending':
            return AiInterviewStatus.pending;
          case 'inProgress':
            return AiInterviewStatus.inProgress;
          case 'completed':
            return AiInterviewStatus.completed;
        }
      }
      return AiInterviewStatus.pending;
    }

    AiInterviewRecommendation? parseRecommendation(dynamic value) {
      if (value is String) {
        switch (value) {
          case 'strongFit':
            return AiInterviewRecommendation.strongFit;
          case 'possibleFit':
            return AiInterviewRecommendation.possibleFit;
          case 'needsReview':
            return AiInterviewRecommendation.needsReview;
        }
      }
      return null;
    }

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    List<AiInterviewResponse> responseList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map(
              (item) => AiInterviewResponse.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      return [];
    }

    return AiInterview(
      id: map['id'] as String? ?? '',
      applicationId:
          (map['applicationId'] ?? map['application_id']) as String? ?? '',
      missionId: (map['missionId'] ?? map['mission_id']) as String? ?? '',
      studentId: (map['studentId'] ?? map['student_id']) as String? ?? '',
      startupId: (map['startupId'] ?? map['startup_id']) as String? ?? '',
      questions: stringList(map['questions']),
      responses: responseList(map['responses']),
      completedAt: DateTime.tryParse(
        (map['completedAt'] ?? map['completed_at']) as String? ?? '',
      ),
      communicationScore:
          ((map['communicationScore'] ?? map['communication_score']) as num?)
              ?.toInt(),
      confidenceScore:
          ((map['confidenceScore'] ?? map['confidence_score']) as num?)?.toInt(),
      relevanceScore:
          ((map['relevanceScore'] ?? map['relevance_score']) as num?)?.toInt(),
      summary: map['summary'] as String?,
      recommendation: parseRecommendation(map['recommendation']),
      status: parseStatus(map['status']),
    );
  }
}
