import 'package:flutter/material.dart';
import '../models/equalizer_preset.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  EqualizerPreset _currentPreset = EqualizerPreset.flat;
  Map<int, double> _customBands = Map.from(EqualizerPreset.flat.bands);
  bool _isEnabled = true;

  final List<int> _frequencies = [
    32,
    64,
    125,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000,
  ];

  void _applyPreset(EqualizerPreset preset) {
    setState(() {
      _currentPreset = preset;
      _customBands = Map.from(preset.bands);
    });
  }

  void _updateBand(int frequency, double value) {
    setState(() {
      _customBands[frequency] = value;
      // Check if matches any preset
      bool matchesPreset = false;
      for (var preset in EqualizerPreset.allPresets) {
        if (_bandsEqual(preset.bands, _customBands)) {
          _currentPreset = preset;
          matchesPreset = true;
          break;
        }
      }
      if (!matchesPreset) {
        _currentPreset = EqualizerPreset(name: 'Custom', bands: _customBands);
      }
    });
  }

  bool _bandsEqual(Map<int, double> a, Map<int, double> b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if ((a[key]! - b[key]!).abs() > 0.1) return false;
    }
    return true;
  }

  String _formatFrequency(int freq) {
    if (freq >= 1000) {
      return '${(freq / 1000).toStringAsFixed(freq % 1000 == 0 ? 0 : 1)}k';
    }
    return freq.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text(
          'Equalizer',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2a2a2a),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Switch(
            value: _isEnabled,
            onChanged: (value) {
              setState(() => _isEnabled = value);
            },
            activeColor: Colors.orange,
            activeTrackColor: Colors.orange.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Current Preset Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.3),
                  Colors.orange.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  _currentPreset.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Equalizer Bands
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _frequencies.map((freq) {
                        final value = _customBands[freq] ?? 0.0;
                        return Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 16,
                                          ),
                                      activeTrackColor: Colors.orange,
                                      inactiveTrackColor: Colors.white
                                          .withOpacity(0.2),
                                      thumbColor: Colors.orange,
                                      overlayColor: Colors.orange.withOpacity(
                                        0.2,
                                      ),
                                      disabledThumbColor: Colors.grey,
                                      disabledActiveTrackColor: Colors.grey,
                                      disabledInactiveTrackColor: Colors.grey
                                          .withOpacity(0.2),
                                    ),
                                    child: Slider(
                                      value: value,
                                      min: -12,
                                      max: 12,
                                      onChanged: _isEnabled
                                          ? (newValue) =>
                                                _updateBand(freq, newValue)
                                          : null,
                                      activeColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      inactiveColor: Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: value.abs() > 0.1
                                      ? Colors.orange
                                      : Colors.white.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatFrequency(freq),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '-12 dB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '+12 dB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Reset Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _applyPreset(EqualizerPreset.flat),
                icon: const Icon(
                  Icons.restart_alt_rounded,
                  color: Colors.orange,
                ),
                label: const Text(
                  'Reset to Flat',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                ),
              ),
            ),
          ),

          // Presets
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Presets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: EqualizerPreset.allPresets.length,
              itemBuilder: (context, index) {
                final preset = EqualizerPreset.allPresets[index];
                final isSelected = preset.name == _currentPreset.name;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  color: isSelected
                      ? Colors.orange.withOpacity(0.2)
                      : const Color(0xFF2a2a2a),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPresetIcon(preset.name),
                        color: isSelected ? Colors.white : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      preset.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected ? Colors.orange : Colors.white,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.orange,
                          )
                        : Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(0.5),
                          ),
                    onTap: () => _applyPreset(preset),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPresetIcon(String presetName) {
    switch (presetName) {
      case 'Flat':
        return Icons.horizontal_rule_rounded;
      case 'Rock':
        return Icons.music_note_rounded;
      case 'Pop':
        return Icons.star_rounded;
      case 'Jazz':
        return Icons.piano_rounded;
      case 'Classical':
        return Icons.library_music_rounded;
      case 'Dance':
        return Icons.nightlife_rounded;
      case 'Electronic':
        return Icons.electrical_services_rounded;
      case 'Hip-Hop':
        return Icons.mic_rounded;
      case 'Metal':
        return Icons.thunderstorm_rounded;
      case 'Latin':
        return Icons.emoji_flags_rounded;
      case 'Acoustic':
        return Icons.music_note_rounded;
      case 'Lounge':
        return Icons.weekend_rounded;
      case 'Piano':
        return Icons.piano_rounded;
      case 'R&B':
        return Icons.favorite_rounded;
      case 'Vocal':
        return Icons.record_voice_over_rounded;
      case 'Bass Booster':
        return Icons.graphic_eq_rounded;
      case 'Treble Booster':
        return Icons.trending_up_rounded;
      case 'Vocal Booster':
        return Icons.surround_sound_rounded;
      case 'Deep Bass':
        return Icons.waterfall_chart_rounded;
      case 'Live':
        return Icons.live_tv_rounded;
      case 'Party':
        return Icons.celebration_rounded;
      default:
        return Icons.equalizer_rounded;
    }
  }
}
