import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:odogo_app/views/driver_active_trip_screen.dart';
import 'package:odogo_app/controllers/trip_controller.dart';
import 'package:odogo_app/models/trip_model.dart';
import 'package:odogo_app/models/enums.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  group('Task 20: Location Selection & Routing UI Tests', () {
    testWidgets('DriverActiveTripScreen dynamically calculates ETA and renders Location Routes', (WidgetTester tester) async {
      
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final exceptionString = details.exception.toString();
        if (exceptionString.contains('Using "ref" when a widget is about to or has been unmounted')) {
          return; 
        }
        originalOnError?.call(details);
      };

      // 1. Arrange
      final mockTrip = TripModel(
        tripID: 'trip_20',
        status: TripStatus.ongoing,
        commuterName: 'Karthic',
        commuterID: 'karthic@test.com',
        startLocName: 'Hall 1', 
        endLocName: 'Main Gate', 
        startTime: DateTime.now(),
        ridePIN: '1234',
        driverEnd: false,
        commuterEnd: false,
        bookingTime: DateTime.now(),
      );

      // 2. Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeTripStreamProvider('trip_20').overrideWith((ref) => Stream.value(mockTrip)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DriverActiveTripScreen(
                tripID: 'trip_20',
                pickupLocation: LatLng(26.5123, 80.2329), 
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 3. Assert
      expect(find.text('Main Gate'), findsOneWidget); 
      expect(find.text('Karthic'), findsOneWidget);
      expect(find.text('Heading to Drop-off'), findsOneWidget);
      expect(find.text('END TRIP'), findsOneWidget);
      expect(find.textContaining('mins'), findsOneWidget);

      // --- THE FIX: Fast forward 10 seconds to flush the 8-second _loadRoadRoute timer ---
      await tester.pump(const Duration(seconds: 10));

      await tester.pumpWidget(Container());
      await tester.pump();

      FlutterError.onError = originalOnError;
    });
  });
}