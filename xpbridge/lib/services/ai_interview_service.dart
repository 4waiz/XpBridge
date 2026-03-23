import '../models/ai_interview.dart';
import '../models/application.dart';
import '../models/startup_profile.dart';
import '../models/student_profile.dart';

class AiInterviewService {
  static List<String> buildQuestions({
    required Application application,
    StudentProfile? student,
    StartupProfile? startup,
  }) {
    final focusSkills = [
      ...?student?.skills.take(2),
      ...?startup?.requiredSkills.take(2),
    ].toSet().toList();
    final roleTitle = application.roleTitle ?? 'this mission';

    return [
      'Tell us why $roleTitle stands out to you and what you want to learn from it.',
      'Describe a recent project where you used ${focusSkills.isNotEmpty ? focusSkills.first : 'one of your core skills'} in a real way.',
      'How do you communicate progress or blockers when you are working with a founder or mentor?',
      'What would your first week on this mission look like if you joined the team?',
    ];
  }

  static AiInterview createInterview({
    required Application application,
    StudentProfile? student,
    StartupProfile? startup,
  }) {
    return AiInterview(
      id: 'interview_${DateTime.now().millisecondsSinceEpoch}',
      applicationId: application.id,
      missionId: '${application.startupId}::${application.roleTitle ?? 'mission'}',
      studentId: application.studentId,
      startupId: application.startupId,
      questions: buildQuestions(
        application: application,
        student: student,
        startup: startup,
      ),
      status: AiInterviewStatus.pending,
    );
  }

  static AiInterview evaluateInterview(
    AiInterview interview,
    List<AiInterviewResponse> responses,
  ) {
    final answered = responses.where((item) => !item.skipped).toList();
    final combinedText = answered.map((item) => item.responseText).join(' ');
    final wordCount = combinedText
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .length;
    final usesStructure = RegExp(
      r'\b(first|then|because|result|learned|shipped|built)\b',
      caseSensitive: false,
    ).hasMatch(combinedText);
    final mentionsMission = RegExp(
      r'\b(team|mission|founder|product|users|startup|impact)\b',
      caseSensitive: false,
    ).hasMatch(combinedText);

    final communication = (48 + (answered.length * 8) + (usesStructure ? 14 : 0))
        .clamp(0, 100);
    final confidence = (42 + (wordCount ~/ 8) + (answered.length * 5))
        .clamp(0, 100);
    final relevance = (46 + (mentionsMission ? 22 : 4) + (wordCount ~/ 10))
        .clamp(0, 100);
    final average = ((communication + confidence + relevance) / 3).round();

    final recommendation = average >= 80
        ? AiInterviewRecommendation.strongFit
        : average >= 62
        ? AiInterviewRecommendation.possibleFit
        : AiInterviewRecommendation.needsReview;

    final summary = average >= 80
        ? 'Clear communicator with grounded examples and strong mission alignment.'
        : average >= 62
        ? 'Promising signal overall. Communication is solid, with a few areas that would benefit from founder follow-up.'
        : 'Useful baseline signal, but the responses need closer manual review for confidence and role alignment.';

    return interview.copyWith(
      responses: responses,
      completedAt: DateTime.now(),
      communicationScore: communication,
      confidenceScore: confidence,
      relevanceScore: relevance,
      summary: summary,
      recommendation: recommendation,
      status: AiInterviewStatus.completed,
    );
  }

  static String recommendationLabel(AiInterviewRecommendation recommendation) {
    switch (recommendation) {
      case AiInterviewRecommendation.strongFit:
        return 'Strong Fit';
      case AiInterviewRecommendation.possibleFit:
        return 'Possible Fit';
      case AiInterviewRecommendation.needsReview:
        return 'Needs Review';
    }
  }
}
