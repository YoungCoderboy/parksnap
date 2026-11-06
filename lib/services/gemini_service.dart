import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Result returned by Gemini extraction.
class GeminiResult {
  final String plate;
  final String type;
  final double confidence;

  const GeminiResult({
    required this.plate,
    required this.type,
    required this.confidence,
  });

  @override
  String toString() =>
      'GeminiResult(plate: $plate, type: $type, confidence: $confidence)';
}

/// Typed exception from Gemini service.
class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
  @override
  String toString() => 'GeminiException: $message';
}

/// Service that communicates with the Gemini 2.5 Flash model to extract
/// vehicle license plate data from an image.
class GeminiService {
  static const _modelName = 'gemini-2.5-flash';

  static const _prompt = '''
Analyze this image of a vehicle at a parking gate.

Your tasks:
1. Extract the license plate number as a clean text string (remove spaces if needed, preserve format like "MH12AB1234").
2. Identify the vehicle type: choose exactly one of ["Car", "Bike", "Truck", "Other"].
3. Estimate your extraction confidence as an integer from 0 to 100.

IMPORTANT: If no license plate is visible or legible, return plate as "UNKNOWN".

Respond ONLY with valid JSON in this exact format, no markdown, no extra text:
{"plate": "...", "type": "...", "confidence": ...}
''';

  final GenerativeModel _model;

  GeminiService(String apiKey)
      : _model = GenerativeModel(
          model: _modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,
            topP: 0.95,
            responseMimeType: 'application/json',
          ),
        );

  /// Extracts vehicle data from an image file at [imagePath].
  /// Throws [GeminiException] on failure.
  Future<GeminiResult> extractVehicleData(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw GeminiException('Image file not found: $imagePath');
    }

    final imageBytes = await file.readAsBytes();
    final mimeType = _getMimeType(imagePath);

    final content = [
      Content.multi([
        TextPart(_prompt),
        DataPart(mimeType, imageBytes),
      ]),
    ];

    GenerateContentResponse response;
    try {
      response = await _model.generateContent(content);
    } on GenerativeAIException catch (e) {
      throw GeminiException('Gemini API error: ${e.message}');
    } catch (e) {
      throw GeminiException('Network or unexpected error: $e');
    }

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw GeminiException('Empty response from Gemini.');
    }

    return _parseResponse(text.trim());
  }

  GeminiResult _parseResponse(String raw) {
    // Strip any accidental markdown code fences
    String cleaned = raw;
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw GeminiException('Failed to parse JSON response: $cleaned');
    }

    final plate = (json['plate'] as String?)?.trim().toUpperCase() ?? 'UNKNOWN';
    final type = _normalizeType(json['type'] as String? ?? 'Other');
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;

    return GeminiResult(plate: plate, type: type, confidence: confidence);
  }

  String _normalizeType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('car')) return 'Car';
    if (lower.contains('bike') || lower.contains('motor')) return 'Bike';
    if (lower.contains('truck') || lower.contains('van') || lower.contains('bus')) return 'Truck';
    return 'Other';
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
