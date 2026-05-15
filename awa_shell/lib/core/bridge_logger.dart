import 'package:flutter/foundation.dart';

class BridgeLogEntry {
  final DateTime timestamp;
  final String direction; // 'IN' (Request) or 'OUT' (Response)
  final String method;
  final Map<String, dynamic> payload;

  BridgeLogEntry({
    required this.timestamp,
    required this.direction,
    required this.method,
    required this.payload,
  });
}

class BridgeLogger {
  static final BridgeLogger _instance = BridgeLogger._internal();

  factory BridgeLogger() {
    return _instance;
  }

  BridgeLogger._internal();

  final ValueNotifier<List<BridgeLogEntry>> logs = ValueNotifier([]);

  void logRequest(String method, Map<String, dynamic> payload) {
    _addLog(BridgeLogEntry(
      timestamp: DateTime.now(),
      direction: 'IN',
      method: method,
      payload: payload,
    ));
  }

  void logResponse(String method, Map<String, dynamic> payload) {
    _addLog(BridgeLogEntry(
      timestamp: DateTime.now(),
      direction: 'OUT',
      method: method,
      payload: payload,
    ));
  }
  
  void clear() {
    logs.value = [];
  }

  void _addLog(BridgeLogEntry entry) {
    final currentLogs = List<BridgeLogEntry>.from(logs.value);
    currentLogs.insert(0, entry);
    if (currentLogs.length > 100) {
      currentLogs.removeLast();
    }
    logs.value = currentLogs;
  }
}
