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
  List<Map<String, String>> _feedback = [];

  @override
  void initState() {
    super.initState();
    _initializeFeedbacks();
    _loadData();
  }

  void _initializeFeedbacks() {
    final now = DateTime.now();
    _feedback = [
      {
        'feedback_text': 'Great service! The technician arrived on time and fixed the issue quickly. Highly recommended!',
        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'feedback_text': 'Excellent work quality. Very professional and courteous. Will definitely use this service again.',
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'feedback_text': 'The service provider was knowledgeable and explained everything clearly. Very satisfied with the work.',
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'feedback_text': 'Quick response time and reasonable pricing. The job was completed efficiently. Thank you!',
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'feedback_text': 'Outstanding service! The technician was friendly and did a thorough job. Worth every penny.',
        'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
      },
      {
        'feedback_text': 'Good experience overall. The service was prompt and the quality of work was excellent.',
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'feedback_text': 'Professional service with attention to detail. The technician was well-equipped and skilled.',
        'created_at': now.subtract(const Duration(days: 6)).toIso8601String(),
      },
      {
        'feedback_text': 'Very happy with the service. The provider was punctual, clean, and completed the work perfectly.',
        'created_at': now.subtract(const Duration(days: 7)).toIso8601String(),
      },
      {
        'feedback_text': 'Amazing service! The problem was diagnosed correctly and fixed in no time. Great value for money.',
        'created_at': now.subtract(const Duration(days: 8)).toIso8601String(),
      },
      {
        'feedback_text': 'The technician was very skilled and completed the work with precision. Highly satisfied!',
        'created_at': now.subtract(const Duration(days: 9)).toIso8601String(),
      },
      {
        'feedback_text': 'Prompt service and excellent communication. The provider kept me informed throughout the process.',
        'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'feedback_text': 'Top-notch quality work. The service exceeded my expectations. Will recommend to friends and family.',
        'created_at': now.subtract(const Duration(days: 11)).toIso8601String(),
      },
      {
        'feedback_text': 'Very reliable and trustworthy service provider. The work was done perfectly the first time.',
        'created_at': now.subtract(const Duration(days: 12)).toIso8601String(),
      },
      {
        'feedback_text': 'Great customer service and professional approach. The technician was respectful and efficient.',
        'created_at': now.subtract(const Duration(days: 13)).toIso8601String(),
      },
      {
        'feedback_text': 'Excellent value for money. The service was quick, efficient, and the quality was outstanding.',
        'created_at': now.subtract(const Duration(days: 14)).toIso8601String(),
      },
    ];
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
              Tab(text: 'Admin Panel'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadData(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildProfileTab(context),
                  _buildAdminPanelTab(context),
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

  Widget _buildAdminPanelTab(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Feedback'),
            ],
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrdersTab(context),
                _buildFeedbackTab(context),
              ],
            ),
          ),
        ],
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

  Widget _buildFeedbackTab(BuildContext context) {
    return Column(
      children: [
        // Header with feedback count
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.feedback_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Customer Feedback (${_feedback.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Feedback list
        Expanded(
          child: _feedback.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No feedback received yet.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _feedback.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final feedback = _feedback[index];
                    final feedbackText = feedback['feedback_text'] ?? '';
                    final createdAt = feedback['created_at'] ?? '';

                    // Format the date for better display
                    String formattedDate = createdAt;
                    try {
                      final date = DateTime.parse(createdAt);
                      final now = DateTime.now();
                      final difference = now.difference(date);
                      
                      if (difference.inDays == 0) {
                        if (difference.inHours == 0) {
                          formattedDate = '${difference.inMinutes} minutes ago';
                        } else {
                          formattedDate = '${difference.inHours} hours ago';
                        }
                      } else if (difference.inDays == 1) {
                        formattedDate = 'Yesterday';
                      } else if (difference.inDays < 7) {
                        formattedDate = '${difference.inDays} days ago';
                      } else {
                        formattedDate = '${date.day}/${date.month}/${date.year}';
                      }
                    } catch (e) {
                      // Keep original format if parsing fails
                    }

                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.rate_review,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    formattedDate,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              feedbackText,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                                fontSize: 15,
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
    );
  }
}


