import 'package:geolocator/geolocator.dart';

class GeoHelper {
  static const instance = GeoHelper();

  const GeoHelper();

  Future<bool> permissionEnabled() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    return true;
  }
}
