import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:prysmglitchtrade/data_catalog_page.dart';
import 'package:prysmglitchtrade/services/api_service.dart';

void main() {
  const sampleProductsJson = '''
  {
    "store": "Prysm Glitch Trade",
    "version": "1.0",
    "products": [
      {
        "id": "gpu-001",
        "name": "NVIDIA GeForce RTX 4080 Super",
        "category": "Graphics Card (GPU)",
        "price": "\$949",
        "condition": "Brand New / Sealed",
        "color": "#E6E7DF",
        "description": "Factory sealed RTX 4080 Super Founders Edition. 16GB GDDR6X.",
        "imageUrl": "https://example.com/rtx4080.jpg",
        "seller": "CyberSamurai",
        "isSold": false
      },
      {
        "id": "cpu-001",
        "name": "AMD Ryzen 9 7950X3D",
        "category": "Processor (CPU)",
        "price": "\$540",
        "condition": "Like New / Pristine",
        "color": "#E8E1D7",
        "description": "16 cores, 32 threads with 3D V-Cache technology.",
        "imageUrl": "https://example.com/ryzen9.jpg",
        "seller": "SiliconBeast",
        "isSold": false
      },
      {
        "id": "periph-001",
        "name": "Wooting 60HE+ Analog Keyboard",
        "category": "PC Peripherals",
        "price": "\$185",
        "condition": "Barely used",
        "color": "#DDE7EF",
        "description": "Rapid Trigger Hall Effect gaming keyboard with Lekker Linear 60 switches.",
        "imageUrl": "https://example.com/wooting.jpg",
        "seller": "RapidTrigger",
        "isSold": false
      }
    ]
  }
  ''';

  const sampleDirectJsonArray = '''
  [
    {
      "id": "ram-001",
      "name": "Corsair Vengeance 32GB DDR5",
      "category": "Memory (RAM)",
      "price": "\$120",
      "condition": "Brand New",
      "color": "#DFECE8",
      "description": "Fast 6000MHz CL30 DDR5 memory kit.",
      "imageUrl": "https://example.com/ram.jpg",
      "seller": "MemMaster",
      "isSold": false
    }
  ]
  ''';

  group('Criterion 1: HTTP GET Request Execution (20 pts)', () {
    test('Executes HTTP GET request successfully and returns 200 OK with product list', () async {
      final mockClient = http_testing.MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), contains('products.json'));
        expect(request.headers['Accept'], 'application/json');

        return http.Response(
          sampleProductsJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final products = await ApiService.fetchCatalogProducts(
        rawUrl: 'https://example.com/api/products.json',
        client: mockClient,
        fallbackToLocal: false,
      );

      expect(products, isNotEmpty);
      expect(products.length, 3);
      expect(products.first.name, 'NVIDIA GeForce RTX 4080 Super');
      expect(products.first.price, '\$949');
    });

    test('Throws exception on HTTP GET error status codes (e.g. 404, 500) when fallback disabled', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      expect(
        () => ApiService.fetchCatalogProducts(
          rawUrl: 'https://example.com/missing.json',
          client: mockClient,
          fallbackToLocal: false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Gracefully falls back to local products when network request fails and fallback enabled', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final products = await ApiService.fetchCatalogProducts(
        rawUrl: 'https://example.com/server-error.json',
        client: mockClient,
        fallbackToLocal: true,
      );

      expect(products, isNotEmpty);
      expect(products.any((p) => p.name.contains('RTX 4080 Super')), isTrue);
    });
  });

  group('Criterion 2: JSON Array to Product Mapping (20 pts)', () {
    test('Maps nested JSON array { "products": [...] } into strongly-typed List<Product>', () {
      final decoded = json.decode(sampleProductsJson);
      final products = ApiService.parseJsonArrayToProducts(decoded);

      expect(products.length, 3);

      final gpu = products[0];
      expect(gpu.id, 'gpu-001');
      expect(gpu.name, 'NVIDIA GeForce RTX 4080 Super');
      expect(gpu.category, 'Graphics Card (GPU)');
      expect(gpu.price, '\$949');
      expect(gpu.numericPrice, 949.0);
      expect(gpu.condition, 'Brand New / Sealed');
      expect(gpu.seller, 'CyberSamurai');
      expect(gpu.isSold, isFalse);

      final cpu = products[1];
      expect(cpu.id, 'cpu-001');
      expect(cpu.name, 'AMD Ryzen 9 7950X3D');
      expect(cpu.category, 'Processor (CPU)');
      expect(cpu.numericPrice, 540.0);
      expect(cpu.seller, 'SiliconBeast');
    });

    test('Maps direct root JSON array [...] into strongly-typed List<Product>', () {
      final decoded = json.decode(sampleDirectJsonArray);
      final products = ApiService.parseJsonArrayToProducts(decoded);

      expect(products.length, 1);
      final ram = products[0];
      expect(ram.id, 'ram-001');
      expect(ram.name, 'Corsair Vengeance 32GB DDR5');
      expect(ram.category, 'Memory (RAM)');
      expect(ram.price, '\$120');
      expect(ram.numericPrice, 120.0);
    });

    test('Product.fromJson handles missing and null fields safely with defaults', () {
      final partialJson = <String, dynamic>{
        'id': 'partial-1',
        'name': null,
        'category': null,
        'price': null,
      };

      final product = Product.fromJson(partialJson);
      expect(product.id, 'partial-1');
      expect(product.name, 'Unnamed Gear');
      expect(product.category, 'All Gear');
      expect(product.price, '\$0');
      expect(product.condition, 'Used');
      expect(product.isSold, isFalse);
    });
  });

  group('Criterion 3 & 4: Dynamic Product ListView Presentation & Search Filtering', () {
    http.Client createMockClient() {
      return http_testing.MockClient((request) async {
        return http.Response(
          sampleProductsJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });
    }

    testWidgets('Dynamic Product ListView presentation renders all mapped items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final client = createMockClient();

      await tester.pumpWidget(
        MaterialApp(
          home: DataCatalogPage(
            client: client,
            initialUrl: 'https://example.com/products.json',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and status
      expect(find.text('Data Catalog'), findsWidgets);
      expect(find.text('HTTP 200 OK'), findsOneWidget);
      expect(find.text('HTTP GET API'), findsOneWidget);

      // Check dynamic product ListView items
      expect(find.text('NVIDIA GeForce RTX 4080 Super'), findsOneWidget);
      expect(find.text('AMD Ryzen 9 7950X3D'), findsOneWidget);
      expect(find.text('Wooting 60HE+ Analog Keyboard'), findsOneWidget);

      // Check prices and badges
      expect(find.text('\$949'), findsOneWidget);
      expect(find.text('\$540'), findsOneWidget);
      expect(find.text('\$185'), findsOneWidget);
      expect(find.text('CyberSamurai'), findsOneWidget);
      expect(find.text('SiliconBeast'), findsOneWidget);

      // Verify tapping product card opens detailed bottom sheet modal
      await tester.tap(find.text('NVIDIA GeForce RTX 4080 Super'));
      await tester.pumpAndSettle();

      // Check modal details
      expect(find.text('Product Description'), findsOneWidget);
      expect(find.text('Product ID'), findsOneWidget);
      expect(find.text('gpu-001'), findsOneWidget);
      expect(find.text('Save Gear'), findsOneWidget);
      expect(find.text('Contact Seller'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Save Gear'));
      await tester.pumpAndSettle();
    });

    testWidgets('Search View Filtering filters products in real time and clears query', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final client = createMockClient();

      await tester.pumpWidget(
        MaterialApp(
          home: DataCatalogPage(
            client: client,
            initialUrl: 'https://example.com/products.json',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially all 3 products are displayed
      expect(find.text('NVIDIA GeForce RTX 4080 Super'), findsOneWidget);
      expect(find.text('AMD Ryzen 9 7950X3D'), findsOneWidget);
      expect(find.text('Wooting 60HE+ Analog Keyboard'), findsOneWidget);

      // Search for "RTX"
      final searchInput = find.byKey(const Key('catalog_search_input'));
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'RTX');
      await tester.pumpAndSettle();

      // Only RTX card should be visible
      expect(find.text('NVIDIA GeForce RTX 4080 Super'), findsOneWidget);
      expect(find.text('AMD Ryzen 9 7950X3D'), findsNothing);
      expect(find.text('Wooting 60HE+ Analog Keyboard'), findsNothing);
      expect(find.text('Found 1 of 3 items'), findsOneWidget);

      // Tap clear search button
      final clearButton = find.byKey(const Key('catalog_search_clear'));
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // All 3 products should be restored
      expect(find.text('NVIDIA GeForce RTX 4080 Super'), findsOneWidget);
      expect(find.text('AMD Ryzen 9 7950X3D'), findsOneWidget);
      expect(find.text('Wooting 60HE+ Analog Keyboard'), findsOneWidget);

      // Search for non-existent keyword to test zero-results empty state
      await tester.enterText(searchInput, 'nonexistenthardwarexyz');
      await tester.pumpAndSettle();

      expect(find.text('No products match "nonexistenthardwarexyz"'), findsOneWidget);
      expect(find.byKey(const Key('catalog_clear_search_empty_button')), findsOneWidget);

      // Tap clear button in empty view
      await tester.tap(find.byKey(const Key('catalog_clear_search_empty_button')));
      await tester.pumpAndSettle();

      // Products restored
      expect(find.text('NVIDIA GeForce RTX 4080 Super'), findsOneWidget);
    });

    testWidgets('Category chips filter dynamic ListView by hardware component', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final client = createMockClient();

      await tester.pumpWidget(
        MaterialApp(
          home: DataCatalogPage(
            client: client,
            initialUrl: 'https://example.com/products.json',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap CPU chip
      final cpuChip = find.byKey(const Key('catalog_chip_CPU'));
      expect(cpuChip, findsOneWidget);
      await tester.tap(cpuChip);
      await tester.pumpAndSettle();

      // Only CPU should appear
      expect(find.text('AMD Ryzen 9 7950X3D'), findsOneWidget);
      expect(find.text('NVIDIA GeForce RTX 4080 Super'), findsNothing);
      expect(find.text('Wooting 60HE+ Analog Keyboard'), findsNothing);

      // Tap Peripherals chip
      final periphChip = find.byKey(const Key('catalog_chip_Peripherals'));
      expect(periphChip, findsOneWidget);
      await tester.tap(periphChip);
      await tester.pumpAndSettle();

      expect(find.text('Wooting 60HE+ Analog Keyboard'), findsOneWidget);
      expect(find.text('AMD Ryzen 9 7950X3D'), findsNothing);
      expect(find.text('NVIDIA GeForce RTX 4080 Super'), findsNothing);

      // Tap All chip to reset
      final allChip = find.byKey(const Key('catalog_chip_All'));
      expect(allChip, findsOneWidget);
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('NVIDIA GeForce RTX 4080 Super'), findsOneWidget);
      expect(find.text('AMD Ryzen 9 7950X3D'), findsOneWidget);
      expect(find.text('Wooting 60HE+ Analog Keyboard'), findsOneWidget);
    });
  });
}
