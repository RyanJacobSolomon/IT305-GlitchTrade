import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prysmglitchtrade/homepage.dart';
import 'package:prysmglitchtrade/login.dart';

void main() {
  testWidgets('shows Prysm sign in surface', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Build your setup.'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);
  });

  test('matches category names exactly for each listing', () {
    final gpu = GearItem(
      name: 'RTX 3080 FE',
      category: 'GPU',
      price: '\$420',
      condition: 'Mint condition',
      color: const Color(0xFFE6E7DF),
      icon: Icons.view_in_ar_rounded,
    );
    final peripheral = GearItem(
      name: 'Keychron Q1 Pro',
      category: 'Peripherals',
      price: '\$145',
      condition: 'Barely used',
      color: const Color(0xFFDDE7EF),
      icon: Icons.keyboard_rounded,
    );

    expect(HomePage.matchesCategory(gpu, 'GPU'), isTrue);
    expect(HomePage.matchesCategory(peripheral, 'Peripherals'), isTrue);
    expect(HomePage.matchesCategory(peripheral, 'GPU'), isFalse);
    expect(HomePage.matchesCategory(peripheral, 'All gear'), isTrue);
  });

  testWidgets(
    'tapping LIST ITEM FAB opens Create Listing form with all required fields',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Check initial feed
      expect(find.text('Fresh on the bench'), findsOneWidget);
      expect(find.text('RTX 3080 FE'), findsOneWidget);

      // Tap LIST ITEM FAB
      final fab = find.byKey(const Key('list_item_fab'));
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify modal appeared with header and all fields
      expect(find.text('Create Listing'), findsOneWidget);
      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byKey(const Key('category_field')), findsOneWidget);
      expect(find.byKey(const Key('condition_field')), findsOneWidget);
      expect(find.byKey(const Key('price_field')), findsOneWidget);
      expect(find.byKey(const Key('description_field')), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.byKey(const Key('submit_listing_button')), findsOneWidget);
    },
  );

  testWidgets('validates required fields and numeric price in listing form', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    // Open listing form
    await tester.tap(find.byKey(const Key('list_item_fab')));
    await tester.pumpAndSettle();

    // Tap submit with empty fields
    await tester.tap(find.byKey(const Key('submit_listing_button')));
    await tester.pumpAndSettle();

    // Validation messages should appear
    expect(find.text('Please enter an item name'), findsOneWidget);
    expect(find.text('Please enter or select condition'), findsOneWidget);
    expect(find.text('Please enter a price'), findsOneWidget);

    // Enter non-numeric price
    await tester.enterText(
      find.byKey(const Key('price_field')),
      'not_a_number',
    );
    await tester.tap(find.byKey(const Key('submit_listing_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Price must be numeric (e.g. 420 or 145.50)'),
      findsOneWidget,
    );
  });

  testWidgets('creates a new listing and adds it to Fresh on the bench feed', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    // Open form
    await tester.tap(find.byKey(const Key('list_item_fab')));
    await tester.pumpAndSettle();

    // Fill valid data
    await tester.enterText(
      find.byKey(const Key('name_field')),
      'RTX 4090 Rog Strix',
    );
    await tester.enterText(
      find.byKey(const Key('condition_field')),
      'Mint condition',
    );
    await tester.enterText(find.byKey(const Key('price_field')), '1650');
    await tester.enterText(
      find.byKey(const Key('description_field')),
      'Flawless condition, box included.',
    );

    // Submit form
    await tester.tap(find.byKey(const Key('submit_listing_button')));
    await tester.pumpAndSettle();

    // New item should appear immediately in the feed
    expect(find.text('RTX 4090 Rog Strix'), findsOneWidget);
    expect(find.text('\$1650'), findsOneWidget);
    expect(
      find.text('Listing "RTX 4090 Rog Strix" added to the bench!'),
      findsOneWidget,
    );
  });

  testWidgets('three-dot menu supports Edit, Mark as Sold, and Delete', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    // Find the first three-dot menu button on RTX 3080 FE card
    final moreButtons = find.byType(PopupMenuButton<String>);
    expect(moreButtons, findsWidgets);

    // Test Mark as Sold
    await tester.tap(moreButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Mark as sold'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Mark as sold'));
    await tester.pumpAndSettle();

    // Should display SOLD badge
    expect(find.text('SOLD'), findsOneWidget);

    // Test Edit
    await tester.tap(moreButtons.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Modal should open pre-filled with RTX 3080 FE in the name field
    expect(find.text('Edit Listing'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('name_field')),
        matching: find.text('RTX 3080 FE'),
      ),
      findsOneWidget,
    );

    // Change price
    await tester.enterText(find.byKey(const Key('price_field')), '399');
    await tester.tap(find.byKey(const Key('submit_listing_button')));
    await tester.pumpAndSettle();

    expect(find.text('\$399'), findsOneWidget);

    // Test Delete with confirmation
    await tester.tap(moreButtons.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.text('Delete listing?'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);

    // Tap DELETE in confirmation dialog
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();

    // Item should be removed from feed
    expect(find.text('RTX 3080 FE'), findsNothing);
  });

  test('matchesCategory supports PC component names and abbreviations', () {
    final cpu = GearItem(
      name: 'Ryzen 7',
      category: 'CPU',
      price: '\$285',
      condition: 'Mint',
      color: Colors.white,
      icon: Icons.memory,
    );
    final gpu = GearItem(
      name: 'RTX 4090',
      category: 'Graphics Card (GPU)',
      price: '\$1600',
      condition: 'Mint',
      color: Colors.white,
      icon: Icons.view_in_ar,
    );

    expect(HomePage.matchesCategory(cpu, 'Processor (CPU)'), isTrue);
    expect(HomePage.matchesCategory(cpu, 'CPU'), isTrue);
    expect(HomePage.matchesCategory(cpu, 'All Gear'), isTrue);
    expect(HomePage.matchesCategory(cpu, 'All gear'), isTrue);
    expect(HomePage.matchesCategory(gpu, 'GPU'), isTrue);
    expect(HomePage.matchesCategory(gpu, 'Graphics Card (GPU)'), isTrue);
    expect(HomePage.matchesCategory(gpu, 'Processor (CPU)'), isFalse);
  });

  testWidgets('displays all 11 PC component category chips in order and filters feed', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    // 1. Verify category list constant order
    expect(HomePage.categories, [
      'All Gear',
      'Processor (CPU)',
      'Motherboard',
      'Memory (RAM)',
      'Graphics Card (GPU)',
      'Storage',
      'Power Supply Unit (PSU)',
      'CPU Cooler',
      'PC Case',
      'Operating System',
      'PC Peripherals',
    ]);

    // 2. Verify "All Gear" is selected by default with checkmark icon
    expect(find.text('All Gear'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Initial feed contains all gear
    expect(find.text('RTX 3080 FE'), findsOneWidget);
    expect(find.text('Keychron Q1 Pro'), findsOneWidget);
    expect(find.text('Ryzen 7 7800X3D'), findsOneWidget);

    // 3. Tap "Graphics Card (GPU)"
    await tester.tap(find.text('Graphics Card (GPU)'));
    await tester.pumpAndSettle();

    // Should only show RTX 3080 FE
    expect(find.text('RTX 3080 FE'), findsOneWidget);
    expect(find.text('Keychron Q1 Pro'), findsNothing);
    expect(find.text('Ryzen 7 7800X3D'), findsNothing);

    // Single-select checkmark is now on Graphics Card (GPU)
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // 4. Tap "Processor (CPU)"
    await tester.tap(find.text('Processor (CPU)'));
    await tester.pumpAndSettle();

    expect(find.text('Ryzen 7 7800X3D'), findsOneWidget);
    expect(find.text('RTX 3080 FE'), findsNothing);
    expect(find.text('Keychron Q1 Pro'), findsNothing);

    // 5. Scroll horizontally to "PC Peripherals"
    final scrollableFinder = find.descendant(
      of: find.byKey(const Key('category_filter_list')),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('category_chip_PC_Peripherals')),
      200,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();

    expect(find.text('PC Peripherals'), findsOneWidget);
    await tester.tap(find.text('PC Peripherals'));
    await tester.pumpAndSettle();

    expect(find.text('Keychron Q1 Pro'), findsOneWidget);
    expect(find.text('RTX 3080 FE'), findsNothing);
    expect(find.text('Ryzen 7 7800X3D'), findsNothing);

    // 6. Test empty category
    await tester.scrollUntilVisible(
      find.byKey(const Key('category_chip_Motherboard')),
      -200,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Motherboard'));
    await tester.pumpAndSettle();

    expect(find.text('No gear listed in this category.'), findsOneWidget);

    // 7. Tap "See all" to reset
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.text('RTX 3080 FE'), findsOneWidget);
    expect(find.text('Keychron Q1 Pro'), findsOneWidget);
    expect(find.text('Ryzen 7 7800X3D'), findsOneWidget);
  });

  testWidgets('verifies chip styling: sage green selected, dark navy unselected, pill border radius', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    // Find "All Gear" chip (selected)
    final allGearChip = find.byKey(const Key('category_chip_All_Gear'));
    expect(allGearChip, findsOneWidget);

    final allGearContainer = tester.widget<AnimatedContainer>(
      find.descendant(of: allGearChip, matching: find.byType(AnimatedContainer)),
    );
    final allGearDecoration = allGearContainer.decoration as BoxDecoration;
    expect(allGearDecoration.color, const Color(0xFF5A7D6E));
    expect(allGearDecoration.borderRadius, BorderRadius.circular(999));

    // Check checkmark icon inside All Gear chip
    expect(
      find.descendant(of: allGearChip, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );

    // Find "Processor (CPU)" chip (unselected initially)
    final cpuChip = find.byKey(const Key('category_chip_Processor__CPU_'));
    expect(cpuChip, findsOneWidget);

    final cpuContainer = tester.widget<AnimatedContainer>(
      find.descendant(of: cpuChip, matching: find.byType(AnimatedContainer)),
    );
    final cpuDecoration = cpuContainer.decoration as BoxDecoration;
    expect(cpuDecoration.color, const Color(0xFF1A2332));
    expect(cpuDecoration.borderRadius, BorderRadius.circular(999));

    // No checkmark inside unselected chip
    expect(
      find.descendant(of: cpuChip, matching: find.byIcon(Icons.check_rounded)),
      findsNothing,
    );

    // Tap Processor (CPU)
    await tester.tap(cpuChip);
    await tester.pumpAndSettle();

    // Now Processor (CPU) should be sage green with checkmark
    final cpuContainerSelected = tester.widget<AnimatedContainer>(
      find.descendant(of: cpuChip, matching: find.byType(AnimatedContainer)),
    );
    expect((cpuContainerSelected.decoration as BoxDecoration).color, const Color(0xFF5A7D6E));
    expect(
      find.descendant(of: cpuChip, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );

    // And All Gear should now be unselected (dark navy without checkmark)
    final allGearContainerUnselected = tester.widget<AnimatedContainer>(
      find.descendant(of: allGearChip, matching: find.byType(AnimatedContainer)),
    );
    expect((allGearContainerUnselected.decoration as BoxDecoration).color, const Color(0xFF1A2332));
    expect(
      find.descendant(of: allGearChip, matching: find.byIcon(Icons.check_rounded)),
      findsNothing,
    );
  });
}


