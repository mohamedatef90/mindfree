import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/data/services/gemini_service.dart';
import 'package:mindfree/data/services/speech_service.dart';

class VoiceTaskDialog extends ConsumerStatefulWidget {
  const VoiceTaskDialog({super.key});

  @override
  ConsumerState<VoiceTaskDialog> createState() => _VoiceTaskDialogState();
}

class _VoiceTaskDialogState extends ConsumerState<VoiceTaskDialog> {
  String _transcript = 'Press the mic and speak...';
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI Voice Task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              _transcript,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isListening ? Colors.white : AppColors.textSecondary,
                fontStyle: _isListening ? FontStyle.italic : null,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _toggleListening,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.accentPink
                      : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isListening
                                  ? AppColors.accentPink
                                  : AppColors.primary)
                              .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleListening() async {
    if (_isListening) {
      await ref.read(speechServiceProvider.notifier).stopListening();
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
      _processAi();
    } else {
      await ref.read(speechServiceProvider.notifier).startListening((text) {
        setState(() => _transcript = text);
      });
      setState(() => _isListening = true);
    }
  }

  void _processAi() async {
    final aiResult = await ref
        .read(geminiServiceProvider.notifier)
        .parseVoiceToTask(_transcript);
    // In a real app, you'd parse the JSON and add the task
    setState(() {
      _transcript = 'AI detected: ${aiResult['ai_response']}';
      _isProcessing = false;
    });
  }
}
