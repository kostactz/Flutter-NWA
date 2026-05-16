import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:another_telephony/telephony.dart';
import '../bridge/models.dart';

class SmsService {
  static Future<Map<String, dynamic>> sendSms(Map<String, dynamic>? params) async {
    final String? number = params?['number'] as String?;
    final String? payload = params?['payload'] as String?;

    if (number == null || payload == null) {
      throw BridgeException(
        code: 'INVALID_PARAMS',
        message: 'number and payload are required',
      );
    }

    if (Platform.isAndroid) {
      final Telephony telephony = Telephony.instance;
      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      if (permissionsGranted == null || !permissionsGranted) {
        throw BridgeException(
          code: 'PERMISSION_DENIED',
          message: 'SMS permissions denied',
        );
      }

      await telephony.sendSms(
        to: number,
        message: payload,
      );
      return {'status': 'success', 'method': 'direct'};
    }

    // Fallback to composer for iOS/other platforms
    final Uri uri = Uri.parse('sms:$number?body=${Uri.encodeComponent(payload)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return {'status': 'success', 'method': 'composer'};
    } else {
      throw BridgeException(
        code: 'LAUNCH_FAILED',
        message: 'Could not open SMS composer',
      );
    }
  }

  static Future<Map<String, dynamic>> receiveSms() async {
    if (Platform.isIOS) {
      throw BridgeException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Manual entry required',
      );
    } else if (Platform.isAndroid) {
      final Telephony telephony = Telephony.instance;
      
      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      if (permissionsGranted == null || !permissionsGranted) {
        throw BridgeException(
          code: 'PERMISSION_DENIED',
          message: 'SMS permissions denied',
        );
      }

      final Completer<Map<String, dynamic>> completer = Completer();

      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          if (!completer.isCompleted) {
            completer.complete({'body': message.body, 'address': message.address});
          }
        },
        listenInBackground: false,
      );

      // Add a timeout to avoid waiting forever
      return completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          if (!completer.isCompleted) {
            throw BridgeException(
              code: 'TIMEOUT',
              message: 'No SMS received within the timeout period',
            );
          }
          return completer.future; // This won't actually be reached because we throw
        }
      );
    } else {
      throw BridgeException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Platform not supported',
      );
    }
  }
}
