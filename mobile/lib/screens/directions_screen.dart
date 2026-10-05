import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_info.dart';
import '../providers/directions_provider.dart';
import '../providers/place_provider.dart';
import '../services/directions_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

/// Shows the route from the user's current location to [destinationAddress]
/// on a map, with distance/time chips for car, walking, bicycle, scooter,
/// bus and metro (see [RouteInfo] for how scooter/bus/metro are derived,
/// since Google Directions has no scooter mode and doesn't split transit).
class DirectionsScreen extends ConsumerStatefulWidget {
  const DirectionsScreen({
    super.key,
    required this.destinationName,
    required this.destinationAddress,
  });

  final String destinationName;
  final String destinationAddress;

  @override
  ConsumerState<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends ConsumerState<DirectionsScreen> {
  GoogleMapController? _mapController;
  bool _loading = true;
  String? _error;
  LatLng? _origin;
  LatLng? _destination;
  Map<TransportMode, RouteInfo> _routes = {};
  TransportMode? _selectedMode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      if (position == null) {
        throw const LocationUnavailableException();
      }
      final origin = LatLng(position.latitude, position.longitude);

      final service = ref.read(directionsServiceProvider);
      final destination = await service.geocodeAddress(widget.destinationAddress);
      final routes = await service.fetchAllRoutes(origin: origin, destination: destination);

      setState(() {
        _origin = origin;
        _destination = destination;
        _routes = routes;
        _selectedMode = routes.keys.first;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    } on LocationUnavailableException {
      setState(() {
        _loading = false;
        _error = "Joylashuvni aniqlab bo'lmadi. Lokatsiyaga ruxsat berilganini tekshiring.";
      });
    } on DirectionsException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = "Yo'nalishni yuklab bo'lmadi. Qayta urinib ko'ring.";
      });
    }
  }

  void _fitBounds() {
    final origin = _origin;
    final destination = _destination;
    final controller = _mapController;
    if (controller == null || origin == null || destination == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude ? origin.latitude : destination.latitude,
        origin.longitude < destination.longitude ? origin.longitude : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude ? origin.latitude : destination.latitude,
        origin.longitude > destination.longitude ? origin.longitude : destination.longitude,
      ),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: AppColors.darkText(context)),
        ),
        title: Text(
          widget.destinationName,
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkText(context), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                child: const Text("Qayta urinish", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final origin = _origin!;
    final destination = _destination!;
    final selectedRoute = _routes[_selectedMode];

    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: origin, zoom: 13),
            markers: {
              Marker(
                markerId: const MarkerId('destination'),
                position: destination,
                infoWindow: InfoWindow(title: widget.destinationName),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ),
            },
            polylines: {
              if (selectedRoute != null)
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: selectedRoute.points,
                  color: AppColors.orange,
                  width: 4,
                ),
            },
            // The user's own position is shown with Google's native blue
            // "my location" dot instead of a generic pin, so it's visually
            // distinct from the orange destination marker above.
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds();
            },
          ),
        ),
        _buildModeSelector(context),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    final modes = TransportMode.values.where(_routes.containsKey).toList();
    final selectedRoute = _routes[_selectedMode];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedRoute != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${selectedRoute.distanceKm.toStringAsFixed(1)} km • ${selectedRoute.durationMinutes} daqiqa',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.darkText(context),
                ),
              ),
            ),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: modes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final mode = modes[index];
                final isSelected = mode == _selectedMode;
                final info = _routes[mode]!;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMode = mode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.orange : AppColors.cream(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.orange : AppColors.fieldBorder(context),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _iconFor(mode),
                              size: 16,
                              color: isSelected ? Colors.white : AppColors.darkText(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _labelFor(mode),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.darkText(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${info.durationMinutes} daq',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(TransportMode mode) {
    switch (mode) {
      case TransportMode.car:
        return 'Avtomobil';
      case TransportMode.walking:
        return 'Piyoda';
      case TransportMode.bicycle:
        return 'Velosiped';
      case TransportMode.scooter:
        return 'Skuter';
      case TransportMode.bus:
        return 'Avtobus';
      case TransportMode.metro:
        return 'Metro';
    }
  }

  IconData _iconFor(TransportMode mode) {
    switch (mode) {
      case TransportMode.car:
        return Icons.directions_car_filled;
      case TransportMode.walking:
        return Icons.directions_walk;
      case TransportMode.bicycle:
        return Icons.directions_bike;
      case TransportMode.scooter:
        return Icons.electric_scooter;
      case TransportMode.bus:
        return Icons.directions_bus;
      case TransportMode.metro:
        return Icons.directions_subway;
    }
  }
}
