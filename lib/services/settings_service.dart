import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Volume Button Controls
  bool _volumeButtonsTrackSwitch = false;
  bool _pauseOnVolumeZero = true;
  bool _playOnVolumeNonZero = false;

  // Headset Controls
  String _headsetSingleTap = 'play_pause';
  String _headsetDoubleTap = 'next';
  String _headsetTripleTap = 'none';
  bool _playOnHeadsetPlugged = false;
  bool _playOnBluetoothHeadsetPlugged = false;
  bool _bluetoothCommandsAsHeadset = false;

  // Shake It
  bool _shakeEnabled = false;
  int _shakeSensitivity = 3;

  // Gestures
  bool _gesturesEnabled = true;
  String _swipeLeftToRight = 'previous';
  String _swipeRightToLeft = 'next';
  String _swipeTopToBottom = 'none';
  String _swipeBottomToTop = 'none';
  String _doubleTapLeft = 'rewind';
  String _doubleTapRight = 'forward';
  String _doubleTapCenter = 'play_pause';
  String _scrollVertically = 'volume';

  // Getters
  bool get volumeButtonsTrackSwitch => _volumeButtonsTrackSwitch;
  bool get pauseOnVolumeZero => _pauseOnVolumeZero;
  bool get playOnVolumeNonZero => _playOnVolumeNonZero;

  String get headsetSingleTap => _headsetSingleTap;
  String get headsetDoubleTap => _headsetDoubleTap;
  String get headsetTripleTap => _headsetTripleTap;
  bool get playOnHeadsetPlugged => _playOnHeadsetPlugged;
  bool get playOnBluetoothHeadsetPlugged => _playOnBluetoothHeadsetPlugged;
  bool get bluetoothCommandsAsHeadset => _bluetoothCommandsAsHeadset;

  bool get shakeEnabled => _shakeEnabled;
  int get shakeSensitivity => _shakeSensitivity;

  bool get gesturesEnabled => _gesturesEnabled;
  String get swipeLeftToRight => _swipeLeftToRight;
  String get swipeRightToLeft => _swipeRightToLeft;
  String get swipeTopToBottom => _swipeTopToBottom;
  String get swipeBottomToTop => _swipeBottomToTop;
  String get doubleTapLeft => _doubleTapLeft;
  String get doubleTapRight => _doubleTapRight;
  String get doubleTapCenter => _doubleTapCenter;
  String get scrollVertically => _scrollVertically;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    _volumeButtonsTrackSwitch =
        _prefs?.getBool('volumeButtonsTrackSwitch') ?? false;
    _pauseOnVolumeZero = _prefs?.getBool('pauseOnVolumeZero') ?? true;
    _playOnVolumeNonZero = _prefs?.getBool('playOnVolumeNonZero') ?? false;

    _headsetSingleTap = _prefs?.getString('headsetSingleTap') ?? 'play_pause';
    _headsetDoubleTap = _prefs?.getString('headsetDoubleTap') ?? 'next';
    _headsetTripleTap = _prefs?.getString('headsetTripleTap') ?? 'none';
    _playOnHeadsetPlugged = _prefs?.getBool('playOnHeadsetPlugged') ?? false;
    _playOnBluetoothHeadsetPlugged =
        _prefs?.getBool('playOnBluetoothHeadsetPlugged') ?? false;
    _bluetoothCommandsAsHeadset =
        _prefs?.getBool('bluetoothCommandsAsHeadset') ?? false;

    _shakeEnabled = _prefs?.getBool('shakeEnabled') ?? false;
    _shakeSensitivity = _prefs?.getInt('shakeSensitivity') ?? 3;

    _gesturesEnabled = _prefs?.getBool('gesturesEnabled') ?? true;
    _swipeLeftToRight = _prefs?.getString('swipeLeftToRight') ?? 'previous';
    _swipeRightToLeft = _prefs?.getString('swipeRightToLeft') ?? 'next';
    _swipeTopToBottom = _prefs?.getString('swipeTopToBottom') ?? 'none';
    _swipeBottomToTop = _prefs?.getString('swipeBottomToTop') ?? 'none';
    _doubleTapLeft = _prefs?.getString('doubleTapLeft') ?? 'rewind';
    _doubleTapRight = _prefs?.getString('doubleTapRight') ?? 'forward';
    _doubleTapCenter = _prefs?.getString('doubleTapCenter') ?? 'play_pause';
    _scrollVertically = _prefs?.getString('scrollVertically') ?? 'volume';

    notifyListeners();
  }

  // Volume Button Controls
  Future<void> setVolumeButtonsTrackSwitch(bool value) async {
    _volumeButtonsTrackSwitch = value;
    await _prefs?.setBool('volumeButtonsTrackSwitch', value);
    notifyListeners();
  }

  Future<void> setPauseOnVolumeZero(bool value) async {
    _pauseOnVolumeZero = value;
    await _prefs?.setBool('pauseOnVolumeZero', value);
    notifyListeners();
  }

  Future<void> setPlayOnVolumeNonZero(bool value) async {
    _playOnVolumeNonZero = value;
    await _prefs?.setBool('playOnVolumeNonZero', value);
    notifyListeners();
  }

  // Headset Controls
  Future<void> setHeadsetSingleTap(String value) async {
    _headsetSingleTap = value;
    await _prefs?.setString('headsetSingleTap', value);
    notifyListeners();
  }

  Future<void> setHeadsetDoubleTap(String value) async {
    _headsetDoubleTap = value;
    await _prefs?.setString('headsetDoubleTap', value);
    notifyListeners();
  }

  Future<void> setHeadsetTripleTap(String value) async {
    _headsetTripleTap = value;
    await _prefs?.setString('headsetTripleTap', value);
    notifyListeners();
  }

  Future<void> setPlayOnHeadsetPlugged(bool value) async {
    _playOnHeadsetPlugged = value;
    await _prefs?.setBool('playOnHeadsetPlugged', value);
    notifyListeners();
  }

  Future<void> setPlayOnBluetoothHeadsetPlugged(bool value) async {
    _playOnBluetoothHeadsetPlugged = value;
    await _prefs?.setBool('playOnBluetoothHeadsetPlugged', value);
    notifyListeners();
  }

  Future<void> setBluetoothCommandsAsHeadset(bool value) async {
    _bluetoothCommandsAsHeadset = value;
    await _prefs?.setBool('bluetoothCommandsAsHeadset', value);
    notifyListeners();
  }

  // Shake It
  Future<void> setShakeEnabled(bool value) async {
    _shakeEnabled = value;
    await _prefs?.setBool('shakeEnabled', value);
    notifyListeners();
  }

  Future<void> setShakeSensitivity(int value) async {
    _shakeSensitivity = value;
    await _prefs?.setInt('shakeSensitivity', value);
    notifyListeners();
  }

  // Gestures
  Future<void> setGesturesEnabled(bool value) async {
    _gesturesEnabled = value;
    await _prefs?.setBool('gesturesEnabled', value);
    notifyListeners();
  }

  Future<void> setSwipeLeftToRight(String value) async {
    _swipeLeftToRight = value;
    await _prefs?.setString('swipeLeftToRight', value);
    notifyListeners();
  }

  Future<void> setSwipeRightToLeft(String value) async {
    _swipeRightToLeft = value;
    await _prefs?.setString('swipeRightToLeft', value);
    notifyListeners();
  }

  Future<void> setSwipeTopToBottom(String value) async {
    _swipeTopToBottom = value;
    await _prefs?.setString('swipeTopToBottom', value);
    notifyListeners();
  }

  Future<void> setSwipeBottomToTop(String value) async {
    _swipeBottomToTop = value;
    await _prefs?.setString('swipeBottomToTop', value);
    notifyListeners();
  }

  Future<void> setDoubleTapLeft(String value) async {
    _doubleTapLeft = value;
    await _prefs?.setString('doubleTapLeft', value);
    notifyListeners();
  }

  Future<void> setDoubleTapRight(String value) async {
    _doubleTapRight = value;
    await _prefs?.setString('doubleTapRight', value);
    notifyListeners();
  }

  Future<void> setDoubleTapCenter(String value) async {
    _doubleTapCenter = value;
    await _prefs?.setString('doubleTapCenter', value);
    notifyListeners();
  }

  Future<void> setScrollVertically(String value) async {
    _scrollVertically = value;
    await _prefs?.setString('scrollVertically', value);
    notifyListeners();
  }

  // Reset all settings to default
  Future<void> resetToDefaults() async {
    // Reset Volume Button Controls
    _volumeButtonsTrackSwitch = false;
    _pauseOnVolumeZero = true;
    _playOnVolumeNonZero = false;

    // Reset Headset Controls
    _headsetSingleTap = 'play_pause';
    _headsetDoubleTap = 'next';
    _headsetTripleTap = 'none';
    _playOnHeadsetPlugged = false;
    _playOnBluetoothHeadsetPlugged = false;
    _bluetoothCommandsAsHeadset = false;

    // Reset Shake It
    _shakeEnabled = false;
    _shakeSensitivity = 3;

    // Reset Gestures
    _gesturesEnabled = true;
    _swipeLeftToRight = 'previous';
    _swipeRightToLeft = 'next';
    _swipeTopToBottom = 'none';
    _swipeBottomToTop = 'none';
    _doubleTapLeft = 'rewind';
    _doubleTapRight = 'forward';
    _doubleTapCenter = 'play_pause';
    _scrollVertically = 'volume';

    // Clear all preferences
    await _prefs?.clear();

    // Save default values
    await _prefs?.setBool(
      'volumeButtonsTrackSwitch',
      _volumeButtonsTrackSwitch,
    );
    await _prefs?.setBool('pauseOnVolumeZero', _pauseOnVolumeZero);
    await _prefs?.setBool('playOnVolumeNonZero', _playOnVolumeNonZero);

    await _prefs?.setString('headsetSingleTap', _headsetSingleTap);
    await _prefs?.setString('headsetDoubleTap', _headsetDoubleTap);
    await _prefs?.setString('headsetTripleTap', _headsetTripleTap);
    await _prefs?.setBool('playOnHeadsetPlugged', _playOnHeadsetPlugged);
    await _prefs?.setBool(
      'playOnBluetoothHeadsetPlugged',
      _playOnBluetoothHeadsetPlugged,
    );
    await _prefs?.setBool(
      'bluetoothCommandsAsHeadset',
      _bluetoothCommandsAsHeadset,
    );

    await _prefs?.setBool('shakeEnabled', _shakeEnabled);
    await _prefs?.setInt('shakeSensitivity', _shakeSensitivity);

    await _prefs?.setBool('gesturesEnabled', _gesturesEnabled);
    await _prefs?.setString('swipeLeftToRight', _swipeLeftToRight);
    await _prefs?.setString('swipeRightToLeft', _swipeRightToLeft);
    await _prefs?.setString('swipeTopToBottom', _swipeTopToBottom);
    await _prefs?.setString('swipeBottomToTop', _swipeBottomToTop);
    await _prefs?.setString('doubleTapLeft', _doubleTapLeft);
    await _prefs?.setString('doubleTapRight', _doubleTapRight);
    await _prefs?.setString('doubleTapCenter', _doubleTapCenter);
    await _prefs?.setString('scrollVertically', _scrollVertically);

    notifyListeners();
  }
}
