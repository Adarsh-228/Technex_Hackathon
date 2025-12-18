import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:technex/services/location_store.dart';
import 'package:technex/data/service_repository.dart';
import 'dart:math';

/// Screen that displays a map with route from customer to service provider
class OrderTrackingScreen extends StatefulWidget {
  final String orderTitle;
  final String orderDescription;

  const OrderTrackingScreen({
    super.key,
    required this.orderTitle,
    required this.orderDescription,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

/// Mapping of Nagpur area names to approximate coordinates
final Map<String, LatLng> _nagpurAreaCoordinates = {
  'Dharampeth': const LatLng(21.1520, 79.0880),
  'Manish Nagar': const LatLng(21.1300, 79.1000),
  'Sadar': const LatLng(21.1500, 79.0900),
  'Trimurti Nagar': const LatLng(21.1400, 79.0950),
  'Mankapur': const LatLng(21.1250, 79.1050),
  'Civil Lines': const LatLng(21.1550, 79.0850),
  'Wardhaman Nagar': const LatLng(21.1350, 79.0920),
  'Nandanvan': const LatLng(21.1200, 79.1100),
  'Hingna': const LatLng(21.1100, 79.1150),
  'Bajaj Nagar': const LatLng(21.1450, 79.0870),
  'Ajni': const LatLng(21.1600, 79.0800),
  'Gandhibagh': const LatLng(21.1480, 79.0920),
};

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  LatLng? _customerLocation;
  LatLng? _serviceProviderLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  ServiceProvider? _serviceProvider;

  @override
  void initState() {
    super.initState();
    _initializeLocations();
  }

  Future<void> _initializeLocations() async {
    // Get customer location from LocationStore
    final customerPos = LocationStore.instance.position;
    if (customerPos != null) {
      _customerLocation = LatLng(customerPos.latitude, customerPos.longitude);
    } else {
      // Fallback to Nagpur center if no location available
      _customerLocation = const LatLng(21.1458, 79.0882); // Nagpur coordinates
    }

    // Find service provider from CSV data based on order title (service name)
    final services = await ServiceRepository.instance.loadServices();
    ServiceProvider? matchedProvider;
    
    // Try to find exact match by service name
    for (final service in services) {
      if (service.serviceName.toLowerCase() == widget.orderTitle.toLowerCase()) {
        matchedProvider = service;
        break;
      }
    }
    
    // If no exact match, try to find by partial match
    if (matchedProvider == null) {
      for (final service in services) {
        if (widget.orderTitle.toLowerCase().contains(service.serviceName.toLowerCase()) ||
            service.serviceName.toLowerCase().contains(widget.orderTitle.toLowerCase())) {
          matchedProvider = service;
          break;
        }
      }
    }
    
    // If still no match, use first service provider as fallback
    if (matchedProvider == null && services.isNotEmpty) {
      matchedProvider = services.first;
    }

    _serviceProvider = matchedProvider;

    // Get service provider location from area name
    if (matchedProvider != null) {
      final areaName = matchedProvider.locationArea;
      _serviceProviderLocation = _nagpurAreaCoordinates[areaName] ?? 
                                 _nagpurAreaCoordinates.values.first;
    } else {
      // Fallback: generate location near customer
      final random = Random();
      final offsetLat = (random.nextDouble() - 0.5) * 0.1;
      final offsetLng = (random.nextDouble() - 0.5) * 0.1;
      _serviceProviderLocation = LatLng(
        _customerLocation!.latitude + offsetLat,
        _customerLocation!.longitude + offsetLng,
      );
    }

    // Generate route points (simple straight line with a few waypoints)
    _routePoints = _generateRoutePoints(_customerLocation!, _serviceProviderLocation!);

    setState(() {
      _isLoading = false;
    });
  }

  /// Generate route points between two locations
  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    final points = <LatLng>[start];
    
    // Add intermediate points for a more realistic route
    final numPoints = 5;
    for (int i = 1; i < numPoints; i++) {
      final ratio = i / numPoints;
      // Add slight curve to the route
      final lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final lng = start.longitude + (end.longitude - start.longitude) * ratio;
      // Add small random offset for realism
      final random = Random();
      final offsetLat = (random.nextDouble() - 0.5) * 0.01;
      final offsetLng = (random.nextDouble() - 0.5) * 0.01;
      points.add(LatLng(lat + offsetLat, lng + offsetLng));
    }
    
    points.add(end);
    return points;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tracking your Order'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate center point for map view
    final centerLat = (_customerLocation!.latitude + _serviceProviderLocation!.latitude) / 2;
    final centerLng = (_customerLocation!.longitude + _serviceProviderLocation!.longitude) / 2;
    final center = LatLng(centerLat, centerLng);

    // Calculate zoom level to fit both points
    final distance = Geolocator.distanceBetween(
      _customerLocation!.latitude,
      _customerLocation!.longitude,
      _serviceProviderLocation!.latitude,
      _serviceProviderLocation!.longitude,
    );
    final zoom = distance > 10000 ? 12.0 : (distance > 5000 ? 13.0 : 14.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking your Order'),
      ),
      body: Column(
        children: [
          // Map - takes more than half the screen
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: 10,
                maxZoom: 18,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.technex',
                ),
                // Route polyline
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                // Markers
                MarkerLayer(
                  markers: [
                    // Customer location marker
                    Marker(
                      point: _customerLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    // Service provider location marker
                    Marker(
                      point: _serviceProviderLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Service Provider Details Card
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                child: _serviceProvider != null
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service Provider Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                'Provider Name',
                                _serviceProvider!.providerName,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Service Name',
                                _serviceProvider!.serviceName,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Location',
                                _serviceProvider!.locationArea,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Service Radius',
                                '${_serviceProvider!.serviceRadiusKm} km',
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Experience',
                                '${_serviceProvider!.experienceYears} years',
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Status',
                                'Pending',
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Payment feature coming soon!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.payment, size: 20),
                                  label: const Text('Make Payment'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service Provider Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Service: ${widget.orderTitle}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Provider details not available',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Status',
                                'Pending',
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Payment feature coming soon!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.payment, size: 20),
                                  label: const Text('Make Payment'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

