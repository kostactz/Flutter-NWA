import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bridge/models.dart';

class LocationService {
  static Future<Map<String, dynamic>> getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw BridgeException(
        code: 'SERVICE_DISABLED',
        message: 'Location services are disabled.',
      );
    }

    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      if (status.isDenied) {
        throw BridgeException(
          code: 'PERMISSION_DENIED',
          message: 'Location permissions are denied',
        );
      }
    }
    
    if (status.isPermanentlyDenied) {
      throw BridgeException(
        code: 'PERMISSION_DENIED',
        message: 'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
    };
  }
}
