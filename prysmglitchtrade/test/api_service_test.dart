import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:prysmglitchtrade/services/api_service.dart';

void main() {
  group('ApiService & Product parsing tests', () {
    test('Product.fromJson parses all fields correctly', () {
      final jsonMap = {
        'id': 'test-gpu-01',
        'name': 'RTX 4070 Ti Super',
        'category': 'Graphics Card (GPU)',
        'price': '\$799',
        'condition': 'Mint condition',
        'color': '#00D9FF',
        'description': 'Super clean card with original box.',
        'imageUrl': 'https://images.unsplash.com/photo-1591488320449-011701bb6704',
        'seller': 'GhostTrader',
        'isSold': false,
      };

      final product = Product.fromJson(jsonMap);

      expect(product.id, 'test-gpu-01');
      expect(product.name, 'RTX 4070 Ti Super');
      expect(product.category, 'Graphics Card (GPU)');
      expect(product.price, '\$799');
      expect(product.imageUrl, 'https://images.unsplash.com/photo-1591488320449-011701bb6704');
      expect(product.seller, 'GhostTrader');
      expect(product.isSold, isFalse);

      final gearItem = product.toGearItem();
      expect(gearItem.name, 'RTX 4070 Ti Super');
      expect(gearItem.price, '\$799');
      expect(gearItem.imageUrl, product.imageUrl);
      expect(gearItem.isSold, isFalse);
    });

    test('Parses raw JSON string format matching GitHub Gist payload', () {
      const sampleJson = '''
      {
        "store": "Prysm Glitch Trade",
        "version": "1.0",
        "products": [
          {
            "id": "cpu-test",
            "name": "Ryzen 9 7900X",
            "category": "Processor (CPU)",
            "price": "\$360",
            "condition": "Like New",
            "color": "#E8E1D7",
            "description": "Fast 12-core AM5 CPU",
            "imageUrl": "https://example.com/cpu.jpg",
            "seller": "Viper",
            "isSold": false
          }
        ]
      }
      ''';

      final decoded = json.decode(sampleJson);
      final productsList = (decoded['products'] as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(productsList.length, 1);
      expect(productsList.first.name, 'Ryzen 9 7900X');
      expect(productsList.first.price, '\$360');
    });

    test('Fetches and parses live GitHub Gist URL', () async {
      final items = await ApiService.fetchProductsFromGist(ApiService.defaultGistUrl);
      expect(items, isNotEmpty);
      expect(items.length, greaterThanOrEqualTo(8));
      expect(items.any((item) => item.name.contains('RTX 4080 Super')), isTrue);
    });
  });
}
