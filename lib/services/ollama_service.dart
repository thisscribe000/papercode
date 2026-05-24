import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../exceptions/ai_service_exception.dart';

class OllamaModel {
  final String name;
  final String size;
  final String paramCount;
  final DateTime modified;

  OllamaModel({
    required this.name,
    required this.size,
    required this.paramCount,
    required this.modified,
  });
}

class OllamaDownloadProgress {
  final String status;
  final double? percent;
  final String? error;

  OllamaDownloadProgress({
    required this.status,
    this.percent,
    this.error,
  });
}

class OllamaService {
  final String baseUrl;

  OllamaService({required this.baseUrl});

  String get _apiUrl => baseUrl.replaceAll(RegExp(r'/+$'), '');

  Future<bool> isReachable() async {
    try {
      final uri = Uri.parse('$_apiUrl/api/tags');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<OllamaModel>> getModels() async {
    final uri = Uri.parse('$_apiUrl/api/tags');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw AIServiceException('Failed to list models: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final List models = data['models'] ?? [];
    return models.map((m) {
      final name = m['name'] as String? ?? '';
      final sizeBytes = m['size'] as int? ?? 0;
      final modifiedAt = m['modified_at'] as String? ?? '';
      final details = m['details'] as Map<String, dynamic>? ?? {};

      return OllamaModel(
        name: name.replaceFirst(RegExp(r':latest$'), ''),
        size: _formatSize(sizeBytes),
        paramCount: (details['parameter_size'] as String? ?? '').replaceAll('B', 'B'),
        modified: DateTime.tryParse(modifiedAt) ?? DateTime.now(),
      );
    }).toList();
  }

  Stream<OllamaDownloadProgress> pullModel(String modelName) async* {
    final uri = Uri.parse('$_apiUrl/api/pull');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'name': modelName, 'stream': true});

    try {
      final response = await request.send();
      if (response.statusCode != 200) {
        yield OllamaDownloadProgress(status: 'error', error: 'Failed to pull model: ${response.statusCode}');
        return;
      }

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.trim().isEmpty) continue;

        try {
          final data = jsonDecode(chunk.trim());
          final status = data['status'] as String? ?? '';

          if (status == 'success') {
            yield OllamaDownloadProgress(status: 'success', percent: 1.0);
          } else if (status == 'error') {
            yield OllamaDownloadProgress(status: 'error', error: data['error'] as String? ?? 'Unknown error');
          } else if (status.startsWith('pulling ')) {
            final total = data['total'] as int?;
            final completed = data['completed'] as int?;
            final percent = total != null && total > 0 ? (completed ?? 0) / total : null;
            yield OllamaDownloadProgress(status: 'pulling', percent: percent);
          } else {
            yield OllamaDownloadProgress(status: status);
          }
        } catch (_) {}
      }
    } catch (e) {
      yield OllamaDownloadProgress(status: 'error', error: 'Connection failed: $e');
    }
  }

  Future<void> deleteModel(String modelName) async {
    final uri = Uri.parse('$_apiUrl/api/delete');
    final request = http.Request('DELETE', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'name': modelName});

    final response = await request.send();
    if (response.statusCode != 200) {
      throw AIServiceException('Failed to delete model: ${response.statusCode}');
    }
  }

  Future<Stream<String>> chat({
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    final uri = Uri.parse('$_apiUrl/v1/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': model,
      'messages': messages,
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
          .transform(_OllamaSSEParser())
          .where((chunk) => chunk.isNotEmpty);
    } on http.ClientException catch (e) {
      throw AIServiceException('Connection failed: ${e.message}');
    } on AIServiceException {
      rethrow;
    } catch (e) {
      throw AIServiceException('Unexpected error: $e');
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _OllamaSSEParser extends StreamTransformerBase<String, String> {
  const _OllamaSSEParser();

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
