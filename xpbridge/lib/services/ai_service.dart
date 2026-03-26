import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/student_profile.dart';
import '../models/startup_profile.dart';
import '../data/dummy_data.dart';

class AiService {
  // Constants
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // State
  static String? _apiKey;
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
User: "hi" -> "Hey there! 👋 What kind of talent are you looking for?"
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

  // Initialization
  static Future<void> initialize({bool forceReload = false}) async {
    if (forceReload || _apiKey == null) {
      _apiKey = AppConfig.instance.geminiApiKey;
    }
    if (_apiKey == null || _apiKey!.isEmpty || _apiKey == 'your_api_key_here') {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    _chatHistory.clear();
  }

  static Future<void> _ensureInitialized() async {
    if (_apiKey == null) await initialize();
  }

  // Helper methods
  static Uri _buildUrl([String? suffix]) => Uri.parse(
    '$_baseUrl/models/$_model:generateContent?key=$_apiKey${suffix ?? ''}',
  );

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

  static Future<http.Response> _post(Uri url, Map<String, dynamic> body) =>
      http.post(url, headers: _headers, body: jsonEncode(body));

  // Reset methods
  static void resetChat() => _chatHistory.clear();

  static void resetStartupChat() {
    _startupChatHistory.clear();
    lastMatchedStudents = [];
    _apiKey = null;
  }

  // Student chat methods
  static Future<String> sendMessage(String message) async {
    await _ensureInitialized();

    if (message.toLowerCase() == 'list models') {
      return await listModels();
    }

    _chatHistory.add(_createMessage('user', message));

    try {
      return await _callGeminiApi();
    } catch (e) {
      _chatHistory.removeLast();
      return 'Error: $e';
    }
  }

  static Future<String> sendMessageWithContext(
    String message,
    StudentProfile? profile,
  ) async {
    await _ensureInitialized();

    final fullMessage = (_chatHistory.isEmpty && profile != null)
        ? _buildStudentContext(profile, message)
        : message;

    _chatHistory.add(_createMessage('user', fullMessage));

    try {
      return await _callGeminiApi();
    } catch (e) {
      _chatHistory.removeLast();
      return 'Error: $e';
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

  static Future<String> listModels() async {
    await _ensureInitialized();
    final response = await http.get(Uri.parse('$_baseUrl/models?key=$_apiKey'));
    return response.body;
  }

  static Future<String> _callGeminiApi() async {
    final contents = _chatHistory.length == 1
        ? [
            _createMessage(
              'user',
              '$_studentSystemPrompt\n\n${_chatHistory.first['parts'][0]['text']}',
            ),
          ]
        : List<Map<String, dynamic>>.from(_chatHistory);

    final response = await _post(_buildUrl(), {
      'contents': contents,
      'generationConfig': _createGenerationConfig(360, temperature: 0.5),
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text =
          _extractTextFromResponse(data) ??
          'Sorry, I could not generate a response.';
      _chatHistory.add(_createMessage('model', text));
      return text;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['error']?['message'] ??
            'API request failed: ${response.statusCode}',
      );
    }
  }

  // Startup chat methods
  static Future<String> sendMessageForStartup(
    String message,
    StartupProfile? profile,
  ) async {
    await _ensureInitialized();

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
    final url = _buildUrl();

    final contents = _startupChatHistory.length == 1
        ? [
            _createMessage(
              'user',
              '$_startupSystemPrompt\n\n${_startupChatHistory.first['parts'][0]['text']}',
            ),
          ]
        : List<Map<String, dynamic>>.from(_startupChatHistory);

    final response = await _post(url, {
      'contents': contents,
      'tools': _searchStudentsTool,
      'generationConfig': _createGenerationConfig(320, temperature: 0.4),
    });

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['error']?['message'] ??
            'API request failed: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    final parts = data['candidates']?[0]?['content']?['parts'] as List?;

    if (parts == null || parts.isEmpty) {
      return 'How can I help you find talent?';
    }

    final functionCall = parts[0]['functionCall'];

    if (functionCall != null && functionCall['name'] == 'search_students') {
      return await _handleFunctionCall(url, functionCall);
    }

    final text = parts[0]['text'] ?? 'How can I help you find talent?';
    _startupChatHistory.add(_createMessage('model', text));
    lastMatchedStudents = [];
    return text;
  }

  static Future<String> _handleFunctionCall(
    Uri url,
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

    return await _getFinalResponseWithResults(url, searchResults, functionCall);
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
    Uri url,
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

    final response = await _post(url, {
      'contents': _startupChatHistory,
      'tools': _searchStudentsTool,
      'generationConfig': _createGenerationConfig(260, temperature: 0.4),
    });

    if (response.statusCode == 200) {
      final text =
          _extractTextFromResponse(jsonDecode(response.body)) ??
          'Found ${results.length} matching students!';
      _startupChatHistory.add(_createMessage('model', text));
      return text;
    }

    return 'Found ${results.length} students matching your criteria! Check them out below.';
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
