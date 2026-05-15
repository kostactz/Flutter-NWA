import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/bridge_logger.dart';

class DebugOverlay extends StatelessWidget {
  const DebugOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BridgeLogEntry>>(
      valueListenable: BridgeLogger().logs,
      builder: (context, logs, child) {
        if (logs.isEmpty) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          ignoring: true, // Allow clicks to pass through to the WebView
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 80, bottom: 20, left: 10, right: 10),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final isReq = log.direction == 'IN';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isReq ? Colors.blue.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${log.direction} - ${log.method}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}.${log.timestamp.millisecond}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _prettyJson(log.payload),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _prettyJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}
