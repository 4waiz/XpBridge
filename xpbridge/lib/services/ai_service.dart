import 'dart:convert';

import '../data/dummy_data.dart';
import '../models/student_profile.dart';
import '../models/startup_profile.dart';
import 'supabase_service.dart';

class AiService {
  // State
  static final List<Map<String, dynamic>> _chatHistory = [];
  static final List<Map<String, dynamic>> _startupChatHistory = [];
  static List<StudentProfile> lastMatchedStudents = [];

  // System prompts
  static const String _studentSystemPrompt = '''
You are a friendly and helpful career advisor for students on XpBridge, a platform that connects students with startup internship opportunities.

Your role is to:
1. Have a natural conversation to understand the student's background
2. Learn about their education, skills, interests, and career goals
3. When you have enough information, recommend suitable job roles

Guidelines:
- Be conversational, direct, and brief
- Keep most replies to 2-4 short sentences
- Ask only 1 follow-up question at a time
- Do not give long intros, long summaries, or motivational filler
- Do not praise the user repeatedly
- End naturally with a complete sentence
- If a longer answer is needed, give a short version first and offer to expand
- Consider their skills, education level, and interests
- Suggest at most 3 specific job roles when you have enough information
- Keep each role explanation to one short line

When you're ready to give recommendations, format them clearly like:
"Based on our conversation, here are roles that would suit you:

1. **[Role Title]** - [Brief explanation of why this fits]
2. **[Role Title]** - [Brief explanation of why this fits]
..."

Also extract and remember:
- Skills mentioned (technical and soft skills)
- Education level and field
- Interests and preferred industries
- Hours available per week

If the user is vague, ask a short clarifying question instead of writing a long answer.
Keep responses concise and not overly formal.
''';

  static const String _startupSystemPrompt = '''
You are a friendly AI talent finder assistant for XpBridge, helping startups find student interns.

Your personality:
- Warm, conversational, and helpful
- Ask clarifying questions to understand their needs better
- Be enthusiastic about helping them find the right talent

CRITICAL RULES:
1. ONLY call search_students when the user mentions SPECIFIC technologies or skills (Flutter, React, Python, Figma, etc.)
2. Do NOT call search_students for vague terms like "database", "backend", "frontend", "developer", "designer" - instead ASK which specific technology they need
3. When you call search_students, do NOT ask follow-up questions in the same response - just present the results
4. Keep responses short (2-3 sentences max)

Examples:
User: "hi" -> "Hey there! What kind of talent are you looking for?"
User: "need database skills" -> "Which database? SQL (PostgreSQL, MySQL) or NoSQL (MongoDB, Redis)?" (DO NOT search)
User: "need backend help" -> "What backend stack? Python, Node.js, Java, Go?" (DO NOT search)
User: "looking for React developers" -> Call search_students with ["React"] (SPECIFIC - search!)
User: "need someone who knows PostgreSQL" -> Call search_students with ["PostgreSQL"] (SPECIFIC - search!)
User: "Flutter and Firebase" -> Call search_students with ["Flutter", "Firebase"] (SPECIFIC - search!)
''';

  static final List<Map<String, dynamic>> _searchStudentsTool = [
    {
      'function_declarations': [
        {
          'name': 'search_students',
          'description':
              'Search for students based on their skills. Call this function whenever the user mentions any skills, technologies, or job roles they are looking for.',
          'parameters': {
            'type': 'object',
            'properties': {
              'skills': {
                'type': 'array',
                'items': {'type': 'string'},
                'description':
                    'List of skills to search for (e.g., ["Flutter", "React", "Python", "UI/UX"])',
              },
            },
            'required': ['skills'],
          },
        },
      ],
    },
  ];

  // Helper methods
  static Map<String, dynamic> _createMessage(String role, String text) => {
    'role': role,
    'parts': [
      {'text': text},
    ],
  };

  static Map<String, dynamic> _createGenerationConfig(
    int maxTokens, {
    double temperature = 0.7,
  }) => {'temperature': temperature, 'maxOutputTokens': maxTokens};

  static String? _extractTextFromResponse(Map<String, dynamic> data) =>
      data['candidates']?[0]?['content']?['parts']?[0]?['text'];

  /// Calls the ai-chat Edge Function which proxies to Gemini server-side.
  static Future<Map<String, dynamic>> _callEdgeFunction({
    required List<Map<String, dynamic>> contents,
    required Map<String, dynamic> generationConfig,
    List<Map<String, dynamic>>? tools,
  }) async {
    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': generationConfig,
    };
    if (tools != null) {
      body['tools'] = tools;
    }

    final response = await SupabaseService.client.functions.invoke(
      'ai-chat',
      body: body,
    );

