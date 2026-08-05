/// The sender or recipient role in an MCP conversation.
enum Role {
  user('user'),
  assistant('assistant');

  final String value;

  @override
  String toString() {
    return value;
  }

  const Role(this.value);
  factory Role.to(String str) => Role.values.firstWhere((e) => e.value == str);
}

/// UI theme variants for [Icon].
enum Theme {
  dark('dark'),
  light('light');

  final String value;

  const Theme(this.value);

  factory Theme.to(String str) =>
      Theme.values.firstWhere((e) => e.value == str);
  @override
  String toString() => value;
}

/// Syslog-compatible log severity levels (RFC-5424).
@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)
enum LoggingLevel {
  debug('debug'),
  info('info'),
  notice('notice'),
  warning('warning'),
  error('error'),
  critical('critical'),
  alert('alert'),
  emergency('emergency');

  final String value;

  const LoggingLevel(this.value);

  factory LoggingLevel.to(String str) =>
      LoggingLevel.values.firstWhere((e) => e.value == str);

  @override
  String toString() => value;
}

/// The user action in response to an elicitation request.
enum ActionType {
  accept('accept'),
  decline('decline'),
  cancel('cancel');

  final String name;

  const ActionType(this.name);

  factory ActionType.to(String str) =>
      ActionType.values.firstWhere((e) => e.name == str);

  @override
  String toString() => name;
}

enum StringFormat {
  uri('uri'),
  email('email'),
  date('date'),
  dateTime('date-time');

  final String value;
  const StringFormat(this.value);

  factory StringFormat.to(String str) =>
      StringFormat.values.firstWhere((e) => e.value == str);

  @override
  String toString() => value;
}

/// Cache scope for a cacheable result (see [DiscoverResult] and the various
/// `List*Result` / `ReadResourceResult` types).
enum CacheScope {
  public('public'),
  private('private');

  final String value;
  const CacheScope(this.value);
  @override
  String toString() => value;
  factory CacheScope.to(String str) =>
      CacheScope.values.firstWhere((e) => e.value == str);
}

enum ResultType {
  complete('complete'),
  inputRequired('input_required');

  final String value;
  const ResultType(this.value);
  @override
  String toString() => value;
  static ResultType to(String str) =>
      ResultType.values.firstWhere((e) => e.value == str);
}
