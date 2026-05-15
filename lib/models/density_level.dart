enum DensityLevel {
  green,
  yellow,
  red,
  black;

  String get apiValue => switch (this) {
        DensityLevel.green => 'GREEN',
        DensityLevel.yellow => 'YELLOW',
        DensityLevel.red => 'RED',
        DensityLevel.black => 'BLACK',
      };

  static DensityLevel fromApi(String? value) => switch (value) {
        'GREEN' => DensityLevel.green,
        'YELLOW' => DensityLevel.yellow,
        'RED' => DensityLevel.red,
        'BLACK' => DensityLevel.black,
        _ => DensityLevel.yellow,
      };

  String get labelTr => switch (this) {
        DensityLevel.green => 'Boş',
        DensityLevel.yellow => 'Orta',
        DensityLevel.red => 'Kalabalık',
        DensityLevel.black => 'Dolu',
      };
}

