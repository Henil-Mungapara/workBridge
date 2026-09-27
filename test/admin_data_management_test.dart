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

    testWidgets('Tapping non-configured card opens bottom sheet with architecture ready status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(_buildTestApp(const AdminDataManagementScreen()));
      await tester.pumpAndSettle();

      // Tap on Services card
      await tester.tap(find.text('Services'));
      await tester.pumpAndSettle();

      // Verify Modal Bottom Sheet
      expect(find.text('Ready for Phase 2 Configuration'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      // Dismiss sheet
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Tapping Service Providers card opens the Add Service Provider dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(_buildTestApp(const AdminDataManagementScreen()));
      await tester.pumpAndSettle();

      // Tap on Service Providers card
      await tester.tap(find.text('Service Providers'));
      await tester.pumpAndSettle();

      // Verify Add Service Provider dialog is shown
      expect(find.text('Add Service Provider'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add Provider'), findsOneWidget);
      expect(find.text('Register new certified technician'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Assigned Role'), findsOneWidget);
      expect(find.text('Mark as Verified Provider'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Tapping Categories card opens the Category Management dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(_buildTestApp(const AdminDataManagementScreen()));
      await tester.pumpAndSettle();

      // Tap on Categories card
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      // Verify Category Management dialog is shown
      expect(find.text('Category Management'), findsOneWidget);
      expect(find.text('Dynamic Firestore categories & platform catalog'), findsOneWidget);
      expect(find.text('Add Category'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
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

    test('FirebaseService.adminCreateServiceProvider produces complete provider schema', () async {
      final service = FirebaseService();
      final result = await service.adminCreateServiceProvider(
        name: 'Suresh Kumar',
        email: 'suresh@workbridge.com',
        phone: '+91 98765 12345',
        password: 'password123',
        category: 'Plumbing',
        isVerified: true,
      );

      expect(result['uid'], isNotEmpty);
      expect(result['name'], 'Suresh Kumar');
      expect(result['email'], 'suresh@workbridge.com');
      expect(result['phone'], '+91 98765 12345');
      expect(result['role'], 'service_provider');
      expect(result['categories'], contains('Plumbing'));
      expect(result['trade'], 'Plumbing');
      expect(result['isVerified'], isTrue);
      expect(result['rating'], 5.0);
      expect(result['completedJobs'], 0);
      expect(result['createdAt'], isNotEmpty);
      expect(result['updatedAt'], isNotEmpty);
    });

    test('FirebaseService.fetchCategories and adminCreateCategory work properly', () async {
      final service = FirebaseService();
      final cats = await service.fetchCategories();
      expect(cats, isNotEmpty);

      final created = await service.adminCreateCategory(
        name: 'Pest Control',
        description: 'Termite and pest extermination',
      );
      expect(created.name, 'Pest Control');
      expect(created.description, 'Termite and pest extermination');
      expect(created.id, isNotEmpty);
    });
  });
}
