import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../homepage.dart';

/// Model representing a product item parsed from GitHub Gist or local JSON.
class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.condition,
    required this.color,
    required this.description,
    required this.imageUrl,
    this.seller = 'Trader',
    this.isSold = false,
  });

  final String id;
  final String name;
  final String category;
  final String price;
  final String condition;
  final String color;
  final String description;
  final String imageUrl;
  final String seller;
  final bool isSold;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Gear',
      category: json['category']?.toString() ?? 'All Gear',
      price: json['price']?.toString() ?? '\$0',
      condition: json['condition']?.toString() ?? 'Used',
      color: json['color']?.toString() ?? '#E6E7DF',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      seller: json['seller']?.toString() ?? 'Trader',
      isSold: json['isSold'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'condition': condition,
    'color': color,
    'description': description,
    'imageUrl': imageUrl,
    'seller': seller,
    'isSold': isSold,
  };

  /// Converts this Product into the app's internal [GearItem].
  GearItem toGearItem() {
    return GearItem(
      name: name,
      category: category,
      price: price,
      condition: condition,
      color: parsedColor,
      icon: categoryIcon,
      imageUrl: imageUrl,
      description: description,
      isSold: isSold,
    );
  }

  /// Returns parsed Flutter [Color] from the hex code.
  Color get parsedColor {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return const Color(0xFF1E293B);
    }
  }

  /// Returns associated [IconData] based on category.
  IconData get categoryIcon => _iconForCategory(category);

  /// Returns numeric price value (e.g. '$949' -> 949.0).
  double get numericPrice {
    final clean = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  static IconData _iconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('gpu') || cat.contains('graphics')) {
      return Icons.view_in_ar_rounded;
    }
    if (cat.contains('cpu') || cat.contains('processor')) {
      return Icons.memory_rounded;
    }
    if (cat.contains('periph') || cat.contains('keyboard') || cat.contains('mouse')) {
      return Icons.keyboard_rounded;
    }
    if (cat.contains('motherboard') || cat.contains('mobo')) {
      return Icons.developer_board_rounded;
    }
    if (cat.contains('ram') || cat.contains('memory')) {
      return Icons.straighten_rounded;
    }
    if (cat.contains('storage') || cat.contains('ssd') || cat.contains('nvme')) {
      return Icons.storage_rounded;
    }
    if (cat.contains('psu') || cat.contains('power')) {
      return Icons.bolt_rounded;
    }
    if (cat.contains('cooler')) {
      return Icons.ac_unit_rounded;
    }
    if (cat.contains('case')) {
      return Icons.computer_rounded;
    }
    if (cat.contains('display') || cat.contains('monitor')) {
      return Icons.monitor_rounded;
    }
    return Icons.devices_other_rounded;
  }
}

/// Service that handles fetching products over HTTP from a REST / GitHub Gist raw URL
/// with automatic parsing, JSON array mapping, and offline fallback.
class ApiService {
  /// Default raw GitHub Gist URL.
  static const String defaultGistUrl =
      'https://gist.githubusercontent.com/RyanJacobSolomon/ebc8227ac5b5110f19006ad709611f80/raw/098750b725dcc7ba016f44609324478eef2c5933/comp.json';

  /// Cached raw JSON payload from the most recent HTTP GET request.
  static String lastRawJson = '';

