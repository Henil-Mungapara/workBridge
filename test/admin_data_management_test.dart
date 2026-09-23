import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workbridge/controllers/user_controller.dart';
import 'package:workbridge/core/services/firebase_service.dart';
import 'package:workbridge/models/user_model.dart';
import 'package:workbridge/views/admin/admin_data_management_screen.dart';

Widget _buildTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserController>(
        create: (_) => UserController(),
      ),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminDataManagementScreen & Add Customer Unit/Widget Tests', () {
    testWidgets('Renders all 8 management module cards with titles and icons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(_buildTestApp(const AdminDataManagementScreen()));
      await tester.pumpAndSettle();

      // Screen title and hero header
      expect(find.text('Admin Data Management'), findsOneWidget);
      expect(find.text('Platform Management Hub'), findsOneWidget);
      expect(find.text('8 Modules'), findsOneWidget);

      // Verify all 8 cards exist
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Service Providers'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Tapping Customers card opens the Add Customer dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(_buildTestApp(const AdminDataManagementScreen()));
      await tester.pumpAndSettle();

      // Tap on Customers card
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();

      // Verify Add Customer dialog is shown (title and submit button)
      expect(find.text('Add Customer'), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Add Customer'), findsOneWidget);
      expect(find.text('Create new client account'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Form validation on empty submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Customer'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an email address'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Tapping non-customer card opens bottom sheet with architecture ready status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(_buildTestApp(const AdminDataManagementScreen()));
      await tester.pumpAndSettle();

      // Tap on Service Providers card
      await tester.tap(find.text('Service Providers'));
      await tester.pumpAndSettle();

      // Verify Modal Bottom Sheet
      expect(find.text('Ready for Phase 2 Configuration'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      // Dismiss sheet
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(null);
    });

    test('FirebaseService.adminCreateCustomer produces strict minimal customer schema', () async {
      final service = FirebaseService();
      final result = await service.adminCreateCustomer(
        email: 'testcustomer@workbridge.com',
        password: 'password123',
        role: AppRoles.customer,
      );

      expect(result['uid'], isNotEmpty);
      expect(result['email'], 'testcustomer@workbridge.com');
      expect(result['role'], 'customer');
      expect(result['createdAt'], isNotEmpty);
      expect(result['updatedAt'], isNotEmpty);
    });
  });
}
