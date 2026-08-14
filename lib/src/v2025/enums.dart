/// The sender or recipient role in an MCP conversation.
enum Role {
  /// A human end user interacting with the client.
  user('user'),

  /// The AI model powering the client.
  assistant('assistant');

  /// The wire value sent over JSON-RPC.
  final String value;

  @override
  String toString() {
    return value;
  }

  /// Creates a [Role] wrapping the given wire [value].
  const Role(this.value);

  /// Looks up the [Role] whose wire value equals [str].
  factory Role.to(String str) => Role.values.firstWhere((e) => e.value == str);
}

/// UI theme variants for [Icon].
enum Theme {
  /// The dark theme variant.
  dark('dark'),

  /// The light theme variant.
  light('light');

  /// The wire value sent over JSON-RPC.
  final String value;

  /// Creates a [Theme] wrapping the given wire [value].
  const Theme(this.value);

  /// Looks up the [Theme] whose wire value equals [str].
  factory Theme.to(String str) =>
      Theme.values.firstWhere((e) => e.value == str);
  @override
  String toString() => value;
}

/// Syslog-compatible log severity levels (RFC-5424).
enum LoggingLevel {
  /// Detailed information useful for debugging.
  debug('debug'),

  /// Normal operational messages.
  info('info'),

  /// Normal but significant events.
  notice('notice'),

  /// Warning conditions.
  warning('warning'),

  /// Error conditions.
  error('error'),

  /// Critical conditions.
  critical('critical'),

  /// Action must be taken immediately.
  alert('alert'),

  /// The system is unusable.
  emergency('emergency');

  /// The wire value sent over JSON-RPC.
  final String value;

  /// Creates a [LoggingLevel] wrapping the given wire [value].
  const LoggingLevel(this.value);

  /// Looks up the [LoggingLevel] whose wire value equals [str].
  factory LoggingLevel.to(String str) =>
      LoggingLevel.values.firstWhere((e) => e.value == str);

  @override
  String toString() => value;
}

/// The user action in response to an elicitation request.
enum ActionType {
  /// The user submitted the form or accepted the request.
  accept('accept'),

  /// The user explicitly declined the request.
  decline('decline'),

  /// The user dismissed the request without a decision.
  cancel('cancel');

  /// The wire value sent over JSON-RPC.
  final String name;

  /// Creates an [ActionType] wrapping the given wire [name].
  const ActionType(this.name);

  /// Looks up the [ActionType] whose wire value equals [str].
  factory ActionType.to(String str) =>
      ActionType.values.firstWhere((e) => e.name == str);

  @override
  String toString() => name;
}

/// The JSON Schema `format` keyword for string-typed values.
enum StringFormat {
  /// A URI string.
  uri('uri'),

  /// An email address string.
  email('email'),

  /// An ISO 8601 date string.
  date('date'),

  /// An ISO 8601 date-time string.
  dateTime('date-time');

  /// The wire value sent over JSON-RPC.
  final String value;

  /// Creates a [StringFormat] wrapping the given wire [value].
  const StringFormat(this.value);

  /// Looks up the [StringFormat] whose wire value equals [str].
  factory StringFormat.to(String str) =>
      StringFormat.values.firstWhere((e) => e.value == str);

  @override
  String toString() => value;
}

/// The status of an MCP task.
enum TaskStatus {
  /// The task is still running.
  working('working'),

  /// The task finished successfully.
  completed('completed'),

  /// The task finished with an error.
  failed('failed'),

  /// The task was cancelled before completion.
  cancelled('cancelled'),

  /// The task is paused pending additional input.
  inputRequired('input_required');

  /// The wire value sent over JSON-RPC.
  final String value;

  /// Creates a [TaskStatus] wrapping the given wire [value].
  const TaskStatus(this.value);

  @override
  String toString() => value;

  /// Looks up the [TaskStatus] whose wire value equals [str].
  static TaskStatus to(String str) =>
      TaskStatus.values.firstWhere((e) => e.value == str);
}

/// Indicates the type of a result, so a client knows how to parse it.
enum ResultType {
  /// The result is complete and contains the final payload.
  complete('complete'),

  /// The result indicates further input is required before completion.
  inputRequired('input_required');

  /// The wire value sent over JSON-RPC.
  final String value;

  /// Creates a [ResultType] wrapping the given wire [value].
  const ResultType(this.value);

  @override
  String toString() => value;

  /// Looks up the [ResultType] whose wire value equals [str].
  static ResultType to(String str) =>
      ResultType.values.firstWhere((e) => e.value == str);
}
