import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:technex/data/local_db.dart';
import 'package:technex/services/location_store.dart';
import 'package:technex/screens/customer_survey_screen.dart';
import 'package:technex/main.dart' show RoleSelectionScreen;

/// Customer login / profile screen with minimal card layout.
class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill location immediately from LocationStore (synchronous, no async needed)
    final formatted = LocationStore.instance.formattedLocation;
    if (formatted != null && formatted.isNotEmpty) {
      _locationController.text = formatted;
    }
    // Show UI immediately, load profile data in background
    _isLoading = false;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Load profile data in background (non-blocking)
    final db = LocalDb.instance;
    final existing = await db.getCustomerProfile();

    if (!mounted) return;

    if (existing != null) {
      // Update fields with saved profile data
      setState(() {
        _nameController.text = (existing['name'] ?? '') as String;
        _emailController.text = (existing['email'] ?? '') as String;
        _phoneController.text = (existing['phone'] ?? '') as String;
        // Only update location if it's not already filled from LocationStore
        if (_locationController.text.isEmpty) {
          _locationController.text = (existing['location'] ?? '') as String;
        }
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isFetchingLocation) return;

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          setState(() {
            _isFetchingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied')),
          );
        }
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get place name from coordinates
      String? placeName;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          if (place.locality != null && place.locality!.isNotEmpty) {
            placeName = place.locality;
            if (place.subAdministrativeArea != null && 
                place.subAdministrativeArea!.isNotEmpty &&
                place.subAdministrativeArea != place.locality) {
              placeName = '${place.subAdministrativeArea}, $placeName';
            } else if (place.administrativeArea != null && 
                       place.administrativeArea!.isNotEmpty &&
                       place.administrativeArea != place.locality) {
              placeName = '${place.administrativeArea}, $placeName';
            }
          } else if (place.subAdministrativeArea != null && 
                     place.subAdministrativeArea!.isNotEmpty) {
            placeName = place.subAdministrativeArea;
          } else if (place.administrativeArea != null && 
                     place.administrativeArea!.isNotEmpty) {
            placeName = place.administrativeArea;
          }
        }
      } catch (e) {
        // If reverse geocoding fails, we'll just use coordinates
      }

      // Update LocationStore
      LocationStore.instance.setPosition(position, placeName: placeName);

      // Update text field
      if (mounted && placeName != null && placeName.isNotEmpty) {
        setState(() {
          _locationController.text = placeName!;
        });
      } else if (mounted) {
        setState(() {
          _locationController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final db = LocalDb.instance;

    await db.upsertCustomerProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    // Move to the survey after persisting profile information.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const CustomerSurveyScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Login'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to initial login page (RoleSelectionScreen)
            // Check if location is available from LocationStore
            final hasLocation = LocationStore.instance.position != null;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => RoleSelectionScreen(hasLocation: hasLocation),
              ),
              (route) => false,
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Customer Login',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Enter your name',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'Enter your email',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!text.contains('@') || !text.contains('.')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Phone No.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                hintText: 'Enter your phone number',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (value.trim().length < 8) {
                                  return 'Phone number looks too short';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _locationController,
                                    decoration: const InputDecoration(
                                      hintText: 'Area / City',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                                  icon: _isFetchingLocation
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.my_location),
                                  tooltip: 'Get current location',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


