import 'package:flutter/material.dart';
import 'package:technex/data/local_db.dart';

/// Service provider profile + current orders screen.
class ServiceProviderProfileScreen extends StatefulWidget {
  const ServiceProviderProfileScreen({super.key});

  @override
  State<ServiceProviderProfileScreen> createState() =>
      _ServiceProviderProfileScreenState();
}

class _ServiceProviderProfileScreenState
    extends State<ServiceProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _serviceCategoryController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _photoController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoadingProfile = true;
  bool _isSaving = false;
  List<Map<String, Object?>> _orders = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingProfile = true;
    });

    final db = LocalDb.instance;
    final profile = await db.getServiceProviderProfile();
    final orders = await db.getCurrentOrders();

    if (profile != null) {
      _fullNameController.text = (profile['full_name'] ?? '') as String;
      _mobileController.text = (profile['mobile'] ?? '') as String;
      _serviceCategoryController.text =
          (profile['service_category'] ?? '') as String;
      _yearsExperienceController.text =
          (profile['years_experience'] ?? '').toString();
      _photoController.text = (profile['photo'] ?? '') as String;
      _locationController.text = (profile['location'] ?? '') as String;
    }

    setState(() {
      _orders = orders;
      _isLoadingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final db = LocalDb.instance;

    final years = int.tryParse(_yearsExperienceController.text.trim()) ?? 0;

    await db.upsertServiceProviderProfile(
      fullName: _fullNameController.text.trim(),
      mobile: _mobileController.text.trim(),
      serviceCategory: _serviceCategoryController.text.trim(),
      yearsExperience: years,
      photo: _photoController.text.trim().isEmpty
          ? null
          : _photoController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved locally.'),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _serviceCategoryController.dispose();
    _yearsExperienceController.dispose();
    _photoController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Service Provider'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profile'),
              Tab(text: 'Orders'),
            ],
          ),
        ),
        body: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildProfileTab(context),
                  _buildOrdersTab(context),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mobile No.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your mobile number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (value.trim().length < 8) {
                          return 'Mobile number looks too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Service Category',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _serviceCategoryController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Electrician, Plumber, Cleaner',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter service category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Years of Experience',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _yearsExperienceController,
                      decoration: const InputDecoration(
                        hintText: 'Enter total years of experience',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter years of experience';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Photo (optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _photoController,
                      decoration: const InputDecoration(
                        hintText: 'URL or file reference (placeholder for now)',
                      ),
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
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'Area / City',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(BuildContext context) {
    if (_orders.isEmpty) {
      return const Center(
        child: Text('No current orders.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final title = (order['title'] ?? '') as String;
        final status = (order['status'] ?? '') as String;
        final createdAt = (order['created_at'] ?? '') as String;

        return Card(
          child: ListTile(
            title: Text(title),
            subtitle: Text('Status: $status\nCreated: $createdAt'),
          ),
        );
      },
    );
  }
}