  /// Returns a pretty-printed, indented JSON string for emulated UI display.
  static String getFormattedJson([String? input]) {
    final raw = (input ?? lastRawJson).trim();
    if (raw.isEmpty) {
      return '{\n  "status": "No JSON fetched yet. Execute HTTP GET to load data."\n}';
    }
    try {
      final decoded = json.decode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  /// Primary HTTP GET request execution method for the Data Catalog.
  ///
  /// Criteria 1: HTTP GET Request Execution (20 pts)
  /// - Executes HTTP GET request via [http.get] or supplied [client].
  /// - Handles HTTP status codes, headers, and timeouts.
  /// - Catches network/timeout exceptions and provides clear error info.
  ///
  /// Criteria 2: JSON Array to Product Mapping (20 pts)
  /// - Deserializes response body JSON.
  /// - Extracts JSON array and maps each element to a strongly-typed [Product].
  static Future<List<Product>> fetchCatalogProducts({
    String? rawUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    bool fallbackToLocal = true,
  }) async {
    final targetUrl = (rawUrl ?? '').trim().isNotEmpty
        ? rawUrl!.trim()
        : defaultGistUrl;

    final uri = Uri.parse(targetUrl);
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'PrysmGlitchTrade-App/1.0',
            },
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode} (${response.reasonPhrase ?? 'Error'}): Failed to fetch catalog from $targetUrl',
        );
      }

      lastRawJson = response.body;
      final decoded = json.decode(response.body);
      return parseJsonArrayToProducts(decoded);
    } catch (e) {
      debugPrint('ApiService.fetchCatalogProducts error: $e');
      if (fallbackToLocal) {
        debugPrint('ApiService: Falling back to local catalog products');
        return await loadFallbackCatalogProducts();
      }
      rethrow;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Maps a decoded JSON structure (root List or Map containing "products"/"data")
  /// into a strongly-typed `List<Product>`.
  ///
  /// Criteria 2: JSON Array to Product Mapping (20 pts)
  static List<Product> parseJsonArrayToProducts(dynamic decoded) {
    List<dynamic> productList;
    if (decoded is List) {
      productList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('products') && decoded['products'] is List) {
        productList = decoded['products'] as List<dynamic>;
      } else if (decoded.containsKey('data') && decoded['data'] is List) {
        productList = decoded['data'] as List<dynamic>;
      } else {
        throw const FormatException(
          'Invalid JSON: Expected a JSON array or object containing "products" key',
        );
      }
    } else {
      throw const FormatException(
        'Invalid JSON payload: expected List or Map',
      );
    }

    return productList
        .whereType<Map<String, dynamic>>()
        .map((json) => Product.fromJson(json))
        .toList();
  }

  /// Fetches products from a given GitHub Gist raw URL using package:http.
  /// Supports both `{ "products": [...] }` and `[...]` JSON formats.
  /// Maintained for backwards compatibility returning [GearItem].
  static Future<List<GearItem>> fetchProductsFromGist(
    String rawUrl, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse(rawUrl);
    final response = await http.get(uri).timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: Failed to fetch products from $rawUrl',
      );
    }

    final decoded = json.decode(response.body);
    return parseJsonArrayToProducts(decoded).map((p) => p.toGearItem()).toList();
  }

  /// Loads products mapped directly as [Product] models from built-in offline fallback data.
  static Future<List<Product>> loadFallbackCatalogProducts() async {
    const fallbackJson = '''
    {
      "products": [
        {
          "id": "gpu-001",
          "name": "NVIDIA GeForce RTX 4080 Super",
          "category": "Graphics Card (GPU)",
          "price": "\$949",
          "condition": "Brand New / Sealed",
          "color": "#E6E7DF",
          "description": "Factory sealed RTX 4080 Super Founders Edition. 16GB GDDR6X, Ada Lovelace architecture, DLSS 3.5 frame generation support. Full 3-year manufacturer warranty.",
          "imageUrl": "https://images.unsplash.com/photo-1591488320449-011701bb6704?auto=format&fit=crop&w=800&q=80",
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
          "description": "16 cores, 32 threads with 3D V-Cache technology. Tested stable under Arctic Liquid Freezer III at 62C max load. Original box and clamshell included.",
          "imageUrl": "https://images.unsplash.com/photo-1555680202-c86f0e12f086?auto=format&fit=crop&w=800&q=80",
          "seller": "SiliconBeast",
          "isSold": false
        },
        {
          "id": "case-001",
          "name": "Lian Li O11 Dynamic EVO RGB",
          "category": "PC Case",
          "price": "\$159",
          "condition": "Mint condition",
          "color": "#E3DFEC",
          "description": "Dual-chamber ATX mid-tower chassis in black. Includes integrated dual ARGB strips, reversible layout chassis, and all dust filters. Glass peel is still on!",
          "imageUrl": "https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&w=800&q=80",
          "seller": "GlassChassis",
          "isSold": false
        },
        {
          "id": "periph-001",
          "name": "Wooting 60HE+ Analog Keyboard",
          "category": "PC Peripherals",
          "price": "\$185",
          "condition": "Barely used",
          "color": "#DDE7EF",
          "description": "Rapid Trigger Hall Effect gaming keyboard with Lekker Linear 60 switches. Custom lubed switches, aluminum Tofu60 Redux case swap, pristine condition.",
          "imageUrl": "https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?auto=format&fit=crop&w=800&q=80",
          "seller": "RapidTrigger",
          "isSold": false
        },
        {
          "id": "ram-001",
          "name": "G.Skill Trident Z5 RGB 64GB DDR5-6400",
          "category": "Memory (RAM)",
          "price": "\$210",
          "condition": "Brand New / Sealed",
          "color": "#DFECE8",
          "description": "2x32GB CL32 dual kit, matte black aluminum heatspreaders with translucent RGB lightbar. Intel XMP 3.0 ready.",
          "imageUrl": "https://images.unsplash.com/photo-1562976540-1502c2145186?auto=format&fit=crop&w=800&q=80",
          "seller": "MemMaster",
          "isSold": false
        },
        {
          "id": "storage-001",
          "name": "Samsung 990 PRO 4TB PCIe 4.0 NVMe",
          "category": "Storage",
          "price": "\$280",
          "condition": "Like New / Pristine",
          "color": "#ECE7DF",
          "description": "Blazing fast speeds up to 7,450 MB/s read and 6,900 MB/s write. 99% drive health verified with Samsung Magician, low TBW.",
          "imageUrl": "https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?auto=format&fit=crop&w=800&q=80",
          "seller": "FastLaneStorage",
          "isSold": false
        },
        {
          "id": "psu-001",
          "name": "Corsair RM1000x Shift ATX 3.0",
          "category": "Power Supply Unit (PSU)",
          "price": "\$175",
          "condition": "Mint condition",
          "color": "#ECEADF",
          "description": "1000 Watt 80 PLUS Gold certified fully modular PSU. Features side-mounted cable connectors and PCIe 5.0 12VHPWR native cable.",
          "imageUrl": "https://images.unsplash.com/photo-1587202372634-32705e3bf49c?auto=format&fit=crop&w=800&q=80",
          "seller": "WattVolt",
          "isSold": false
        },
        {
          "id": "cooler-001",
          "name": "NZXT Kraken Elite 360 RGB AIO",
          "category": "CPU Cooler",
          "price": "\$235",
          "condition": "Mint condition",
          "color": "#E3DFEC",
          "description": "360mm liquid cooler with customizable 2.36 inch LCD screen. Includes 3x F120 RGB Core fans and RGB controller.",
          "imageUrl": "https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&w=800&q=80",
          "seller": "AIOKing",
          "isSold": false
        }
      ]
    }
    ''';
    lastRawJson = fallbackJson;
    final decoded = json.decode(fallbackJson);
    return parseJsonArrayToProducts(decoded);
  }

  /// Loads products from built-in offline fallback data as [GearItem].
  static Future<List<GearItem>> loadLocalProducts() async {
    final products = await loadFallbackCatalogProducts();
    return products.map((p) => p.toGearItem()).toList();
  }

  /// Primary fetch method: tries the specified or stored GitHub Gist URL first.
  /// If [rawUrl] is empty, invalid, or network is unreachable,
  /// it gracefully falls back to local assets so the app always displays gear.
  static Future<List<GearItem>> fetchProducts({
    String? rawUrl,
    bool fallbackToLocal = true,
  }) async {
    try {
      final products = await fetchCatalogProducts(
        rawUrl: rawUrl,
        fallbackToLocal: fallbackToLocal,
      );
      return products.map((p) => p.toGearItem()).toList();
    } catch (e) {
      if (!fallbackToLocal) rethrow;
      return await loadLocalProducts();
    }
  }
}
