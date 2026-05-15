import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/sms_service.dart';
import '../core/bridge_logger.dart';
import 'models.dart';

class CommandDispatcher {
  final BridgeLogger _logger = BridgeLogger();

  void registerHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'AWABridge',
      callback: handleMessage,
    );
  }

  Future<Map<String, dynamic>> handleMessage(List<dynamic> args) async {
    if (args.isEmpty) {
      final errorResp = {'error': 'No arguments provided'};
      _logger.logRequest('UNKNOWN', errorResp);
      _logger.logResponse('UNKNOWN', errorResp);
      return errorResp;
    }

    final Map<String, dynamic> requestData = Map<String, dynamic>.from(args[0] as Map);
    final request = BridgeRequest.fromJson(requestData);

    _logger.logRequest(request.method, requestData);

    Map<String, dynamic> responseData;

    try {
      dynamic result;

      switch (request.method) {
        case 'location.current':
          result = await LocationService.getPosition();
          break;
        case 'media.camera':
          result = await MediaService.takePhoto(request.params);
          break;
        case 'media.filePicker':
          result = await MediaService.pickFile(request.params);
          break;
        case 'sms.send':
          result = await SmsService.sendSms(request.params);
          break;
        case 'sms.receive':
          result = await SmsService.receiveSms();
          break;
        default:
          responseData = BridgeResponse(
            id: request.id,
            error: {
              'code': 'METHOD_NOT_FOUND',
              'message': 'Method ${request.method} is not implemented',
            },
          ).toJson();
          _logger.logResponse(request.method, responseData);
          return responseData;
      }

      responseData = BridgeResponse(
        id: request.id,
        data: result,
      ).toJson();
      _logger.logResponse(request.method, responseData);
      return responseData;
    } on BridgeException catch (e) {
      responseData = BridgeResponse(
        id: request.id,
        error: {
          'code': e.code,
          'message': e.message,
        },
      ).toJson();
      _logger.logResponse(request.method, responseData);
      return responseData;
    } catch (e) {
      responseData = BridgeResponse(
        id: request.id,
        error: {
          'code': 'INTERNAL_ERROR',
          'message': e.toString(),
        },
      ).toJson();
      _logger.logResponse(request.method, responseData);
      return responseData;
    }
  }
}
