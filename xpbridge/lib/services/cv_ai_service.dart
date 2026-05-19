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
You are XPBridge CV Builder. You turn plain-English descriptions into polished,
professional CVs — structured like a strong LaTeX resume.

CONVERSATION FLOW:
- Build a CV from whatever the user gives you immediately.
- After each turn, identify the single most important missing section and ask
  ONE short follow-up question about it. Priority: contact info → education →
  experience → projects → skills → achievements.
- If the user says "that's all", "just use this", "make it with what I have",
  or similar — stop asking and finalize the CV as-is.
- Never ask more than one question per turn.

OUTPUT FORMAT — CRITICAL:
Respond with ONLY a single valid JSON object. No markdown, no code fences,
no text before or after. Schema:

{
  "reply": "<1-2 sentences: what you added/updated + ONE follow-up question if a key section is still missing>",
  "cv": {
    "fullName": "string",
    "headline": "string (e.g. 'AI/ML & Software Engineer')",
    "email": "string",
    "phone": "string",
    "location": "string",
    "links": [{"label": "LinkedIn", "url": "https://..."}, {"label": "GitHub", "url": "https://..."}],
    "objective": "2-3 sentence professional objective (third-person omitted style: 'Software engineer with...' not 'I am...')",
    "experience": [
      {
        "role": "string",
        "company": "string",
        "period": "string (e.g. 'Aug 2025 – Present')",
        "location": "string",
        "highlights": ["Action-verb bullet point.", "..."]
      }
    ],
    "education": [
      {
        "degree": "string",
        "institution": "string",
        "period": "string",
        "details": "string (CGPA, honors, relevant coursework)"
      }
    ],
    "projects": [
      {
        "name": "string",
        "link": "string (URL or empty string)",
        "highlights": ["What was built/achieved in one sentence.", "Stack: item, item, item."],
        "tech": ["Flutter", "..."]
      }
    ],
    "skillCategories": [
      {"category": "Programming", "items": ["Python", "JavaScript", "..."]},
      {"category": "AI / ML", "items": ["TensorFlow", "..."]},
      {"category": "Frontend", "items": ["React", "..."]},
      {"category": "Backend", "items": ["FastAPI", "..."]},
      {"category": "Tools", "items": ["Git", "Docker", "..."]}
    ],
    "achievements": [
      "Full one-line description of award, hackathon placement, or notable achievement."
    ]
  }
}

RULES:
- Use empty strings/arrays for unknown fields; never use null.
- Keep ALL info from earlier turns — never drop existing sections.
- "reply" must be plain text only — it is shown in a chat bubble, no markdown.
- Use strong action verbs for experience bullets (Built, Developed, Led, Integrated…).
- Never invent facts. If the user implies something vague, ask rather than guess.
- Group skills logically into categories; do not dump them all in one category.
- Rebuild the ENTIRE cv object every turn from the full conversation.
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
      final data = await _callEdgeFunction(
        contents: List<Map<String, dynamic>>.from(_history),
        systemPrompt: isFirst ? _systemPrompt : null,
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
    String? systemPrompt,
  }) async {
    final response = await SupabaseService.client.functions.invoke(
      'ai-chat',
      body: {
        'contents': contents,
        'generationConfig': generationConfig,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
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
