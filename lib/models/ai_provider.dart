import 'package:flutter/material.dart';

enum AIProviderType { deepseek, gemini, groq, openai, ollama, custom }

class AIProvider {
  final AIProviderType type;
  final String name;
  final String baseUrl;
  final String defaultModel;
  final String apiKeyLabel;
  final bool requiresApiKey;
  final bool isLocal;
  final Color dotColor;
  final String rateLimit;
  final String? keyHelperUrl;

  const AIProvider({
    required this.type,
    required this.name,
    required this.baseUrl,
    required this.defaultModel,
    required this.apiKeyLabel,
    this.requiresApiKey = true,
    this.isLocal = false,
    required this.dotColor,
    required this.rateLimit,
    this.keyHelperUrl,
  });

  bool get isFree => type == AIProviderType.gemini || type == AIProviderType.groq || type == AIProviderType.ollama;

  static const List<AIProvider> all = [
    AIProvider(
      type: AIProviderType.deepseek,
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-chat',
      apiKeyLabel: 'DeepSeek API Key',
      dotColor: Color(0xFFE8FF00),
      rateLimit: '40 req/min · paid',
      keyHelperUrl: 'https://platform.deepseek.com',
    ),
    AIProvider(
      type: AIProviderType.gemini,
      name: 'Google Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      defaultModel: 'gemini-2.0-flash',
      apiKeyLabel: 'Gemini API Key',
      dotColor: Color(0xFF4285F4),
      rateLimit: '15 req/min · 1M ctx · FREE',
      keyHelperUrl: 'https://aistudio.google.com',
    ),
    AIProvider(
      type: AIProviderType.groq,
      name: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      defaultModel: 'llama-3.3-70b-versatile',
      apiKeyLabel: 'Groq API Key',
      dotColor: Color(0xFFF55036),
      rateLimit: '30 req/min · free tier',
      keyHelperUrl: 'https://console.groq.com',
    ),
    AIProvider(
      type: AIProviderType.openai,
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o-mini',
      apiKeyLabel: 'OpenAI API Key',
      dotColor: Color(0xFF10A37F),
      rateLimit: 'paid',
      keyHelperUrl: 'https://platform.openai.com',
    ),
    AIProvider(
      type: AIProviderType.ollama,
      name: 'Ollama',
      baseUrl: 'http://localhost:11434/v1',
      defaultModel: 'llama3',
      apiKeyLabel: '',
      requiresApiKey: false,
      isLocal: true,
      dotColor: Color(0xFFA78BFA),
      rateLimit: 'local · unlimited',
    ),
    AIProvider(
      type: AIProviderType.custom,
      name: 'Custom',
      baseUrl: '',
      defaultModel: '',
      apiKeyLabel: 'Custom API Key',
      dotColor: Color(0xFF555550),
      rateLimit: 'depends on endpoint',
    ),
  ];

  AIProvider copyWith({String? baseUrl, String? defaultModel}) {
    return AIProvider(
      type: type,
      name: name,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      apiKeyLabel: apiKeyLabel,
      requiresApiKey: requiresApiKey,
      isLocal: isLocal,
      dotColor: dotColor,
      rateLimit: rateLimit,
      keyHelperUrl: keyHelperUrl,
    );
  }

  static AIProvider byType(AIProviderType type) {
    return all.firstWhere((p) => p.type == type);
  }
}
