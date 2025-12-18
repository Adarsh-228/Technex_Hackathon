import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dual-tone palette for the whole app.
    const Color darkTone = Color(0xFF171614); // Parsed from #1717614
    const Color accentTone = Color(0xFF9A8873); // #9A8873

    return MaterialApp(
      title: 'Technex Services',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: accentTone,
          onPrimary: darkTone,
          secondary: accentTone,
          onSecondary: darkTone,
          error: const Color(0xFFCF6679),
          onError: darkTone,
          background: darkTone,
          onBackground: const Color(0xFFF5F3EE),
          surface: const Color(0xFF1F1E1B),
          onSurface: const Color(0xFFF5F3EE),
        ),
        scaffoldBackgroundColor: darkTone,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF5F3EE),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF5F3EE),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFFE0DDD7),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentTone,
            foregroundColor: darkTone,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: accentTone.withOpacity(0.8),
                width: 1,
              ),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1F1E1B),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: const Color(0xFF1F1E1B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          iconColor: accentTone,
          textColor: const Color(0xFFF5F3EE),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F1E1B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: accentTone,
              width: 1.2,
            ),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF8A857D),
          ),
        ),
      ),
      home: const LocationInitializer(),
    );
  }
}

/// Root widget that is responsible for requesting location permissions
/// and fetching the user's current location when the app starts.
class LocationInitializer extends StatefulWidget {
  const LocationInitializer({super.key});

  @override
  State<LocationInitializer> createState() => _LocationInitializerState();
}

class _LocationInitializerState extends State<LocationInitializer> {
  Position? _currentPosition;
  String? _locationError;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        setState(() {
          _locationError = 'Location permission is required to use the app.';
          _initialised = true;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _initialised = true;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
        _initialised = true;
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
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

  @override
  Widget build(BuildContext context) {
    if (!_initialised) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // We keep the fetched location in memory. For now we only show
    // a lightweight hint that location is available or not.
    return RoleSelectionScreen(
      hasLocation: _currentPosition != null && _locationError == null,
    );
  }
}

/// Initial screen with simple role selection buttons.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({
    super.key,
    required this.hasLocation,
  });

  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Local Sure',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary, // #9A8873
                    fontFamily: 'sans-serif',
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Continue as',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomerDetailsScreen(),
                    ),
                  );
                },
                child: const Text('Customer'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ServiceProviderProfileScreen(),
                    ),
                  );
                },
                child: const Text('Service Provider'),
              ),
            ),
            const SizedBox(height: 32),
            if (hasLocation)
              const Text(
                'Location permission granted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              )
            else
              const Text(
                'Location is required for nearby services.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder screen for customer details.
class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Customer details screen (to be implemented).'),
      ),
    );
  }
}

/// Placeholder screen for service provider profile creation.
class ServiceProviderProfileScreen extends StatelessWidget {
  const ServiceProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Provider Profile'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Service provider profile screen (to be implemented).'),
      ),
    );
  }
}
