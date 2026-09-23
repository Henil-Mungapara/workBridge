import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workbridge/app/app.dart';
import 'package:workbridge/controllers/user_controller.dart';
import 'package:workbridge/core/constants/app_currency.dart';
import 'package:workbridge/core/services/app_preferences.dart';
import 'package:workbridge/models/service_category_model.dart';
import 'package:workbridge/models/user_model.dart';

void main() {
  testWidgets('WorkBridge complete live sequence: Splash -> GetStarted -> Policy -> SignUp -> Login -> Dashboard -> Profile -> Logout', (WidgetTester tester) async {
    // 1. Initialize SharedPreferences: isFirstLoggin=true, isLoggin=true
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstLoggin: true,
      AppPreferences.keyIsLoggin: true,
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());

    // 2. Splash Screen 3s timer
    expect(find.text('WORKBRIDGE'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // 3. Get Started Screen (because isFirstLoggin == true)
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Welcome to\nWorkBridge'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // 4. Privacy Policy Screen with 2 checkboxes
    expect(find.text('Privacy Policy & Terms'), findsOneWidget);
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(2));
    await tester.tap(checkboxes.at(0));
    await tester.pumpAndSettle();
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 5. Sign Up Screen
    expect(find.text('Get Started with WorkBridge'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Switch to Login screen
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    // 6. Login Screen
    expect(find.text('Log In to Your Account'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    // Perform Login: sets isFirstLoggin=false and isLoggin=false
    await tester.tap(find.text('Log In'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // 7. Dashboard Screen
    expect(find.text('Active Bookings'), findsOneWidget);
    expect(find.text('Explore Service Categories'), findsOneWidget);

    // 8. Open Profile Screen from Dashboard Bottom Navigation
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // 9. Verify Profile Screen details
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Account Credentials'), findsOneWidget);
    expect(find.text('User ID (UID)'), findsOneWidget);

    // Dismiss any active floating SnackBar
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // 10. Perform Logout (sets isLoggin=true and redirects to Login)
    await tester.ensureVisible(find.text('Log Out of WorkBridge'));
    await tester.tap(find.text('Log Out of WorkBridge'));
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Are you sure you want to log out of WorkBridge?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
    await tester.pumpAndSettle();

    // Assert redirected back to Login screen
    expect(find.text('Log In to Your Account'), findsOneWidget);

    // Assert isLoggin is true after logout
    final isNeedLogin = await AppPreferences.getIsLoggin();
    expect(isNeedLogin, isTrue);

    // Assert isFirstLoggin is false
    final isFirst = await AppPreferences.getIsFirstLoggin();
    expect(isFirst, isFalse);
  });

  testWidgets('Splash directs immediately to Dashboard when already logged in', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstLoggin: false,
      AppPreferences.keyIsLoggin: false,
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Active Bookings'), findsOneWidget);
    expect(find.text('Explore Service Categories'), findsOneWidget);
  });

  testWidgets('Splash directs immediately to Login when user previously logged out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstLoggin: false,
      AppPreferences.keyIsLoggin: true,
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Log In to Your Account'), findsOneWidget);
  });

  testWidgets('Splash evaluates reference keys: isFirstInstall=true directs to GetStarted', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: true,
      AppPreferences.keyIsLoggedIn: false,
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Welcome to\nWorkBridge'), findsOneWidget);
  });

  testWidgets('Splash evaluates reference keys: isLoggedIn=true with role directs to Dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'customer',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Active Bookings'), findsOneWidget);
    expect(find.text('Explore Service Categories'), findsOneWidget);
  });

  testWidgets('Hot reload triggers reassemble and restarts compulsory from Splash Screen before Dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'customer',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // User is on Dashboard
    expect(find.text('Active Bookings'), findsOneWidget);

    // Simulate Hot Reload
    // ignore: invalid_use_of_protected_member
    tester.element(find.byType(WorkBridgeApp)).reassemble();
    await tester.pump();

    // Must be compulsory back on Splash Screen
    expect(find.text('WORKBRIDGE'), findsOneWidget);

    // Let Splash finish 3 seconds
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Routes verified user back to Dashboard
    expect(find.text('Active Bookings'), findsOneWidget);
  });

  testWidgets('Splash directs immediately to Provider Dashboard when role is provider', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'provider',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Must be on Service Provider Dashboard
    expect(find.text('Provider Portal'), findsOneWidget);
    expect(find.text('Incoming Job Requests'), findsOneWidget);
    expect(find.text('Active Gigs'), findsOneWidget);
  });

  testWidgets('Splash directs immediately to Admin Dashboard when role is admin', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'admin',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Must be on Admin Dashboard
    expect(find.text('WorkBridge Administration'), findsOneWidget);
    expect(find.text('SUPER ADMIN PORTAL'), findsOneWidget);
    expect(find.text('Total Customers'), findsOneWidget);
    expect(find.text('Active Providers'), findsOneWidget);
  });

  testWidgets('Provider state management dynamically updates user name across all panels', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'customer',
      AppPreferences.keyUserName: 'Initial User',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // On Dashboard, update profile via Provider directly
    final BuildContext context = tester.element(find.text('Active Bookings'));
    final userController = Provider.of<UserController>(context, listen: false);

    // Dynamic update name
    await userController.updateProfile(name: 'Jane Doe Updated', phone: '+1234567890');
    await tester.pump();

    // Verify all places on dashboard with user name are dynamically updated
    expect(find.text('Jane Doe Updated'), findsWidgets);
  });

  test('UserModel.normalizeRole preserves unrecognized roles for strict validation', () {
    expect(UserModel.normalizeRole('customer'), 'customer');
    expect(UserModel.normalizeRole('Customer'), 'customer');
    expect(UserModel.normalizeRole('admin'), 'admin');
    expect(UserModel.normalizeRole('Admin'), 'admin');
    expect(UserModel.normalizeRole('service_provider'), 'service_provider');
    expect(UserModel.normalizeRole('Service_Provider'), 'service_provider');
    expect(UserModel.normalizeRole('provider'), 'service_provider');
    expect(UserModel.normalizeRole('Provider'), 'service_provider');
    expect(UserModel.normalizeRole('service provider'), 'service_provider');
    expect(UserModel.normalizeRole('unknown_role'), 'unknown_role');
    expect(UserModel.normalizeRole('Henil'), 'Henil');
    expect(UserModel.normalizeRole(null), 'customer');
  });

  test('AppRoles strictly allows only Customer, Service_Provider, and Admin (case-insensitive conversion)', () {
    // Valid roles in any casing
    expect(AppRoles.isValid('customer'), isTrue);
    expect(AppRoles.isValid('Customer'), isTrue);
    expect(AppRoles.isValid('CUSTOMER'), isTrue);
    expect(AppRoles.isValid('admin'), isTrue);
    expect(AppRoles.isValid('Admin'), isTrue);
    expect(AppRoles.isValid('ADMIN'), isTrue);
    expect(AppRoles.isValid('service_provider'), isTrue);
    expect(AppRoles.isValid('Service_Provider'), isTrue);
    expect(AppRoles.isValid('SERVICE_PROVIDER'), isTrue);
    expect(AppRoles.isValid('provider'), isTrue);
    expect(AppRoles.isValid('Provider'), isTrue);
    expect(AppRoles.isValid('service provider'), isTrue);

    // Invalid roles strictly rejected (e.g. 'Henil')
    expect(AppRoles.isValid('Henil'), isFalse);
    expect(AppRoles.isValid('henil'), isFalse);
    expect(AppRoles.isValid('student'), isFalse);
    expect(AppRoles.isValid('faculty'), isFalse);
    expect(AppRoles.isValid('guest'), isFalse);
    expect(AppRoles.isValid(''), isFalse);
    expect(AppRoles.isValid(null), isFalse);

    // Canonicalization
    expect(AppRoles.canonicalize('Customer'), 'customer');
    expect(AppRoles.canonicalize('SERVICE_PROVIDER'), 'service_provider');
    expect(AppRoles.canonicalize('Admin'), 'admin');
    expect(AppRoles.canonicalize('Henil'), isNull);
  });

  testWidgets('Splash directs immediately to Provider Dashboard when role is service_provider', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'service_provider',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Must be on Service Provider Dashboard
    expect(find.text('Provider Portal'), findsOneWidget);
    expect(find.text('Incoming Job Requests'), findsOneWidget);
    expect(find.text('Active Gigs'), findsOneWidget);
  });

  testWidgets('Splash directs to role panel when isLoggedIn=true even if isFirstInstall=true', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: true, // e.g. uninitialized prefs but user logged in
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'admin',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // User should navigate directly to Admin Dashboard, NOT GetStarted
    expect(find.text('WorkBridge Administration'), findsOneWidget);
    expect(find.text('SUPER ADMIN PORTAL'), findsOneWidget);
  });

  test('AppPreferences.determineSplashTargetRoute resolves customer, admin, and service_provider', () async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'customer',
    });
    expect(await AppPreferences.determineSplashTargetRoute(), '/customer/dashboard');

    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'admin',
    });
    expect(await AppPreferences.determineSplashTargetRoute(), '/admin/dashboard');

    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'service_provider',
    });
    expect(await AppPreferences.determineSplashTargetRoute(), '/provider/dashboard');
  });

  testWidgets('SignUpView allows selecting Provider and navigates to Provider Dashboard with service_provider role', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: false,
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // On Login screen, switch to Sign Up
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Select Provider role option
    expect(find.text('Provider'), findsOneWidget);
    await tester.tap(find.text('Provider'));
    await tester.pumpAndSettle();

    // Fill sign up inputs
    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Bob Provider');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'provider@test.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number'), '1234567890');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Password123!');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'Password123!');

    // Submit sign up
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Role in SharedPreferences must be service_provider
    final savedRole = await AppPreferences.getUserRole();
    expect(savedRole, 'service_provider');

    // Must have routed to Provider Dashboard
    expect(find.text('Provider Portal'), findsOneWidget);
    expect(find.text('Incoming Job Requests'), findsOneWidget);
  });

  testWidgets('Admin Dashboard switches to Providers tab, searches and sorts dynamically', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'admin',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify on Admin Dashboard
    expect(find.text('SUPER ADMIN PORTAL'), findsOneWidget);

    // Tap Manage Providers module tile
    await tester.ensureVisible(find.text('Manage\nProviders'));
    await tester.tap(find.text('Manage\nProviders'));
    await tester.pumpAndSettle();

    // Verify on Providers Tab
    expect(find.text('Service Providers'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Search provider or trade...'), findsOneWidget);

    // Search input interaction
    await tester.enterText(find.widgetWithText(TextField, 'Search provider or trade...'), 'Electrician');
    await tester.pumpAndSettle();

    // Clear search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Service Providers'), findsOneWidget);
  });

  testWidgets('Admin Dashboard switches to Users tab, searches dynamically and Admin Profile shows styled logout dialog', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'admin',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Tap Manage Customers tile
    await tester.ensureVisible(find.text('Manage\nCustomers'));
    await tester.tap(find.text('Manage\nCustomers'));
    await tester.pumpAndSettle();

    // Verify Customer Directory
    expect(find.text('Customer Directory'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Search customer name or email...'), findsOneWidget);

    // Search interaction
    await tester.enterText(find.widgetWithText(TextField, 'Search customer name or email...'), 'Diana');
    await tester.pumpAndSettle();

    // Open Admin Profile
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Profile'), findsOneWidget);
    expect(find.text('Log Out of Admin Portal'), findsOneWidget);

    // Tap Logout button
    await tester.ensureVisible(find.text('Log Out of Admin Portal'));
    await tester.tap(find.text('Log Out of Admin Portal'));
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog with custom styled alert box
    expect(find.text('Are you sure you want to log out of the Administrator Portal?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog dismissed, still on admin profile
    expect(find.text('Admin Profile'), findsOneWidget);
  });

  test('UserModel securely retains password in toMap and fromMap serialization', () {
    final user = UserModel(
      uid: 'test_uid_123',
      name: 'Henil Patel',
      email: 'henil@test.com',
      phone: '+1234567890',
      role: 'Customer',
      password: 'SecretPassword123!',
      createdAt: '2026-09-19T12:00:00.000Z',
      updatedAt: '2026-09-19T12:00:00.000Z',
    );

    final map = user.toMap();
    expect(map['password'], 'SecretPassword123!');
    expect(map['role'], 'customer');

    final reconstructed = UserModel.fromMap(map);
    expect(reconstructed.password, 'SecretPassword123!');
    expect(reconstructed.role, 'customer');
    expect(reconstructed.canonicalRole, 'customer');
    expect(AppRoles.displayName(reconstructed.role), 'Customer');
    expect(reconstructed.name, 'Henil Patel');

    final updated = user.copyWith(password: 'NewPass456!');
    expect(updated.password, 'NewPass456!');
    expect(updated.name, 'Henil Patel');
  });

  test('UserController tracks session role properly', () {
    final controller = UserController();
    expect(controller.sessionRole, isNull);
    expect(controller.isLoggedIn, isFalse);
    expect(controller.user.uid.isEmpty, isTrue);
  });

  test('AppCurrency strictly enforces Indian Rupee (₹ - INR) and proper formatting', () {
    expect(AppCurrency.symbol, '₹');
    expect(AppCurrency.code, 'INR');
    expect(AppCurrency.icon, Icons.currency_rupee_rounded);
    expect(AppCurrency.format(1200), '₹1,200.00');
    expect(AppCurrency.format(4200, showDecimals: false), '₹4,200');
    expect(AppCurrency.format(18500), '₹18,500.00');
    expect(AppCurrency.formatRate(450), '₹450.00 / hour');
  });

  test('ServiceCategory.all8Categories defines exactly the 8 requested service categories', () {
    final names = ServiceCategory.all8Categories.map((c) => c.name).toList();
    expect(names.length, 8);
    expect(names, contains('Plumbing'));
    expect(names, contains('Electrical'));
    expect(names, contains('Carpentry'));
    expect(names, contains('Painting'));
    expect(names, contains('Home Cleaning'));
    expect(names, contains('Appliance Repair'));
    expect(names, contains('Salon & Beauty'));
    expect(names, contains('Vehicle Services'));
  });

  testWidgets('Customer Dashboard displays all 8 service categories and View All modal', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'customer',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify Customer Dashboard Categories Header
    expect(find.text('Explore Service Categories'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);

    // Verify all 8 categories are rendered on dashboard
    expect(find.text('Plumbing'), findsWidgets);
    expect(find.text('Electrical'), findsWidgets);
    expect(find.text('Carpentry'), findsWidgets);
    expect(find.text('Painting'), findsWidgets);
    expect(find.text('Home Cleaning'), findsWidgets);
    expect(find.text('Appliance Repair'), findsWidgets);
    expect(find.text('Salon & Beauty'), findsWidgets);
    expect(find.text('Vehicle Services'), findsWidgets);

    // Tap View All button to open All Categories modal
    await tester.ensureVisible(find.text('View All'));
    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();

    expect(find.text('All Service Categories'), findsOneWidget);
    expect(find.text('8 categories available for instant booking'), findsOneWidget);

    // Close modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
  });

  testWidgets('Provider Dashboard displays ONLY assigned category and hides unrelated categories', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'service_provider',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify on Provider Dashboard
    expect(find.text('Provider Portal'), findsOneWidget);
    expect(find.text('My Assigned Categories'), findsOneWidget);

    // Default assigned specialization is Electrical
    expect(find.text('Electrical'), findsOneWidget);

    // Assert that unrelated categories are NOT in My Assigned Categories
    expect(find.text('Salon & Beauty'), findsNothing);
    expect(find.text('Home Cleaning'), findsNothing);
    expect(find.text('Vehicle Services'), findsNothing);
    expect(find.text('Carpentry'), findsNothing);
  });

  testWidgets('Admin Dashboard displays all 8 categories and Category Management section', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyIsFirstInstall: false,
      AppPreferences.keyIsLoggedIn: true,
      AppPreferences.keyRole: 'admin',
    });

    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const WorkBridgeApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify Admin Dashboard has Category Management module tile and Platform Categories overview
    expect(find.text('Platform Service Categories'), findsOneWidget);
    expect(find.text('Category\nManagement'), findsOneWidget);

    // Verify all 8 categories in overview grid
    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Electrical'), findsOneWidget);
    expect(find.text('Carpentry'), findsOneWidget);
    expect(find.text('Painting'), findsOneWidget);
    expect(find.text('Home Cleaning'), findsOneWidget);
    expect(find.text('Appliance Repair'), findsOneWidget);
    expect(find.text('Salon & Beauty'), findsOneWidget);
    expect(find.text('Vehicle Services'), findsOneWidget);

    // Tap Category Management module tile
    await tester.ensureVisible(find.text('Category\nManagement'));
    await tester.tap(find.text('Category\nManagement'));
    await tester.pumpAndSettle();

    // Verify Category Management modal dialog
    expect(find.text('Category Management'), findsOneWidget);
    expect(find.text('8 main service categories & live technician distribution'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);

    // Close modal
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
}


