class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fields = const {},
    this.outcomeUncertain = false,
  });

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, String> fields;
  final bool outcomeUncertain;

  @override
  String toString() => message;
}
