import 'package:flutter_test/flutter_test.dart';
import 'package:awa_shell/bridge/command_dispatcher.dart';

void main() {
  group('CommandDispatcher Tests', () {
    late CommandDispatcher dispatcher;

    setUp(() {
      dispatcher = CommandDispatcher();
    });

    test('handleMessage returns error if no arguments provided', () async {
      final response = await dispatcher.handleMessage([]);
      expect(response['error'], 'No arguments provided');
    });

    test('handleMessage returns METHOD_NOT_FOUND for unknown method', () async {
      final args = [
        {
          'id': 'test-id-123',
          'method': 'unknown.method',
          'params': {}
        }
      ];

      final response = await dispatcher.handleMessage(args);
      expect(response['id'], 'test-id-123');
      expect(response['error'], isNotNull);
      expect(response['error']['code'], 'METHOD_NOT_FOUND');
    });
  });
}
