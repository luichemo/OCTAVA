import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/deck_filters.dart';
import 'repositories.dart';

/// Sharing your approximate location, which makes distances work.
abstract interface class LocationRepository {
  Future<bool> hasLocation();

  /// Asks the device for an approximate position and saves it (the database
  /// rounds it to about 1 km). Explains problems with a [UserFacingException].
  Future<void> shareCurrentLocation();

  Future<void> stopSharing();
}

class DeviceLocationRepository implements LocationRepository {
  DeviceLocationRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<bool> hasLocation() async {
    try {
      return await _client.rpc('has_my_location') as bool;
    } catch (_) {
      return false; // Distances just stay off.
    }
  }

  @override
  Future<void> shareCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UserFacingException(
        'Location is turned off on this device. Turn it on and try again.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const UserFacingException(
        "OCTAVA isn't allowed to use your location. Allow it in your browser or phone settings, then try again.",
      );
    }
    final Position position;
    try {
      // Low accuracy is enough: distances are rounded to about 1 km anyway.
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const UserFacingException(
        "Couldn't find your location. Try again in a moment.",
      );
    }
    try {
      await _client.rpc(
        'set_my_location',
        params: {'lat': position.latitude, 'lng': position.longitude},
      );
    } catch (_) {
      throw const UserFacingException(
        "Couldn't save your location. Check your connection and try again.",
      );
    }
  }

  @override
  Future<void> stopSharing() async {
    try {
      await _client.rpc('set_my_location', params: {'lat': null, 'lng': null});
    } catch (_) {
      throw const UserFacingException(
        "Couldn't remove your location. Check your connection and try again.",
      );
    }
  }
}

/// Remembers swipe filters between visits.
abstract interface class FilterStore {
  Future<DeckFilters> load();
  Future<void> save(DeckFilters filters);
}

/// Keeps filters on this device, separately for each account.
class PrefsFilterStore implements FilterStore {
  PrefsFilterStore(this._userId);
  final String _userId;
  final _prefs = SharedPreferencesAsync();

  String get _key => 'deck_filters_$_userId';

  @override
  Future<DeckFilters> load() async {
    try {
      final saved = await _prefs.getString(_key);
      return saved == null
          ? const DeckFilters()
          : DeckFilters.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      return const DeckFilters(); // Unreadable or old format: start fresh.
    }
  }

  @override
  Future<void> save(DeckFilters filters) async {
    try {
      await _prefs.setString(_key, jsonEncode(filters.toJson()));
    } catch (_) {
      // Not remembering filters isn't worth bothering anyone about.
    }
  }
}

/// Filters kept only while the app runs. Used in tests and as a fallback.
class MemoryFilterStore implements FilterStore {
  DeckFilters _filters = const DeckFilters();

  @override
  Future<DeckFilters> load() async => _filters;

  @override
  Future<void> save(DeckFilters filters) async => _filters = filters;
}
