class EqualizerPreset {
  final String name;
  final Map<int, double> bands; // frequency -> gain (-12 to +12 dB)

  const EqualizerPreset({required this.name, required this.bands});

  // Preset modes
  static const flat = EqualizerPreset(
    name: 'Flat',
    bands: {
      32: 0.0,
      64: 0.0,
      125: 0.0,
      250: 0.0,
      500: 0.0,
      1000: 0.0,
      2000: 0.0,
      4000: 0.0,
      8000: 0.0,
      16000: 0.0,
    },
  );

  static const rock = EqualizerPreset(
    name: 'Rock',
    bands: {
      32: 8.0,
      64: 5.0,
      125: -5.0,
      250: -8.0,
      500: -3.0,
      1000: 4.0,
      2000: 8.0,
      4000: 11.0,
      8000: 11.0,
      16000: 11.0,
    },
  );

  static const pop = EqualizerPreset(
    name: 'Pop',
    bands: {
      32: -1.5,
      64: 4.5,
      125: 7.5,
      250: 8.0,
      500: 5.5,
      1000: 0.0,
      2000: -2.0,
      4000: -2.0,
      8000: -1.5,
      16000: -1.5,
    },
  );

  static const jazz = EqualizerPreset(
    name: 'Jazz',
    bands: {
      32: 0.0,
      64: 0.0,
      125: 0.0,
      250: 4.0,
      500: 4.0,
      1000: 4.0,
      2000: 0.0,
      4000: 2.0,
      8000: 4.0,
      16000: 6.0,
    },
  );

  static const classical = EqualizerPreset(
    name: 'Classical',
    bands: {
      32: 0.0,
      64: 0.0,
      125: 0.0,
      250: 0.0,
      500: 0.0,
      1000: 0.0,
      2000: -7.0,
      4000: -7.0,
      8000: -7.0,
      16000: -9.0,
    },
  );

  static const dance = EqualizerPreset(
    name: 'Dance',
    bands: {
      32: 9.5,
      64: 7.0,
      125: 2.0,
      250: 0.0,
      500: 0.0,
      1000: -5.5,
      2000: -7.5,
      4000: -7.5,
      8000: 0.0,
      16000: 0.0,
    },
  );

  static const electronic = EqualizerPreset(
    name: 'Electronic',
    bands: {
      32: 8.0,
      64: 8.0,
      125: 1.0,
      250: -5.0,
      500: -5.0,
      1000: 0.0,
      2000: 4.0,
      4000: 8.0,
      8000: 9.0,
      16000: 9.0,
    },
  );

  static const hiphop = EqualizerPreset(
    name: 'Hip-Hop',
    bands: {
      32: 8.5,
      64: 8.0,
      125: 1.5,
      250: 3.0,
      500: -1.5,
      1000: -1.5,
      2000: 2.0,
      4000: -1.0,
      8000: 2.0,
      16000: 3.0,
    },
  );

  static const metal = EqualizerPreset(
    name: 'Metal',
    bands: {
      32: 8.0,
      64: 8.0,
      125: 8.0,
      250: 0.0,
      500: 4.0,
      1000: 5.0,
      2000: 0.0,
      4000: 8.0,
      8000: 10.0,
      16000: 11.0,
    },
  );

  static const latin = EqualizerPreset(
    name: 'Latin',
    bands: {
      32: 0.0,
      64: 0.0,
      125: 0.0,
      250: 0.0,
      500: -1.5,
      1000: -1.5,
      2000: -1.5,
      4000: 0.0,
      8000: 7.5,
      16000: 11.5,
    },
  );

  static const acoustic = EqualizerPreset(
    name: 'Acoustic',
    bands: {
      32: 5.5,
      64: 4.5,
      125: 4.0,
      250: 1.0,
      500: 2.5,
      1000: 1.5,
      2000: 4.0,
      4000: 5.0,
      8000: 3.5,
      16000: 1.5,
    },
  );

  static const lounge = EqualizerPreset(
    name: 'Lounge',
    bands: {
      32: -3.0,
      64: 1.5,
      125: 5.5,
      250: 1.5,
      500: -1.5,
      1000: -1.5,
      2000: 0.0,
      4000: 2.5,
      8000: 1.0,
      16000: 0.0,
    },
  );

  static const piano = EqualizerPreset(
    name: 'Piano',
    bands: {
      32: 0.0,
      64: 2.5,
      125: 0.0,
      250: 2.5,
      500: 3.5,
      1000: 1.5,
      2000: 3.5,
      4000: 4.5,
      8000: 3.0,
      16000: 4.0,
    },
  );

  static const rNb = EqualizerPreset(
    name: 'R&B',
    bands: {
      32: 10.0,
      64: 7.5,
      125: 5.5,
      250: 1.5,
      500: -2.5,
      1000: -1.5,
      2000: 3.0,
      4000: 3.0,
      8000: 3.5,
      16000: 4.0,
    },
  );

  static const vocal = EqualizerPreset(
    name: 'Vocal',
    bands: {
      32: -1.5,
      64: -3.0,
      125: -3.0,
      250: 1.5,
      500: 4.0,
      1000: 4.0,
      2000: 4.0,
      4000: 3.0,
      8000: 1.5,
      16000: 0.0,
    },
  );

  static const bassBooster = EqualizerPreset(
    name: 'Bass Booster',
    bands: {
      32: 10.0,
      64: 8.0,
      125: 6.0,
      250: 4.0,
      500: 2.0,
      1000: 0.0,
      2000: 0.0,
      4000: 0.0,
      8000: 0.0,
      16000: 0.0,
    },
  );

  static const trebleBooster = EqualizerPreset(
    name: 'Treble Booster',
    bands: {
      32: 0.0,
      64: 0.0,
      125: 0.0,
      250: 0.0,
      500: 0.0,
      1000: 2.0,
      2000: 4.0,
      4000: 6.0,
      8000: 8.0,
      16000: 10.0,
    },
  );

  static const vocalBooster = EqualizerPreset(
    name: 'Vocal Booster',
    bands: {
      32: -3.0,
      64: -2.0,
      125: 2.0,
      250: 4.0,
      500: 6.0,
      1000: 6.0,
      2000: 5.0,
      4000: 3.0,
      8000: 0.0,
      16000: -2.0,
    },
  );

  static const deepBass = EqualizerPreset(
    name: 'Deep Bass',
    bands: {
      32: 12.0,
      64: 10.0,
      125: 8.0,
      250: 5.0,
      500: 2.0,
      1000: 0.0,
      2000: -2.0,
      4000: -3.0,
      8000: -4.0,
      16000: -5.0,
    },
  );

  static const live = EqualizerPreset(
    name: 'Live',
    bands: {
      32: -4.5,
      64: 0.0,
      125: 4.0,
      250: 5.5,
      500: 5.5,
      1000: 5.5,
      2000: 4.0,
      4000: 2.5,
      8000: 2.5,
      16000: 2.5,
    },
  );

  static const party = EqualizerPreset(
    name: 'Party',
    bands: {
      32: 7.0,
      64: 7.0,
      125: 0.0,
      250: 0.0,
      500: 0.0,
      1000: 0.0,
      2000: 0.0,
      4000: 0.0,
      8000: 7.0,
      16000: 7.0,
    },
  );

  static const allPresets = [
    flat,
    rock,
    pop,
    jazz,
    classical,
    dance,
    electronic,
    hiphop,
    metal,
    latin,
    acoustic,
    lounge,
    piano,
    rNb,
    vocal,
    bassBooster,
    trebleBooster,
    vocalBooster,
    deepBass,
    live,
    party,
  ];
}
