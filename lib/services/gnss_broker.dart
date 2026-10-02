import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// Single native GNSS subscription shared by map, tracking, media and QA/QC.
/// Consumers subscribe to [stream] instead of opening independent Geolocator streams.
class GnssBroker {
  GnssBroker(this.location);

  final LocationService location;
  final StreamController<Position> _controller = StreamController<Position>.broadcast();
  StreamSubscription<Position>? _nativeSubscription;
  Position? _latest;

  Stream<Position> get stream => _controller.stream;
  Position? get latest => _latest;
  bool get isRunning => _nativeSubscription != null;

  Future<bool> start({int distanceFilter = 1}) async {
    if (_nativeSubscription != null) return true;
    if (!await location.ensureReady()) return false;
    _nativeSubscription = location.positionStream(distanceFilter: distanceFilter).listen(
      (position) {
        _latest = position;
        _controller.add(position);
      },
      onError: _controller.addError,
    );
    return true;
  }

  Future<void> stop() async {
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
