import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hedieaty/main.dart'; // Replace with your correct import path
import 'package:hedieaty/screens/login_page.dart'; // Replace with your correct import path

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login and Add Event Test', () {
    setUpAll(() async {
      await Firebase.initializeApp();
      // You can create test users or mock Firebase initialization here if needed
    });

    tearDownAll(() async {
      // You can add cleanup tasks here, such as deleting test users if needed
    });

    testWidgets('Login, Navigate to Event List Tab and Add an Event', (tester) async {
      await tester.pumpWidget(HedieatyApp());

      // Ensure the login fields are present on the screen
      expect(find.byKey(const ValueKey('loginEmailField')), findsOneWidget);
      expect(find.byKey(const ValueKey('loginPasswordField')), findsOneWidget);

      // Find the email and password fields, and enter test credentials
      final emailField = find.byKey(const ValueKey('loginEmailField'));
      await tester.enterText(emailField, 'testuser@yahoo.com');

      final passwordField = find.byKey(const ValueKey('loginPasswordField'));
      await tester.enterText(passwordField, 'testPassword123%');

      // Find and tap the login button
      final loginButton = find.byKey(const ValueKey('loginButtonKey'));
      await tester.tap(loginButton);

      // Wait for the UI to settle after the login attempt
      await tester.pumpAndSettle();

      // Check that you're on the right page after logging in
      expect(find.byKey(ValueKey('homePageAppBar')), findsOneWidget);  // Check for home page

      // Now tap on the second item in the BottomNavigationBar to navigate to the Event List
      final eventTab = find.byIcon(Icons.event);
      await tester.tap(eventTab);

      // Wait for the UI to settle after the navigation
      await tester.pumpAndSettle();

      // Ensure the correct page (Event List) is displayed
      expect(find.text('Event List'), findsOneWidget);

      // Now, find the "Add Event" button (assuming a floating action button or similar element)
      final addEventButton = find.byKey(const ValueKey('addEventButtonKey')); // Replace with your actual key
      await tester.tap(addEventButton);


      // Wait for the UI to settle (this might be a form to create the event)
      await tester.pumpAndSettle();

      // Ensure the event form is displayed (check if any input fields or title are visible)
      // Ensure the fields are present
      expect(find.byKey(const ValueKey('eventNameField')), findsOneWidget);
      expect(find.byKey(const ValueKey('eventDescriptionField')), findsOneWidget);
      expect(find.byKey(const ValueKey('eventLocationField')), findsOneWidget);
      expect(find.byKey(const ValueKey('eventDatePicker')), findsOneWidget);

      // Enter test data into the fields
      await tester.enterText(find.byKey(const ValueKey('eventNameField')), 'Test Event');
      await tester.enterText(find.byKey(const ValueKey('eventDescriptionField')), 'This is a description for the test event');
      await tester.enterText(find.byKey(const ValueKey('eventLocationField')), 'Test Location');

      // Simulate selecting a date (you can implement a date picker simulation if needed)
      await tester.tap(find.byKey(const ValueKey('eventDatePicker')));
      await tester.pumpAndSettle(); // Simulate the date picker behavior


      // Submit the event (usually by tapping a "Save" or "Submit" button)
      final submitButton = find.byKey(const ValueKey('submitEventButton')); // Adjust based on actual key
      await tester.tap(submitButton);

      // Wait for the UI to settle after submitting the event
      await tester.pumpAndSettle();

      // Ensure that the event appears in the Event List
      expect(find.text('Test Event'), findsOneWidget); // Check if the event name appears in the list
    });
  });
}
