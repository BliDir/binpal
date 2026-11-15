import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'photo_matcher.dart';

/// Reads a photo on the phone: what is in it, and the text printed on it.
abstract interface class PhotoAnalyzer {
  Future<PhotoSignals> analyze(String path);
}

/// Google ML Kit's image labeling on both platforms. Text is read with
/// ML Kit's Japanese recognizer on Android and Apple's Vision on iOS, where
/// the ML Kit plugin reads Latin text only (so not プラ, アルミ or 紙).
///
/// Everything runs on the phone with bundled models; nothing is sent.
class DevicePhotoAnalyzer implements PhotoAnalyzer {
  DevicePhotoAnalyzer();

  static const _iosText = MethodChannel('binpal/text_recognition');

  final _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.4),
  );
  TextRecognizer? _androidText;

  @override
  Future<PhotoSignals> analyze(String path) async {
    final input = InputImage.fromFilePath(path);
    final (labels, text) = await (
      _readLabels(input),
      _readText(path, input),
    ).wait;
    return PhotoSignals(
      labels: labels ?? const [],
      text: text ?? '',
      modelsMissing: labels == null || text == null,
    );
  }

  /// Null when labeling failed, for example while Play Services is still
  /// downloading the model after install. Whatever else worked is still used.
  Future<List<PhotoLabel>?> _readLabels(InputImage input) async {
    try {
      return [
        for (final l in await _labeler.processImage(input))
          PhotoLabel(l.label, l.confidence),
      ];
    } on Object catch (e) {
      debugPrint('Photo labeling failed: $e');
      return null;
    }
  }

  /// The recognised text, one line per line; null when it couldn't be read.
  Future<String?> _readText(String path, InputImage input) async {
    try {
      if (Platform.isIOS) {
        return await _iosText.invokeMethod<String>('recognize', {
              'path': path,
            }) ??
            '';
      }
      final recognizer = _androidText ??= TextRecognizer(
        script: TextRecognitionScript.japanese,
      );
      final result = await recognizer.processImage(input);
      return [
        for (final block in result.blocks)
          for (final line in block.lines) line.text,
      ].join('\n');
    } on Object catch (e) {
      debugPrint('Photo text recognition failed: $e');
      return null;
    }
  }

  Future<void> close() async {
    await _labeler.close();
    await _androidText?.close();
  }
}
