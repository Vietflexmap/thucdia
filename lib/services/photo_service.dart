import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models.dart';
import 'location_service.dart';
import 'storage_service.dart';

class PhotoService {
  PhotoService(this.storage, this.location);

  final StorageService storage;
  final LocationService location;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  Future<FieldPhoto?> capture() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      requestFullMetadata: true,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'field_photos'));
    await photosDir.create(recursive: true);
    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final id = _uuid.v4();
    final target = p.join(photosDir.path, '$id$ext');
    await File(picked.path).copy(target);

    double? lat;
    double? lon;
    double? accuracy;
    double? heading;
    try {
      final pos = await location.getCurrentPosition();
      lat = pos.latitude;
      lon = pos.longitude;
      accuracy = pos.accuracy;
      heading = pos.heading;
    } catch (_) {
      // Photo is still useful when GNSS is temporarily unavailable.
    }

    final photo = FieldPhoto(
      id: id,
      filePath: target,
      latitude: lat,
      longitude: lon,
      accuracy: accuracy,
      heading: heading,
      takenAt: DateTime.now(),
    );
    await storage.savePhoto(photo);
    return photo;
  }
}
