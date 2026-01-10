import 'package:speech_to_text/speech_to_text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'speech_service.g.dart';

@riverpod
class SpeechService extends _$SpeechService {
  final SpeechToText _speechToText = SpeechToText();

  @override
  FutureOr<bool> build() async {
    return await _speechToText.initialize();
  }

  Future<void> startListening(Function(String) onResult) async {
    await _speechToText.listen(
      onResult: (result) => onResult(result.recognizedWords),
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }
}
