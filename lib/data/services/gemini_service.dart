import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gemini_service.g.dart';

@riverpod
class GeminiService extends _$GeminiService {
  GenerativeModel? _model;
  bool _isInitialized = false;
  String? _initError;
  late final List<String> _apiKeys;

  int _currentKeyIndex = 0;

  List<String> _loadApiKeys() {
    final keys = <String>[];
    for (int i = 1; i <= 10; i++) {
      final key = dotenv.env['GEMINI_API_KEY_$i'];
      if (key != null && key.isNotEmpty) {
        keys.add(key);
      }
    }
    return keys;
  }

  @override
  FutureOr<void> build() async {
    _apiKeys = _loadApiKeys();
    _initializeModel();
  }

  void _initializeModel() {
    try {
      if (_apiKeys.isEmpty || _apiKeys.every((k) => k.isEmpty)) {
        _initError = 'API key not configured';
        _isInitialized = false;
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKeys[_currentKeyIndex],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );
      _isInitialized = true;
      _initError = null;
    } catch (e) {
      _initError = 'Failed to initialize AI: $e';
      _isInitialized = false;
    }
  }

  void _switchToNextKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    _initializeModel();
  }

  /// Execute API call with automatic key rotation on quota errors
  Future<T> _executeWithRetry<T>(Future<T> Function() apiCall) async {
    int attempts = 0;
    final maxAttempts = _apiKeys.length;

    while (attempts < maxAttempts) {
      try {
        return await apiCall();
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        // Check if it's a quota/rate limit error
        if (errorStr.contains('quota') ||
            errorStr.contains('429') ||
            errorStr.contains('rate limit') ||
            errorStr.contains('resource exhausted') ||
            errorStr.contains('too many requests')) {
          attempts++;
          if (attempts < maxAttempts) {
            _switchToNextKey();
            continue; // Retry with new key
          }
        }
        rethrow; // Non-quota error or all keys exhausted, rethrow
      }
    }
    throw Exception('All API keys quota exhausted');
  }

  bool get isAvailable => _isInitialized && _model != null;
  String? get initializationError => _initError;
  int get currentKeyIndex => _currentKeyIndex + 1; // 1-indexed for display
  int get totalKeys => _apiKeys.length;

  /// Summarize tasks for dashboard insights
  Future<String> summarizeTasks({
    required int totalTasks,
    required int completedTasks,
    required int overdueTasks,
    required int highPriorityTasks,
    required List<String> upcomingTaskTitles,
  }) async {
    if (!isAvailable) {
      return _getDefaultInsight(totalTasks, completedTasks, overdueTasks);
    }

    try {
      final prompt =
          '''
You are a productivity assistant. Based on this task data, give ONE short motivational insight or tip (max 15 words).

Data:
- Total tasks today: $totalTasks
- Completed: $completedTasks
- Overdue: $overdueTasks
- High priority pending: $highPriorityTasks
- Upcoming tasks: ${upcomingTaskTitles.take(3).join(', ')}

Give a brief, encouraging insight. Be specific to the data. No emojis. Just one sentence.
''';

      final response = await _executeWithRetry(
        () => _model!.generateContent([Content.text(prompt)]),
      );
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return _getDefaultInsight(totalTasks, completedTasks, overdueTasks);
    } catch (e) {
      return _getDefaultInsight(totalTasks, completedTasks, overdueTasks);
    }
  }

  String _getDefaultInsight(int total, int completed, int overdue) {
    if (overdue > 0) {
      return 'You have $overdue overdue tasks. Focus on those first!';
    }
    if (total == 0) {
      return 'No tasks for today. Plan your day!';
    }
    if (completed == total) {
      return 'All done! Great job today!';
    }
    final remaining = total - completed;
    return '$remaining tasks left. You got this!';
  }

  /// Get productivity suggestions based on task patterns
  Future<List<String>> getProductivitySuggestions({
    required int streak,
    required int weeklyCompleted,
    required int weeklyTotal,
    required double completionRate,
  }) async {
    if (!isAvailable) {
      return _getDefaultSuggestions(streak, completionRate);
    }

    try {
      final prompt =
          '''
Based on this productivity data, give 2-3 SHORT tips (max 10 words each).
Return as JSON array of strings only.

Data:
- Current streak: $streak days
- Weekly completed: $weeklyCompleted/$weeklyTotal tasks
- Completion rate: ${(completionRate * 100).toInt()}%

Example format: ["Tip one here", "Tip two here"]
''';

      final response = await _executeWithRetry(
        () => _model!.generateContent([Content.text(prompt)]),
      );
      final text = response.text ?? '[]';

      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
      if (jsonMatch != null) {
        try {
          final List<dynamic> parsed = json.decode(jsonMatch.group(0)!);
          return parsed.map((e) => e.toString()).take(3).toList();
        } catch (_) {}
      }
      return _getDefaultSuggestions(streak, completionRate);
    } catch (e) {
      return _getDefaultSuggestions(streak, completionRate);
    }
  }

  List<String> _getDefaultSuggestions(int streak, double rate) {
    final suggestions = <String>[];
    if (streak == 0) {
      suggestions.add('Start a streak by completing today\'s tasks');
    } else if (streak > 0) {
      suggestions.add('Keep your $streak day streak going!');
    }
    if (rate < 0.5) {
      suggestions.add('Try breaking big tasks into smaller ones');
    } else if (rate > 0.8) {
      suggestions.add('Great progress! Consider taking on more');
    }
    suggestions.add('Focus on high-priority tasks first');
    return suggestions.take(3).toList();
  }

  /// Summarize content
  Future<String> summarize(String content) async {
    if (!isAvailable) {
      return _initError ?? 'AI not available.';
    }
    try {
      final prompt =
          '''
Summarize this in 2-3 sentences:

$content
''';

      final response = await _executeWithRetry(
        () => _model!.generateContent([Content.text(prompt)]),
      );
      return response.text?.trim() ?? 'Could not generate summary.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Parse voice to task
  Future<Map<String, dynamic>> parseVoiceToTask(String transcript) async {
    if (!isAvailable) {
      return {
        'error': true,
        'message': _initError ?? 'AI not available.',
        'transcript': transcript,
      };
    }

    try {
      final prompt =
          '''
Extract task info from this voice input. Return ONLY JSON.

Voice: "$transcript"

JSON format:
{
  "title": "task title",
  "description": null,
  "projectName": "Inbox",
  "dueDate": null,
  "priority": 1
}
''';

      final response = await _executeWithRetry(
        () => _model!.generateContent([Content.text(prompt)]),
      );
      final text = response.text ?? '{}';

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        try {
          final parsed = json.decode(jsonMatch.group(0)!);
          return {'success': true, 'transcript': transcript, 'data': parsed};
        } catch (_) {}
      }
      return {'success': true, 'transcript': transcript, 'ai_response': text};
    } catch (e) {
      return {'error': true, 'message': '$e', 'transcript': transcript};
    }
  }

  /// Suggest subtasks for a task
  Future<List<String>> suggestSubtasks(
    String taskTitle,
    String? description,
  ) async {
    if (!isAvailable) return [];

    try {
      final prompt =
          '''
Suggest 3-4 subtasks for this task. Return JSON array only.

Task: $taskTitle
${description != null ? 'Details: $description' : ''}

Format: ["subtask1", "subtask2", "subtask3"]
''';

      final response = await _executeWithRetry(
        () => _model!.generateContent([Content.text(prompt)]),
      );
      final text = response.text ?? '[]';

      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
      if (jsonMatch != null) {
        final List<dynamic> parsed = json.decode(jsonMatch.group(0)!);
        return parsed.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Extract text from document image using OCR
  Future<String> extractTextFromImage(Uint8List imageBytes) async {
    if (!isAvailable) {
      return _initError ?? 'AI not available for OCR.';
    }

    try {
      final prompt = '''
Extract all text from this document image.
Return only the extracted text, clean and formatted.
Preserve paragraph structure and line breaks where appropriate.
If you cannot read the text clearly, indicate that.
''';

      final response = await _executeWithRetry(
        () => _model!.generateContent([
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
        ]),
      );

      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return 'Could not extract text from the image.';
    } catch (e) {
      return 'Error extracting text: ${e.toString()}';
    }
  }
}
