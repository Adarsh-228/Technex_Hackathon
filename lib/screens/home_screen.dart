import 'dart:math';
import 'package:flutter/material.dart';
import 'package:technex/screens/customer_profile_screen.dart';
import 'package:technex/screens/chatbot_screen.dart';
import 'package:technex/screens/order_tracking_screen.dart';
import 'package:technex/data/service_repository.dart';
import 'package:technex/data/local_db.dart';

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
  List<Map<String, Object?>> _orders = const [];
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

  Future<void> _loadOrders() async {
    final db = LocalDb.instance;
    final orders = await db.getCurrentOrders();
    if (!mounted) return;
    setState(() {
      _orders = orders;
    });
  }

  Future<void> _deleteOrder(BuildContext context, int orderId, String orderTitle) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete "$orderTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = LocalDb.instance;
      await db.deleteOrder(orderId);
      if (!mounted) return;
      
      // Refresh orders list
      await _loadOrders();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order "$orderTitle" deleted'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static _HomeScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomeScreenState>();
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
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: _orders.isEmpty
                      ? const Center(
                          child: Text(
                            'No orders yet.\nBook a service to see it here.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final orderId = (order['id'] as int?) ?? 0;
                            final title =
                                (order['title'] ?? '') as String;
                            final status =
                                (order['status'] ?? '') as String;
                            final createdAt =
                                (order['created_at'] ?? '') as String;
                            final description =
                                (order['description'] ?? '') as String;

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.9),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Status: $status',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontSize: 13,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.9),
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  createdAt,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _deleteOrder(
                                                context, orderId, title),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              size: 20,
                                            ),
                                            tooltip: 'Delete order',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      if (description.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 13,
                                                color:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(
                                                            0.85),
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) => OrderTrackingScreen(
                                                  orderTitle: title,
                                                  orderDescription: description,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.location_on, size: 18),
                                          label: const Text('Track your Order'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                )
              : const ChatbotScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            _loadOrders();
          }
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

  /// Generate random cost between 100-900, rounded to nearest hundred
  int _generateRandomCost() {
    final random = Random();
    // Generate random number between 100-900
    final baseCost = 100 + random.nextInt(801); // 100 to 900
    // Round to nearest hundred
    return ((baseCost / 100).round() * 100);
  }

  void _bookService() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final TextEditingController requirementsController =
            TextEditingController();
        bool isBooking = false;
        int? serviceCost;
        bool showCost = false;
        
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Book Service'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service: ${widget.service.serviceName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (showCost && serviceCost != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Cost:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹$serviceCost',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: requirementsController,
                    maxLines: 3,
                    enabled: !isBooking,
                    decoration: const InputDecoration(
                      hintText: 'What are your requirements?',
                      labelText: 'Requirements',
                    ),
                  ),
                  if (isBooking) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isBooking
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                if (!showCost)
                  OutlinedButton.icon(
                    onPressed: isBooking
                        ? null
                        : () {
                            setDialogState(() {
                              serviceCost = _generateRandomCost();
                              showCost = true;
                            });
                          },
                    icon: const Icon(Icons.currency_rupee, size: 18),
                    label: const Text('View Cost'),
                  ),
                ElevatedButton(
                  onPressed: isBooking
                      ? null
                      : () async {
                          final requirements = requirementsController.text.trim();
                          if (requirements.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your requirements'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isBooking = true;
                          });

                          final db = LocalDb.instance;
                          await db.createOrder(
                            title: widget.service.serviceName,
                            description: requirements,
                            status: 'Pending',
                          );
                          
                          if (!ctx.mounted) return;
                          
                          if (mounted) {
                            await _HomeScreenState.of(context)?._loadOrders();
                          }
                          
                          Navigator.of(ctx).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Service "${widget.service.serviceName}" booked successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  child: const Text('Confirm Booking'),
                ),
              ],
            );
          },
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


