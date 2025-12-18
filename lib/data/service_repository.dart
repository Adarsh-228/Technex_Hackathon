import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ServiceProvider {
  const ServiceProvider({
    required this.providerName,
    required this.serviceName,
    required this.serviceCategory,
    required this.primarySkill,
    required this.locationArea,
    required this.serviceRadiusKm,
    required this.experienceYears,
    required this.availabilityStatus,
    required this.emergencySupport,
  });

  final String providerName;
  final String serviceName;
  final String serviceCategory;
  final String primarySkill;
  final String locationArea;
  final int serviceRadiusKm;
  final int experienceYears;
  final String availabilityStatus;
  final String emergencySupport;
}

class ServiceRepository {
  ServiceRepository._internal();

  static final ServiceRepository instance = ServiceRepository._internal();

  List<ServiceProvider>? _cached;

  Future<List<ServiceProvider>> loadServices() async {
    if (_cached != null) return _cached!;

    final csvString = await rootBundle
        .loadString('assets/data/nagpur_service_providers.csv');

    final lines = const LineSplitter().convert(csvString.trim());
    if (lines.length <= 1) {
      _cached = <ServiceProvider>[];
      return _cached!;
    }

    // Skip header
    final dataLines = lines.skip(1);
    final services = <ServiceProvider>[];

    for (final line in dataLines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 9) continue;

      int parseInt(String s) => int.tryParse(s.trim()) ?? 0;

      services.add(
        ServiceProvider(
          providerName: parts[0].trim(),
          serviceName: parts[1].trim(),
          serviceCategory: parts[2].trim(),
          primarySkill: parts[3].trim(),
          locationArea: parts[4].trim(),
          serviceRadiusKm: parseInt(parts[5]),
          experienceYears: parseInt(parts[6]),
          availabilityStatus: parts[7].trim(),
          emergencySupport: parts[8].trim(),
        ),
      );
    }

    _cached = services;
    return _cached!;
  }
}


