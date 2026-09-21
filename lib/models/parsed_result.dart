class ParsedResult {
  final String type;
  final String rawValue;
  final String displayTitle;
  final String action;
  final Map<String, dynamic>? details;

  ParsedResult({
    required this.type,
    required this.rawValue,
    required this.displayTitle,
    required this.action,
    this.details,
  });
}
