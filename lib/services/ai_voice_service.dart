import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import './ai_orchestrator_service.dart';

/// AI Voice Service for Voice Interaction with AI
/// Provides speech-to-text and text-to-speech capabilities
class AIVoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static final FlutterTts _textToSpeech = FlutterTts();
  static bool _isInitialized = false;
  static bool _isListening = false;

  /// Initialize voice services
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize speech-to-text
      final speechAvailable = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );

      if (!speechAvailable) {
        debugPrint('Speech recognition not available');
      }

      // Initialize text-to-speech
      await _textToSpeech.setLanguage('en-US');
      await _textToSpeech.setPitch(1.0);
      await _textToSpeech.setSpeechRate(0.5);

      // Set completion handler
      _textToSpeech.setCompletionHandler(() {
        debugPrint('TTS completed');
      });

      _isInitialized = true;
      debugPrint('AIVoiceService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AIVoiceService: $e');
      // Don't rethrow - voice features are optional
    }
  }

  /// Voice query to AI consensus system
  static Future<void> voiceQueryAI({
    required String context,
    required Function(String) onResponse,
    Function(String)? onTranscript,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Speech-to-text
      final voiceQuery = await _listenForVoice(onPartialResult: onTranscript);

      if (voiceQuery.isEmpty) {
        onResponse('No voice input detected');
        return;
      }

      debugPrint('Voice query: $voiceQuery');

      // Send to AI consensus system
      final response = await AIOrchestratorService.analyzeWithConsensus(
        context: '$context\n\nVoice Query: $voiceQuery',
        analysisType: 'voice_interaction',
      );

      final aiResponse = response.finalRecommendation;

      // Text-to-speech response
      await speak(aiResponse);
      onResponse(aiResponse);
    } catch (e) {
      debugPrint('Voice query failed: $e');
      onResponse('Voice query failed: ${e.toString()}');
    }
  }

  /// Listen for voice input
  static Future<String> _listenForVoice({
    Function(String)? onPartialResult,
  }) async {
    final completer = Completer<String>();
    String recognizedWords = '';

    try {
      _isListening = true;

      await _speechToText.listen(
        onResult: (result) {
          recognizedWords = result.recognizedWords;

          // Call partial result callback
          if (onPartialResult != null) {
            onPartialResult(recognizedWords);
          }

          if (result.finalResult) {
            _isListening = false;
            completer.complete(recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );

      // Timeout fallback
      Future.delayed(const Duration(seconds: 11), () {
        if (!completer.isCompleted) {
          _isListening = false;
          completer.complete(recognizedWords);
        }
      });
    } catch (e) {
      debugPrint('Listen error: $e');
      _isListening = false;
      if (!completer.isCompleted) {
        completer.complete('');
      }
    }

    return completer.future;
  }

  /// Speak text using text-to-speech
  static Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    try {
      await _textToSpeech.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  /// Stop speaking
  static Future<void> stopSpeaking() async {
    try {
      await _textToSpeech.stop();
    } catch (e) {
      debugPrint('Stop TTS error: $e');
    }
  }

  /// Stop listening
  static Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
      }
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }
  }

  /// Check if currently listening
  static bool get isListening => _isListening;

  /// Check if speech recognition is available
  static Future<bool> isSpeechAvailable() async {
    if (!_isInitialized) await initialize();
    return _speechToText.isAvailable;
  }

  /// Get available languages
  static Future<List<String>> getAvailableLanguages() async {
    if (!_isInitialized) await initialize();

    try {
      final locales = await _speechToText.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      debugPrint('Failed to get languages: $e');
      return ['en-US'];
    }
  }

  /// Set speech language
  static Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) await initialize();

    try {
      await _textToSpeech.setLanguage(languageCode);
    } catch (e) {
      debugPrint('Failed to set language: $e');
    }
  }

  /// Set speech rate (0.0 to 1.0)
  static Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await initialize();

    try {
      await _textToSpeech.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Failed to set speech rate: $e');
    }
  }

  /// Set pitch (0.5 to 2.0)
  static Future<void> setPitch(double pitch) async {
    if (!_isInitialized) await initialize();

    try {
      await _textToSpeech.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      debugPrint('Failed to set pitch: $e');
    }
  }

  /// Get available TTS voices
  static Future<List<Map<String, String>>> getAvailableVoices() async {
    if (!_isInitialized) await initialize();

    try {
      final voices = await _textToSpeech.getVoices;
      return voices
          .map(
            (voice) => {
              'name': voice['name'] as String? ?? '',
              'locale': voice['locale'] as String? ?? '',
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Failed to get voices: $e');
      return [];
    }
  }

  /// Set TTS voice
  static Future<void> setVoice(Map<String, String> voice) async {
    if (!_isInitialized) await initialize();

    try {
      await _textToSpeech.setVoice(voice);
    } catch (e) {
      debugPrint('Failed to set voice: $e');
    }
  }
}
