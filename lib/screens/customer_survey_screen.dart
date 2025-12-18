import 'package:flutter/material.dart';
import 'package:technex/screens/home_screen.dart';

class CustomerSurveyScreen extends StatefulWidget {
  const CustomerSurveyScreen({super.key});

  @override
  State<CustomerSurveyScreen> createState() => _CustomerSurveyScreenState();
}

class _CustomerSurveyScreenState extends State<CustomerSurveyScreen> {
  final List<_ServiceOption> _options = [
    _ServiceOption(
      key: 'home',
      label: 'Home',
      icon: Icons.home_rounded,
    ),
    _ServiceOption(
      key: 'services',
      label: 'Services',
      icon: Icons.build_rounded,
    ),
    _ServiceOption(
      key: 'healthcare',
      label: 'Healthcare',
      icon: Icons.local_hospital_rounded,
    ),
    _ServiceOption(
      key: 'personal_care',
      label: 'Personal Care',
      icon: Icons.spa_rounded,
    ),
    _ServiceOption(
      key: 'events_occasions',
      label: 'Events & Occasions',
      icon: Icons.celebration_rounded,
    ),
  ];

  final Set<String> _selectedKeys = {};

  void _toggleSelection(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _confirmSelection() async {
    if (_selectedKeys.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 service categories.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Services'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What do you usually look for?',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick at least 3 categories. We will use this to personalise your experience.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: _options.map((option) {
                  final isSelected = _selectedKeys.contains(option.key);
                  return _ServiceTile(
                    option: option,
                    isSelected: isSelected,
                    onTap: () => _toggleSelection(option.key),
                    colorScheme: colorScheme,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSelection,
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceOption {
  const _ServiceOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  final _ServiceOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final baseColor = colorScheme.surface;
    final fadedColor = baseColor.withOpacity(0.65);
    final accent = colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? accent.withOpacity(0.18) : fadedColor,
          border: Border.all(
            color: isSelected ? accent : colorScheme.onSurface.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.onSurface.withOpacity(0.08),
                ),
                child: Icon(
                  option.icon,
                  size: 32,
                  color: accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                option.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


