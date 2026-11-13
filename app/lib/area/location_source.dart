import 'package:geolocator/geolocator.dart';

/// Why there is no position.
enum LocationProblem {
  /// The user said no to location access this time.
  denied,

  /// The user said no and the system will not ask again.
  deniedForever,

  /// Location services are off for the whole phone.
  serviceOff,

  /// No fix in time, or the platform failed.
  unavailable,
}

/// A position, or why there is none. Positions are never stored.
class LocationResult {
  const LocationResult.position(double this.latitude, double this.longitude)
    : problem = null;
  const LocationResult.problem(LocationProblem this.problem)
    : latitude = null,
      longitude = null;

  final double? latitude;
  final double? longitude;
  final LocationProblem? problem;
}

/// The phone's current position, asking for "while in use" access only.
abstract class LocationSource {
  Future<LocationResult> current();

  /// Opens the system screen that fixes [problem]: the phone's location
  /// settings when services are off, otherwise BinPal's own settings.
  Future<void> openSettings(LocationProblem problem);
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource({
    this.timeLimit = const Duration(seconds: 20),
  });

  final Duration timeLimit;

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.problem(LocationProblem.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // The prompt only offers "while using the app"; nothing asks for
        // background access.
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const LocationResult.problem(LocationProblem.denied);
        case LocationPermission.deniedForever:
          return const LocationResult.problem(LocationProblem.deniedForever);
        case LocationPermission.unableToDetermine:
          return const LocationResult.problem(LocationProblem.unavailable);
        case LocationPermission.whileInUse || LocationPermission.always:
          break;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return LocationResult.position(position.latitude, position.longitude);
    } on Exception {
      return const LocationResult.problem(LocationProblem.unavailable);
    }
  }

  @override
  Future<void> openSettings(LocationProblem problem) async {
    if (problem == LocationProblem.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