    if (response.status != 200) {
      final errorData = response.data;
      final errorMessage = errorData is Map<String, dynamic>
          ? errorData['error'] as String?
          : null;
      throw XpServiceException(
        errorMessage ?? 'AI service error (${response.status}).',
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    // response.data may already be decoded or may be a string
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    throw const XpServiceException('Unexpected AI response format.');
  }

  // Reset methods
  static void resetChat() => _chatHistory.clear();

  static void resetStartupChat() {
    _startupChatHistory.clear();
    lastMatchedStudents = [];
  }

  // Student chat methods
  static Future<String> sendMessageWithContext(
    String message,
    StudentProfile? profile,
  ) async {
    final fullMessage = (_chatHistory.isEmpty && profile != null)
        ? _buildStudentContext(profile, message)
        : message;

    _chatHistory.add(_createMessage('user', fullMessage));

    try {
      return await _callGeminiApi();
    } catch (e) {
      _chatHistory.removeLast();
      rethrow;
    }
  }

  static String _buildStudentContext(StudentProfile profile, String message) =>
      '''
[Student Profile Context - Use this to personalize your advice]
Name: ${profile.name}
Education: ${profile.education ?? 'Not specified'}
Current Skills: ${profile.skills.join(', ')}
Bio: ${profile.bio ?? 'Not specified'}
Available Hours: ${profile.availabilityHours} hrs/week

Now respond to their message: $message
''';

  static Future<String> _callGeminiApi() async {
    final contents = _chatHistory.length == 1
        ? [
            _createMessage(
              'user',
              '$_studentSystemPrompt\n\n${_chatHistory.first['parts'][0]['text']}',
            ),
          ]
        : List<Map<String, dynamic>>.from(_chatHistory);

    final data = await _callEdgeFunction(
      contents: contents,
      generationConfig: _createGenerationConfig(360, temperature: 0.5),
    );

    final text =
        _extractTextFromResponse(data) ??
        'Sorry, I could not generate a response.';
    _chatHistory.add(_createMessage('model', text));
    return text;
  }

  // Startup chat methods
  static Future<String> sendMessageForStartup(
    String message,
    StartupProfile? profile,
  ) async {
    final fullMessage = (_startupChatHistory.isEmpty && profile != null)
        ? _buildStartupContext(profile, message)
        : message;

    _startupChatHistory.add(_createMessage('user', fullMessage));

    try {
      return await _callGeminiApiForStartup();
    } catch (e) {
      _startupChatHistory.removeLast();
      rethrow;
    }
  }

  static String _buildStartupContext(StartupProfile profile, String message) =>
      '''
[Startup Profile Context]
Company: ${profile.companyName}
Industry: ${profile.industry}
Required Skills: ${profile.requiredSkills.join(', ')}
Description: ${profile.description}

Help this startup find suitable student talent. Respond to: $message
''';

  static Future<String> _callGeminiApiForStartup() async {
    final contents = _startupChatHistory.length == 1
        ? [
            _createMessage(
              'user',
              '$_startupSystemPrompt\n\n${_startupChatHistory.first['parts'][0]['text']}',
            ),
          ]
        : List<Map<String, dynamic>>.from(_startupChatHistory);

    final data = await _callEdgeFunction(
      contents: contents,
      generationConfig: _createGenerationConfig(320, temperature: 0.4),
      tools: _searchStudentsTool,
    );

    final parts = data['candidates']?[0]?['content']?['parts'] as List?;

    if (parts == null || parts.isEmpty) {
      return 'How can I help you find talent?';
    }

    final functionCall = parts[0]['functionCall'];

    if (functionCall != null && functionCall['name'] == 'search_students') {
      return await _handleFunctionCall(functionCall);
    }

    final text = parts[0]['text'] ?? 'How can I help you find talent?';
    _startupChatHistory.add(_createMessage('model', text));
    lastMatchedStudents = [];
    return text;
  }

  static Future<String> _handleFunctionCall(
    Map<String, dynamic> functionCall,
  ) async {
    final skills = List<String>.from(functionCall['args']['skills'] ?? []);
    final searchResults = _executeSearchStudents(skills);
    lastMatchedStudents = searchResults;

    _startupChatHistory.add({
      'role': 'model',
      'parts': [
        {'functionCall': functionCall},
      ],
    });

    return await _getFinalResponseWithResults(searchResults, functionCall);
  }

  static List<StudentProfile> _executeSearchStudents(List<String> skills) {
    final skillsLower = skills.map((s) => s.toLowerCase()).toList();

    final matches = DummyData.students.where((student) {
      final studentSkillsLower = student.skills
          .map((s) => s.toLowerCase())
          .toList();
      return skillsLower.any(
        (skill) => studentSkillsLower.any(
          (s) => s.contains(skill) || skill.contains(s),
        ),
      );
    }).toList()..sort((a, b) => b.xpPoints.compareTo(a.xpPoints));

    return matches.take(10).toList();
  }

  static Future<String> _getFinalResponseWithResults(
    List<StudentProfile> results,
    Map<String, dynamic> functionCall,
  ) async {
    final resultSummary = results.isEmpty
        ? 'No students found matching those skills.'
        : results
              .map(
                (s) =>
                    '${s.name}: ${s.skills.take(4).join(", ")} (${s.xpPoints} XP)',
              )
              .join('\n');

    _startupChatHistory.add({
      'role': 'user',
      'parts': [
        {
          'functionResponse': {
            'name': functionCall['name'],
            'response': {'count': results.length, 'students': resultSummary},
          },
        },
      ],
    });

    final data = await _callEdgeFunction(
      contents: _startupChatHistory,
      generationConfig: _createGenerationConfig(260, temperature: 0.4),
      tools: _searchStudentsTool,
    );

    final text =
        _extractTextFromResponse(data) ??
        'Found ${results.length} matching students!';
    _startupChatHistory.add(_createMessage('model', text));
    return text;
  }

  static List<String> extractRecommendedRoles(String response) {
    final roleRegex = RegExp(r'\*\*([^*]+)\*\*');
    return response
        .split('\n')
        .map((line) => roleRegex.firstMatch(line)?.group(1)?.trim())
        .whereType<String>()
        .toList();
  }
}
