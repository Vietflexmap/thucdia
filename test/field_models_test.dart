import 'package:flutter_test/flutter_test.dart';
import 'package:vietflex_thucdia/data/field_models.dart';

void main() {
  test('FeatureRecord database round-trip preserves geometry and properties', () {
    final now = DateTime.utc(2026, 10, 2, 2, 30);
    final feature = FeatureRecord(
      id: 'f-1',
      projectId: 'p-1',
      sessionId: 's-1',
      layerId: 'assets',
      geometryType: FeatureGeometryType.point,
      geometry: const {
        'type': 'Point',
        'coordinates': [106.0, 10.0],
      },
      properties: const {'name': 'Mốc 01'},
      accuracy: 0.03,
      source: 'rtk',
      qualityFlag: 'rtk_fixed',
      syncState: FieldSyncState.pending,
      createdAt: now,
      updatedAt: now,
    );

    final restored = FeatureRecord.fromMap(feature.toMap());
    expect(restored.geometry['type'], 'Point');
    expect(restored.properties['name'], 'Mốc 01');
    expect(restored.syncState, FieldSyncState.pending);
    expect(restored.qualityFlag, 'rtk_fixed');
  });
}
