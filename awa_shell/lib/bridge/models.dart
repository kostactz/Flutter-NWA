class BridgeRequest {
  final String id;
  final String method;
  final Map<String, dynamic> params;

  BridgeRequest({
    required this.id,
    required this.method,
    required this.params,
  });

  factory BridgeRequest.fromJson(Map<String, dynamic> json) {
    return BridgeRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      params: json['params'] is Map 
          ? Map<String, dynamic>.from(json['params']) 
          : <String, dynamic>{},
    );
  }
}

class BridgeResponse {
  final String id;
  final dynamic data;
  final dynamic error;

  BridgeResponse({
    required this.id,
    this.data,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'error': error,
    };
  }
}

class BridgeException implements Exception {
  final String code;
  final String message;

  BridgeException({required this.code, required this.message});

  @override
  String toString() => message;
}

