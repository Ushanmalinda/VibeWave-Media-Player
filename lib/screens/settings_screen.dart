import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  Future<void> _initialize() async {
    await _settingsService.initialize();
    setState(() => _isLoading = false);
  }

  void _showActionDialog(
    String title,
    String currentValue,
    Function(String) onSelect,
  ) {
    final actions = {
      'none': 'None',
      'play_pause': 'Play / Pause',
      'next': 'Next track',
      'previous': 'Previous track',
      'rewind': 'Rewind',
      'forward': 'Fast forward',
      'volume': 'Adjust volume',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions.entries.map((entry) {
            return RadioListTile<String>(
              value: entry.key,
              groupValue: currentValue,
              activeColor: Colors.orange,
              title: Text(
                entry.value,
                style: const TextStyle(color: Colors.white),
              ),
              onChanged: (value) {
                if (value != null) {
                  onSelect(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Volume Buttons Section
        _buildSectionHeader('Volume Buttons'),
        _buildSwitchTile(
          title: 'Double tap switches the tracks',
          subtitle:
              'Current volume level must be at 2 points above minimum and 2 points below maximum',
          value: _settingsService.volumeButtonsTrackSwitch,
          onChanged: (value) =>
              _settingsService.setVolumeButtonsTrackSwitch(value),
        ),
        _buildSwitchTile(
          title: 'Pause playback when volume become zero',
          value: _settingsService.pauseOnVolumeZero,
          onChanged: (value) => _settingsService.setPauseOnVolumeZero(value),
        ),
        _buildSwitchTile(
          title: 'Start playing when volume become non-zero',
          value: _settingsService.playOnVolumeNonZero,
          onChanged: (value) => _settingsService.setPlayOnVolumeNonZero(value),
        ),

        const SizedBox(height: 24),

        // Headset Section
        _buildSectionHeader('Headset'),
        _buildActionTile(
          title: 'Action on single tap',
          subtitle: _getActionLabel(_settingsService.headsetSingleTap),
          onTap: () => _showActionDialog(
            'Action on single tap',
            _settingsService.headsetSingleTap,
            (value) => _settingsService.setHeadsetSingleTap(value),
          ),
        ),
        _buildActionTile(
          title: 'Action on double tap',
          subtitle: _getActionLabel(_settingsService.headsetDoubleTap),
          onTap: () => _showActionDialog(
            'Action on double tap',
            _settingsService.headsetDoubleTap,
            (value) => _settingsService.setHeadsetDoubleTap(value),
          ),
        ),
        _buildActionTile(
          title: 'Action on triple tap',
          subtitle: _getActionLabel(_settingsService.headsetTripleTap),
          onTap: () => _showActionDialog(
            'Action on triple tap',
            _settingsService.headsetTripleTap,
            (value) => _settingsService.setHeadsetTripleTap(value),
          ),
        ),
        _buildSwitchTile(
          title: 'Play when headset plugged in',
          value: _settingsService.playOnHeadsetPlugged,
          onChanged: (value) => _settingsService.setPlayOnHeadsetPlugged(value),
        ),
        _buildSwitchTile(
          title: 'Play when bluetooth-headset plugged in',
          value: _settingsService.playOnBluetoothHeadsetPlugged,
          onChanged: (value) =>
              _settingsService.setPlayOnBluetoothHeadsetPlugged(value),
        ),
        _buildSwitchTile(
          title: 'Bluetooth-commands as headset commands',
          subtitle:
              'Set the option if single/double/triple taps from your bluetooth-headset does not work as you setup above',
          value: _settingsService.bluetoothCommandsAsHeadset,
          onChanged: (value) =>
              _settingsService.setBluetoothCommandsAsHeadset(value),
        ),

        const SizedBox(height: 24),

        // Shake It Section
        _buildSectionHeader('Shake It'),
        _buildSwitchTile(
          title: 'Enable shake it feature',
          subtitle: 'Shake your device to play next track',
          value: _settingsService.shakeEnabled,
          onChanged: (value) => _settingsService.setShakeEnabled(value),
        ),
        _buildSliderTile(
          title: 'Shake sensitivity',
          value: _settingsService.shakeSensitivity.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (value) =>
              _settingsService.setShakeSensitivity(value.round()),
        ),

        const SizedBox(height: 24),

        // Gestures Section
        _buildSectionHeader('Gestures'),
        _buildSwitchTile(
          title: 'Allow gestures',
          subtitle: 'Allow gesture control on album art area',
          value: _settingsService.gesturesEnabled,
          onChanged: (value) => _settingsService.setGesturesEnabled(value),
        ),
        _buildActionTile(
          title: 'Swipe left-to-right',
          subtitle: _getActionLabel(_settingsService.swipeLeftToRight),
          onTap: () => _showActionDialog(
            'Swipe left-to-right',
            _settingsService.swipeLeftToRight,
            (value) => _settingsService.setSwipeLeftToRight(value),
          ),
        ),
        _buildActionTile(
          title: 'Swipe right-to-left',
          subtitle: _getActionLabel(_settingsService.swipeRightToLeft),
          onTap: () => _showActionDialog(
            'Swipe right-to-left',
            _settingsService.swipeRightToLeft,
            (value) => _settingsService.setSwipeRightToLeft(value),
          ),
        ),
        _buildActionTile(
          title: 'Swipe top-to-bottom',
          subtitle: _getActionLabel(_settingsService.swipeTopToBottom),
          onTap: () => _showActionDialog(
            'Swipe top-to-bottom',
            _settingsService.swipeTopToBottom,
            (value) => _settingsService.setSwipeTopToBottom(value),
          ),
        ),
        _buildActionTile(
          title: 'Swipe bottom-to-top',
          subtitle: _getActionLabel(_settingsService.swipeBottomToTop),
          onTap: () => _showActionDialog(
            'Swipe bottom-to-top',
            _settingsService.swipeBottomToTop,
            (value) => _settingsService.setSwipeBottomToTop(value),
          ),
        ),
        _buildActionTile(
          title: 'Double tap at left side',
          subtitle: _getActionLabel(_settingsService.doubleTapLeft),
          onTap: () => _showActionDialog(
            'Double tap at left side',
            _settingsService.doubleTapLeft,
            (value) => _settingsService.setDoubleTapLeft(value),
          ),
        ),
        _buildActionTile(
          title: 'Double tap at right side',
          subtitle: _getActionLabel(_settingsService.doubleTapRight),
          onTap: () => _showActionDialog(
            'Double tap at right side',
            _settingsService.doubleTapRight,
            (value) => _settingsService.setDoubleTapRight(value),
          ),
        ),
        _buildActionTile(
          title: 'Double tap at center',
          subtitle: _getActionLabel(_settingsService.doubleTapCenter),
          onTap: () => _showActionDialog(
            'Double tap at center',
            _settingsService.doubleTapCenter,
            (value) => _settingsService.setDoubleTapCenter(value),
          ),
        ),
        _buildActionTile(
          title: 'Scrolling vertically',
          subtitle: _getActionLabel(_settingsService.scrollVertically),
          onTap: () => _showActionDialog(
            'Scrolling vertically',
            _settingsService.scrollVertically,
            (value) => _settingsService.setScrollVertically(value),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              )
            : null,
        value: value,
        activeColor: Colors.orange,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  activeColor: Colors.orange,
                  inactiveColor: Colors.white.withOpacity(0.3),
                  onChanged: onChanged,
                ),
              ),
              Text(
                value.round().toString(),
                style: const TextStyle(color: Colors.orange, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'none':
        return '(none)';
      case 'play_pause':
        return 'Play / Pause';
      case 'next':
        return 'Next track';
      case 'previous':
        return 'Previous track';
      case 'rewind':
        return 'Rewind';
      case 'forward':
        return 'Fast forward';
      case 'volume':
        return 'Adjust volume';
      default:
        return action;
    }
  }
}
