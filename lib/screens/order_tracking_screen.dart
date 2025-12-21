import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:technex/services/location_store.dart';
import 'package:technex/data/service_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  GoogleMapController? _mapController;
  LatLng? _customerLocation;
  LatLng? _serviceProviderLocation;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;
  ServiceProvider? _serviceProvider;
  
  // Google Maps API Key
  static const String _googleMapsApiKey = 'AIzaSyCOCEy6SmwapTeZ1UPibfcwtlOmqqiA74g';

  @override
  void initState() {
    super.initState();
    _initializeLocations();
  }

  Future<void> _initializeLocations() async {
    try {
      // Get customer location - use LocationStore if available, otherwise fetch fresh
      Position? customerPos = LocationStore.instance.position;
      
      if (customerPos == null) {
        // Fetch location fresh using the same method as main.dart
        final hasPermission = await _checkLocationPermission();
        if (hasPermission) {
          customerPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          // Store it for future use
          LocationStore.instance.setPosition(customerPos);
        }
      }
      
      if (customerPos != null) {
        _customerLocation = LatLng(customerPos.latitude, customerPos.longitude);
      } else {
        // Fallback to Nagpur center if no location available
        _customerLocation = const LatLng(21.1458, 79.0882);
      }

      // Find service provider from CSV data based on order title (service name)
      final services = await ServiceRepository.instance.loadServices();
      ServiceProvider? matchedProvider;
      
      // Try to find exact match by service name
      for (final service in services) {
        if (service.serviceName.toLowerCase().trim() == widget.orderTitle.toLowerCase().trim()) {
          matchedProvider = service;
          break;
        }
      }
      
      // If no exact match, try to find by partial match
      if (matchedProvider == null) {
        for (final service in services) {
          final orderTitleLower = widget.orderTitle.toLowerCase().trim();
          final serviceNameLower = service.serviceName.toLowerCase().trim();
          if (orderTitleLower.contains(serviceNameLower) ||
              serviceNameLower.contains(orderTitleLower)) {
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

      // Get service provider location from area name using geocoding
      if (matchedProvider != null) {
        final areaName = matchedProvider.locationArea.trim();
        
        // Always try geocoding first for accurate location
        try {
          final locations = await geo.locationFromAddress(
            '$areaName, Nagpur, Maharashtra, India',
          );
          if (locations.isNotEmpty) {
            _serviceProviderLocation = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
          } else {
            // Fallback to predefined coordinates if geocoding fails
            _serviceProviderLocation = _nagpurAreaCoordinates[areaName] ?? 
                                     _nagpurAreaCoordinates.values.first;
          }
        } catch (e) {
          // Fallback to predefined coordinates if geocoding fails
          _serviceProviderLocation = _nagpurAreaCoordinates[areaName] ?? 
                                   _nagpurAreaCoordinates.values.first;
        }
      } else {
        // Fallback: use Nagpur center if no provider found
        _serviceProviderLocation = const LatLng(21.1458, 79.0882);
      }

      // Ensure both locations are set before fetching route
      if (_customerLocation != null && _serviceProviderLocation != null) {
        // Fetch route from Google Directions API
        await _fetchRoute();

        // Create markers
        _createMarkers();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading locations: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Check and request location permission (same as main.dart)
  Future<bool> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Fetch route from Google Directions API
  Future<void> _fetchRoute() async {
    if (_customerLocation == null || _serviceProviderLocation == null) return;

    try {
      final origin = '${_customerLocation!.latitude},${_customerLocation!.longitude}';
      final destination = '${_serviceProviderLocation!.latitude},${_serviceProviderLocation!.longitude}';
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$_googleMapsApiKey',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final overviewPolyline = route['overview_polyline'];
          final points = overviewPolyline['points'];
          
          // Decode polyline points
          final decodedPoints = _decodePolyline(points);
          
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: decodedPoints,
                color: Theme.of(context).colorScheme.primary,
                width: 5,
                patterns: [],
              ),
            };
          });
        } else {
          // If API fails, create a simple straight line
          _createFallbackRoute();
        }
      } else {
        // If API fails, create a simple straight line
        _createFallbackRoute();
      }
    } catch (e) {
      // If API fails, create a simple straight line
      _createFallbackRoute();
    }
  }

  /// Decode Google Maps polyline string to list of LatLng
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  /// Create fallback route (straight line) if Directions API fails
  void _createFallbackRoute() {
    if (_customerLocation == null || _serviceProviderLocation == null) return;
    
    final points = <LatLng>[
      _customerLocation!,
      _serviceProviderLocation!,
    ];
    
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Theme.of(context).colorScheme.primary,
          width: 5,
          patterns: [],
        ),
      };
    });
  }

  /// Create markers for customer and service provider locations
  void _createMarkers() {
    if (_customerLocation == null || _serviceProviderLocation == null) return;

    setState(() {
      _markers = {
        // Customer location marker
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Customer location',
          ),
        ),
        // Service provider location marker
        Marker(
          markerId: const MarkerId('service_provider'),
          position: _serviceProviderLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Service Location',
            snippet: _serviceProvider?.locationArea ?? 'Service provider location',
          ),
        ),
      };
    });
  }

  /// Calculate bounds to fit both markers
  LatLngBounds? _getBounds() {
    if (_customerLocation == null || _serviceProviderLocation == null) return null;
    
    return LatLngBounds(
      southwest: LatLng(
        _customerLocation!.latitude < _serviceProviderLocation!.latitude
            ? _customerLocation!.latitude
            : _serviceProviderLocation!.latitude,
        _customerLocation!.longitude < _serviceProviderLocation!.longitude
            ? _customerLocation!.longitude
            : _serviceProviderLocation!.longitude,
      ),
      northeast: LatLng(
        _customerLocation!.latitude > _serviceProviderLocation!.latitude
            ? _customerLocation!.latitude
            : _serviceProviderLocation!.latitude,
        _customerLocation!.longitude > _serviceProviderLocation!.longitude
            ? _customerLocation!.longitude
            : _serviceProviderLocation!.longitude,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _customerLocation == null || _serviceProviderLocation == null) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking your Order'),
      ),
      body: Column(
        children: [
          // Map - takes more than half the screen
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(centerLat, centerLng),
                zoom: 13.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // Fit bounds to show both markers
                final bounds = _getBounds();
                if (bounds != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 100.0),
                  );
                }
              },
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
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
