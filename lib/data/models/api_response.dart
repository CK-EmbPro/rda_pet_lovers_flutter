class ActionResponse<T> {
  final String message;
  final T? data;
  final bool success;

  ActionResponse({
    required this.message,
    this.data,
    this.success = true,
  });

  factory ActionResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    // Some backend responses wrap data in 'data' field, others don't.
    // Our ServicesController now wraps them.
    final dynamic rawData = json['data'];
    final dynamic rawMessage = json['message'];
    
    return ActionResponse(
      message: rawMessage?.toString() ?? 'Action completed successfully',
      data: rawData != null ? fromJson(rawData) : null,
      success: json['success'] as bool? ?? true,
    );
  }

  factory ActionResponse.error(String message) {
    return ActionResponse(
      message: message,
      success: false,
    );
  }
}
