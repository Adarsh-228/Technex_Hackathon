import 'package:flutter/material.dart';
import 'package:technex/data/local_db.dart';
import 'package:technex/screens/customer_details_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Map<String, Object?>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final db = LocalDb.instance;
    final existing = await db.getCustomerProfile();

    if (!mounted) return;

    if (existing == null) {
      // No profile yet; send user to customer details form.
      // Use push instead of pushReplacement to allow back navigation
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CustomerDetailsScreen(),
          ),
        );
      }
      return;
    }

    setState(() {
      _profile = existing;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileRow(
                            label: 'Name',
                            value: (_profile?['name'] ?? '') as String,
                          ),
                          const SizedBox(height: 16),
                          _ProfileRow(
                            label: 'Email',
                            value: (_profile?['email'] ?? '') as String,
                          ),
                          const SizedBox(height: 16),
                          _ProfileRow(
                            label: 'Phone',
                            value: (_profile?['phone'] ?? '') as String,
                          ),
                          const SizedBox(height: 16),
                          _ProfileRow(
                            label: 'Location (Area / City)',
                            value: (_profile?['location'] ?? '') as String,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () async {
                        final db = LocalDb.instance;
                        await db.clearCustomerProfile();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const CustomerDetailsScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Log out'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}


