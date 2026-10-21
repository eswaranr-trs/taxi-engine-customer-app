class TerminalModel {
  final String id;
  final String name;
  final double lat;
  final double lng;

  TerminalModel({required this.id, required this.name, required this.lat, required this.lng});

  bool get hasCoords => !(lat == 0 && lng == 0);

  TerminalModel copyWith({double? lat, double? lng}) =>
      TerminalModel(id: id, name: name, lat: lat ?? this.lat, lng: lng ?? this.lng);
}

class AirportModel {
  final String id;
  final String name;
  final String city;
  final double lat;
  final double lng;
  final List<TerminalModel> terminals;

  AirportModel({
    required this.id,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
    required this.terminals,
  });

  bool get hasCoords => !(lat == 0 && lng == 0);

  static List<AirportModel> forCities(List<String> cities) {
    final seen = <String>{};
    final list = <AirportModel>[];

    for (final raw in cities) {
      final city = raw.trim();
      if (city.isEmpty) continue;
      if (!seen.add(city.toLowerCase())) continue;
      list.add(forCity(city));
    }
    return list;
  }

  static AirportModel forCity(String city) {
    final String name = city.trim();
    final String key = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return AirportModel(
      id: 'city-$key',
      name: '$name Airport',
      city: name,
      lat: 0,
      lng: 0,
      terminals: [TerminalModel(id: '$key-main', name: 'Main Terminal', lat: 0, lng: 0)],
    );
  }
}
