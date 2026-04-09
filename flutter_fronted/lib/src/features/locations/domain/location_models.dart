class CountryItem {
  const CountryItem({required this.code, required this.name});

  final String code;
  final String name;
}

class RegionItem {
  const RegionItem({
    required this.code,
    required this.name,
    required this.countryCode,
  });

  final String code;
  final String name;
  final String countryCode;
}

class CityItem {
  const CityItem({
    required this.code,
    required this.name,
    required this.countryCode,
    required this.regionCode,
  });

  final String code;
  final String name;
  final String countryCode;
  final String regionCode;
}
