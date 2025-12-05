import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal();

  static const platform = MethodChannel('com.media_player_app/equalizer');

  bool _isEnabled = true;
  Map<int, double> _bands = {};
  int? _audioSessionId;

  Future<void> initialize(int audioSessionId) async {
    _audioSessionId = audioSessionId;
    await _loadSettings();
    if (Platform.isAndroid && _isEnabled) {
      await _applyEqualizerSettings();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('eq_enabled') ?? true;
      final bandsJson = prefs.getString('eq_bands');

      if (bandsJson != null) {
        final bandsMap = json.decode(bandsJson) as Map<String, dynamic>;
        _bands = bandsMap.map(
          (key, value) => MapEntry(int.parse(key), value as double),
        );
      }
    } catch (e) {
      print('Error loading equalizer settings: $e');
    }
  }

  Future<void> _applyEqualizerSettings() async {
    if (!Platform.isAndroid || _audioSessionId == null) {
      print(
        'Equalizer: Skipping - Platform: ${Platform.isAndroid}, Session ID: $_audioSessionId',
      );
      return;
    }

    try {
      print(
        'Equalizer: Applying settings - Enabled: $_isEnabled, Bands: ${_bands.length}',
      );

      await platform.invokeMethod('setEnabled', {'enabled': _isEnabled});

      if (_isEnabled && _bands.isNotEmpty) {
        // Convert bands to list format for native code
        final bandsList = _bands.entries
            .map((e) => {'frequency': e.key, 'gain': e.value})
            .toList();

        print(
          'Equalizer: Sending to native - Session: $_audioSessionId, Bands: $bandsList',
        );

        await platform.invokeMethod('setBands', {
          'audioSessionId': _audioSessionId,
          'bands': bandsList,
        });

        print('Equalizer: Successfully applied');
      }
    } catch (e) {
      print('Error applying equalizer: $e');
    }
  }

  Future<void> updateSettings() async {
    await _loadSettings();
    await _applyEqualizerSettings();
  }

  void dispose() {
    if (Platform.isAndroid && _audioSessionId != null) {
      try {
        platform.invokeMethod('release');
      } catch (e) {
        print('Error releasing equalizer: $e');
      }
    }
  }
}
