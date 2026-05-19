import 'dart:convert';

import '../models/cv_data.dart';
import '../models/student_profile.dart';
import 'supabase_service.dart';

/// One AI turn for the CV builder: a short chat reply plus the full,
/// regenerated CV the user can preview/export.
class CvAiTurn {
  const CvAiTurn({required this.reply, required this.cv});

  final String reply;
  final CvData cv;
}

/// Dedicated AI pipeline for the CV Builder.
///
/// This is deliberately separate from [AiService]: it keeps its own
/// conversation history, system prompt, and generation config so the CV
/// pipeline can evolve independently of the career-advisor chat. It still
/// talks to the same `ai-chat` Supabase Edge Function (the Groq key lives
/// server-side), but instructs the model to always answer with strict JSON
/// containing both a chat `reply` and the complete `cv` object.
class CvAiService {
  CvAiService._();

  static final List<Map<String, dynamic>> _history = [];

  /// Last CV the model produced — kept so a turn that doesn't change the CV
  /// (e.g. the user just asks a question) still returns the latest version.
  static CvData _lastCv = CvData.empty;

  static const String _systemPrompt = '''
You are XPBridge CV Builder, an assistant that turns plain-English descriptions
into a polished, professional CV.

How you work:
- The user describes their background, experience, education, skills, and goals
  in everyday language across multiple messages.
- After EVERY user message you rebuild the ENTIRE CV from the full conversation
  so far (do not just append — always return the complete, current CV).
- Infer reasonable, professional phrasing. Turn vague notes into strong,
  concise resume bullet points starting with action verbs. Never invent facts
  (no fake employers, dates, or metrics the user didn't imply).
- Ask at most ONE short follow-up question when a critical section is missing.

OUTPUT FORMAT — CRITICAL:
Respond with ONLY a single valid JSON object, no markdown, no code fences, no
text before or after. Schema:

{
  "reply": "<one or two short sentences to the user: what you added/changed and, if needed, one follow-up question>",
  "cv": {
    "fullName": "string",
    "headline": "string (e.g. 'Computer Science Student & Flutter Developer')",
    "email": "string",
    "phone": "string",
    "location": "string",
    "links": [{"label": "GitHub", "url": "https://..."}],
    "summary": "2-3 sentence professional summary",
    "experience": [
      {"role": "string", "company": "string", "period": "string", "location": "string",
       "highlights": ["action-verb bullet", "..."]}
    ],
    "education": [
      {"degree": "string", "institution": "string", "period": "string", "details": "string"}
    ],
    "projects": [
      {"name": "string", "description": "string", "tech": ["Flutter", "..."]}
    ],
    "skills": ["string", "..."],
    "certifications": ["string", "..."]
  }
}

Rules:
- Use empty strings/arrays for unknown fields; never use null.
- Keep all known information from earlier in the conversation.
- "reply" must be plain text only (it is shown in a chat bubble).
''';

  static void reset() {
    _history.clear();
    _lastCv = CvData.empty;
  }

  static CvData get currentCv => _lastCv;

  /// Sends [message] to the model and returns the chat reply plus the freshly
  /// rebuilt CV. On the first turn we prepend the student's profile (if any)
  /// so the CV starts from real data instead of a blank slate.
  static Future<CvAiTurn> send(
    String message,
    StudentProfile? profile,
  ) async {
    final isFirst = _history.isEmpty;
    final userText = isFirst ? _withProfileContext(profile, message) : message;

    _history.add(_msg('user', userText));

    try {
      final contents = isFirst
          ? [_msg('user', '$_systemPrompt\n\n$userText')]
          : List<Map<String, dynamic>>.from(_history);

      final data = await _callEdgeFunction(
        contents: contents,
        generationConfig: {
          'temperature': 0.35,
          'maxOutputTokens': 2600,
          'thinkingConfig': {'thinkingBudget': 0},
        },
      );

      final raw = data['candidates']?[0]?['content']?['parts']?[0]?['text']
              ?.toString() ??
          '';
      final parsed = _parse(raw);
      _history.add(_msg('model', raw));
      _lastCv = parsed.cv;
      return parsed;
    } catch (e) {
      _history.removeLast();
      rethrow;
    }
  }

  static Map<String, dynamic> _msg(String role, String text) => {
        'role': role,
        'parts': [
          {'text': text},
        ],
      };

  static String _withProfileContext(StudentProfile? p, String message) {
    if (p == null) return message;
    return '''
[Existing profile — use as a starting point, the user will refine it]
Name: ${p.name}
Education: ${p.education ?? 'Not specified'}
Skills: ${p.skills.join(', ')}
Bio: ${p.bio ?? 'Not specified'}
Portfolio: ${p.portfolioUrl ?? 'Not specified'}
GitHub: ${p.githubUrl ?? 'Not specified'}

User message: $message''';
  }

  /// Extracts the JSON object from the model output, tolerating stray prose or
  /// ```json fences. Falls back to treating the whole text as a chat reply.
  static CvAiTurn _parse(String raw) {
    final text = raw.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      final candidate = text.substring(start, end + 1);
      try {
        final json = jsonDecode(candidate) as Map<String, dynamic>;
        final reply = (json['reply'] ?? '').toString().trim();
        final cvJson = json['cv'];
        final cv = cvJson is Map<String, dynamic>
            ? CvData.fromJson(cvJson)
            : (cvJson is Map
                ? CvData.fromJson(cvJson.cast<String, dynamic>())
                : _lastCv);
        return CvAiTurn(
          reply: reply.isEmpty ? 'Updated your CV — check the preview.' : reply,
          cv: cv.isEmpty ? _lastCv : cv,
        );
      } catch (_) {
        // fall through to plain-text handling
      }
    }
    return CvAiTurn(
      reply: text.isEmpty
          ? 'Sorry, I could not generate a response. Please try again.'
          : text,
      cv: _lastCv,
    );
  }

  static Future<Map<String, dynamic>> _callEdgeFunction({
    required List<Map<String, dynamic>> contents,
    required Map<String, dynamic> generationConfig,
  }) async {
    final response = await SupabaseService.client.functions.invoke(
      'ai-chat',
      body: {
        'contents': contents,
        'generationConfig': generationConfig,
      },
    );

    if (response.status != 200) {
      final errorData = response.data;
      final errorMessage = errorData is Map<String, dynamic>
          ? errorData['error'] as String?
          : null;
      throw XpServiceException(
        errorMessage ?? 'CV AI service error (${response.status}).',
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    throw const XpServiceException('Unexpected AI response format.');
  }
}
