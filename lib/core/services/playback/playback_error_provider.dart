import 'package:classipod/core/services/audio_player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the latest playback error message from the audio handler so the
/// UI can surface it inline. Emits null while playback is healthy.
final playbackErrorProvider = StreamProvider<String?>((ref) {
  final handler = ref.watch(libraryAudioHandlerProvider);
  return handler.playbackState.map((state) => state.errorMessage);
});
