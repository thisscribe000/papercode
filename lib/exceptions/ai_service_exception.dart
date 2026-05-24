class AIServiceException implements Exception {
  final String message;
  final int? statusCode;

  AIServiceException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'AIServiceException [$statusCode]: $message'
      : 'AIServiceException: $message';
}
