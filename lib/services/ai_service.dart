import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/ollama_provider.dart';
import '../exceptions/ai_service_exception.dart';
import 'ollama_service.dart';

class AIService {
  final AIProvider provider;
  final String apiKey;
  final String? customBaseUrl;
  final String? customModel;
  final OllamaService? _ollamaService;

  AIService._({
    required this.provider,
    this.apiKey = '',
    this.customBaseUrl,
    this.customModel,
    OllamaService? ollamaService,
  }) : _ollamaService = ollamaService;

  factory AIService.fromProvider(
    ConnectionProvider conn, {
    OllamaProvider? ollama,
  }) {
    if (conn.activeProviderType == AIProviderType.ollama) {
      final op = ollama ?? OllamaProvider();
      final service = OllamaService(baseUrl: op.ollamaHost);
      return AIService._(
        provider: conn.activeProvider,
        customModel: op.activeModelName,
        ollamaService: service,
      );
    }
    return AIService._(
      provider: conn.activeProvider,
      apiKey: conn.apiKey,
      customBaseUrl: conn.customBaseUrl,
      customModel: conn.customModel,
    );
  }

  String get _resolvedBaseUrl {
    if (provider.type == AIProviderType.custom && customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    return provider.baseUrl;
  }

  String get _resolvedModel {
    if (provider.type == AIProviderType.ollama && customModel != null) {
      return customModel!;
    }
    if (provider.type == AIProviderType.custom && customModel != null && customModel!.isNotEmpty) {
      return customModel!;
    }
    return provider.defaultModel;
  }

  Future<Stream<String>> sendMessage({
    required List<Map<String, String>> history,
    required String systemPrompt,
  }) async {
    if (_ollamaService != null) {
      return _ollamaService.chat(
        model: _resolvedModel,
        messages: [
          {'role': 'system', 'content': systemPrompt},
          ...history,
        ],
      );
    }

    final uri = Uri.parse('$_resolvedBaseUrl/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    if (provider.type == AIProviderType.gemini && apiKey.isNotEmpty) {
      headers['x-goog-api-key'] = apiKey;
    }

    final body = jsonEncode({
      'model': _resolvedModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...history,
      ],
      'stream': true,
      'max_tokens': 4096,
    });

    try {
      final request = http.Request('POST', uri)..headers.addAll(headers)..body = body;
      final response = await request.send();

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        throw AIServiceException(
          responseBody.isNotEmpty ? responseBody : 'Unknown error',
          statusCode: response.statusCode,
        );
      }

      return response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .transform(_SSEParser())
          .where((chunk) => chunk.isNotEmpty);
    } on http.ClientException catch (e) {
      throw AIServiceException('Connection failed: ${e.message}');
    } on AIServiceException {
      rethrow;
    } catch (e) {
      throw AIServiceException('Unexpected error: $e');
    }
  }
}

class _SSEParser extends StreamTransformerBase<String, String> {
  const _SSEParser();

  @override
  Stream<String> bind(Stream<String> stream) {
    return stream
        .where((line) => line.startsWith('data: '))
        .map((line) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') return '';
          try {
            final json = jsonDecode(data);
            final delta = json['choices']?[0]?['delta'];
            final content = delta?['content'] as String?;
            return content ?? '';
          } catch (_) {
            return '';
          }
        });
  }
}
