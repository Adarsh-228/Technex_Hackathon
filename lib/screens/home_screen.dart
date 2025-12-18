import 'package:flutter/material.dart';
import 'package:technex/screens/customer_profile_screen.dart';
import 'package:technex/screens/chatbot_screen.dart';
import 'package:technex/data/service_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final int _pageSize = 8;

  List<ServiceProvider> _allServices = const [];
  List<ServiceProvider> _filteredServices = const [];
  int _visibleCount = 8;
  bool _loading = true;
  int _selectedIndex = 0; // 0: Services, 1: Orders, 2: Chatbot

  @override
  void initState() {
    super.initState();
    _loadServices();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _loadServices() async {
    final services = await ServiceRepository.instance.loadServices();
    if (!mounted) return;
    setState(() {
      _allServices = services;
      _filteredServices = services;
      _visibleCount = _pageSize.clamp(0, services.length);
      _loading = false;
    });
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    List<ServiceProvider> base = _allServices;
    if (query.isNotEmpty) {
      base = _allServices.where((s) {
        return s.serviceName.toLowerCase().contains(query) ||
            s.providerName.toLowerCase().contains(query) ||
            s.serviceCategory.toLowerCase().contains(query) ||
            s.primarySkill.toLowerCase().contains(query) ||
            s.locationArea.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredServices = base;
      _visibleCount = _pageSize.clamp(0, base.length);
    });
  }

  void _loadMore() {
    setState(() {
      _visibleCount =
          (_visibleCount + _pageSize).clamp(0, _filteredServices.length);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services for You'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CustomerProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services for You',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search services',
                            prefixIcon:
                                const Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _visibleCount,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final service = _filteredServices[index];
                              return _ServiceRow(
                                service: service,
                                theme: theme,
                              );
                            },
                          ),
                        ),
                        if (_visibleCount < _filteredServices.length)
                          SizedBox(
                            height: 44,
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _loadMore,
                              child: const Text('Show more'),
                            ),
                          ),
                      ],
                    ),
            )
          : _selectedIndex == 1
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Your orders will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : const ChatbotScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Your Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chatbot',
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatefulWidget {
  const _ServiceRow({
    required this.service,
    required this.theme,
  });

  final ServiceProvider service;
  final ThemeData theme;

  @override
  State<_ServiceRow> createState() => _ServiceRowState();
}

class _ServiceRowState extends State<_ServiceRow> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  void _bookService() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final TextEditingController problemController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Book Service'),
          content: TextField(
            controller: problemController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'What are your requirements?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Use problemController.text and service details
                // to create a booking when backend is ready.
                Navigator.of(ctx).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final colorScheme = theme.colorScheme;
    final service = widget.service;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _toggleExpanded,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface.withOpacity(0.9),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.onSurface.withOpacity(0.08),
                ),
                child: Icon(
                  Icons.home_repair_service_rounded,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.serviceName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.serviceCategory,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: colorScheme.primary.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${service.providerName} • ${service.locationArea}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.primarySkill,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Experience: ${service.experienceYears} years • Radius: ${service.serviceRadiusKm} km',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Availability: ${service.availabilityStatus} • Emergency: ${service.emergencySupport}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _bookService,
                          child: const Text('Book Service'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


