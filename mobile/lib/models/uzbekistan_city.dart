import 'package:google_maps_flutter/google_maps_flutter.dart';

class UzbekistanCity {
  const UzbekistanCity({required this.name, required this.center});

  final String name;
  final LatLng center;
}

const uzbekistanCities = [
  UzbekistanCity(name: 'Tashkent, Uzbekistan', center: LatLng(41.311081, 69.240562)),
  UzbekistanCity(name: 'Samarkand, Uzbekistan', center: LatLng(39.627012, 66.975463)),
  UzbekistanCity(name: 'Bukhara, Uzbekistan', center: LatLng(39.768478, 64.421903)),
  UzbekistanCity(name: 'Andijan, Uzbekistan', center: LatLng(40.783058, 72.344329)),
  UzbekistanCity(name: 'Namangan, Uzbekistan', center: LatLng(40.998168, 71.673295)),
  UzbekistanCity(name: 'Fergana, Uzbekistan', center: LatLng(40.389104, 71.783405)),
  UzbekistanCity(name: 'Nukus, Uzbekistan', center: LatLng(42.460564, 59.601543)),
  UzbekistanCity(name: 'Termez, Uzbekistan', center: LatLng(37.224655, 67.278152)),
  UzbekistanCity(name: 'Urgench, Uzbekistan', center: LatLng(41.550314, 60.631029)),
  UzbekistanCity(name: 'Qarshi, Uzbekistan', center: LatLng(38.860161, 65.789537)),
];
