import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/territories_api.dart';
import '../data/territories_repository.dart';
import '../domain/territory.dart';
import '../domain/repositories/territories_repository.dart';
import '../domain/usecases/get_territories_for_bbox.dart';
import '../domain/value_objects/bbox.dart';

final territoriesApiProvider = Provider<TerritoriesApi>((ref) {
  return TerritoriesApi(ref.watch(dioProvider));
});

final territoriesRepositoryProvider = Provider<TerritoriesRepository>((ref) {
  return TerritoriesRepositoryImpl(ref.watch(territoriesApiProvider));
});

final getTerritoriesForBboxUseCaseProvider = Provider<GetTerritoriesForBboxUseCase>((ref) {
  return GetTerritoriesForBboxUseCase(ref.watch(territoriesRepositoryProvider));
});

final territoriesForBboxProvider = FutureProvider.family<List<Territory>, Bbox>((ref, bbox) async {
  return ref.watch(getTerritoriesForBboxUseCaseProvider)(bbox);
});


