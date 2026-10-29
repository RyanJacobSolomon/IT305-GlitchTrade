import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';
import 'data_catalog_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const List<String> categories = [
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
  ];

  static bool matchesCategory(GearItem item, String category) {
    final catLower = category.trim().toLowerCase();
    if (catLower == 'all gear') return true;

    final itemCatLower = item.category.trim().toLowerCase();
    if (itemCatLower == catLower) return true;

    String normalize(String cat) {
      final c = cat.trim().toLowerCase();
      if (c == 'gpu' || c == 'graphics card (gpu)' || c == 'graphics cards (gpu)') {
        return 'gpu';
      }
      if (c == 'cpu' || c == 'processor (cpu)' || c == 'processors (cpu)') {
        return 'cpu';
      }
      if (c == 'peripherals' || c == 'pc peripherals') {
        return 'peripherals';
      }
      if (c == 'ram' || c == 'memory (ram)' || c == 'memory') {
        return 'ram';
      }
      if (c == 'psu' || c == 'power supply unit (psu)' || c == 'power supply') {
        return 'psu';
      }
      if (c == 'motherboard' || c == 'motherboards' || c == 'mobo') {
        return 'motherboard';
      }
      if (c == 'storage' || c == 'ssd' || c == 'hdd' || c == 'nvme') {
        return 'storage';
      }
      if (c == 'cpu cooler' || c == 'cooler' || c == 'coolers' || c == 'aio') {
        return 'cpu cooler';
      }
      if (c == 'pc case' || c == 'case' || c == 'cases' || c == 'chassis') {
        return 'pc case';
      }
      if (c == 'operating system' || c == 'os' || c == 'windows') {
        return 'operating system';
      }
      if (c == 'display' || c == 'displays' || c == 'monitor' || c == 'monitors') {
        return 'display';
      }
      return c;
    }

    return normalize(item.category) == normalize(category);
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class GearItem {
  GearItem({
    required this.name,
    required this.category,
    required this.price,
    required this.condition,
    required this.color,
    required this.icon,
    this.images = const [],
    this.imageUrl,
    this.description = '',
    this.isSold = false,
  });

  String name;
  String category;
  String price;
  String condition;
  Color color;
  IconData icon;
  List<Uint8List> images;
  String? imageUrl;
  String description;
  bool isSold;
}

class _ListingFormData {
  _ListingFormData({
    required this.name,
    required this.category,
    required this.price,
    required this.condition,
    required this.description,
    required this.images,
  });

  final String name;
  final String category;
  final String price;
  final String condition;
  final String description;
  final List<Uint8List> images;
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  String _category = 'All Gear';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<GearItem> _items = [
    GearItem(
      name: 'RTX 3080 FE',
      category: 'GPU',
      price: '\$420',
      condition: 'Mint condition',
      color: const Color(0xFFE6E7DF),
      icon: Icons.view_in_ar_rounded,
      description:
          'Founders Edition card in mint shape. Never used for mining, kept cool in a mesh case. Original box included.',
    ),
    GearItem(
      name: 'Keychron Q1 Pro',
      category: 'Peripherals',
      price: '\$145',
      condition: 'Barely used',
      color: const Color(0xFFDDE7EF),
      icon: Icons.keyboard_rounded,
      description:
          'Wireless custom mechanical keyboard, fully assembled with Banana switches and PBT keycaps.',
    ),
    GearItem(
      name: 'Ryzen 7 7800X3D',
      category: 'CPU',
      price: '\$285',
      condition: 'Boxed + receipt',
      color: const Color(0xFFE8E1D7),
      icon: Icons.memory_rounded,
      description:
          'Best gaming processor on AM5. Bought 4 months ago at Micro Center, receipt included for warranty.',
    ),
  ];

  bool _isFetchingApi = false;
  String _gistUrl = ApiService.defaultGistUrl;
  late final TextEditingController _gistUrlController;

  @override
  void initState() {
    super.initState();
    _gistUrlController = TextEditingController(text: _gistUrl);
    final isTesting =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTesting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductsFromApi();
      });
    }
  }

  Future<void> _loadProductsFromApi({bool showToast = false}) async {
    if (_isFetchingApi) return;
    setState(() => _isFetchingApi = true);
    try {
      final fetched = await ApiService.fetchProducts(
        rawUrl: _gistUrl,
        fallbackToLocal: true,
      );
      if (mounted && fetched.isNotEmpty) {
        setState(() {
          final existingNames = _items.map((e) => e.name.toLowerCase()).toSet();
          for (final item in fetched) {
            if (!existingNames.contains(item.name.toLowerCase())) {
              _items.add(item);
              existingNames.add(item.name.toLowerCase());
            }
          }
        });
        if (showToast && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synced ${fetched.length} products from Gist / API'),
              backgroundColor: const Color(0xFF00D9FF),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingApi = false);
    }
  }

  void _showGistConfigDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: Color(0xFF00D9FF)),
            SizedBox(width: 10),
            Text(
              'Gist API Source',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your GitHub Gist raw URL to fetch and display products dynamically via http:',
              style: TextStyle(color: Color(0xFFAAB8CC), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _gistUrlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Raw Gist URL',
                labelStyle: const TextStyle(color: Color(0xFF00D9FF)),
                hintText: 'https://gist.githubusercontent.com/.../raw/products.json',
                hintStyle: const TextStyle(color: Color(0xFF6B7E96), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF162238),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF283548)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF283548)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Leave default to load from local asset/products.json or your published gist.',
              style: TextStyle(color: Color(0xFF6B7E96), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: const Color(0xFF070B18),
            ),
            onPressed: () {
              setState(() {
                _gistUrl = _gistUrlController.text.trim();
              });
              Navigator.pop(dialogContext);
              _loadProductsFromApi(showToast: true);
            },
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text(
              'FETCH NOW',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gistUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12.0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: Image.asset(
          'asset/ic_prysm_logo.png',
          height: 38,
          fit: BoxFit.contain,
          semanticLabel: 'Prysm Glitch Trade logo',
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Gist / API',
            onPressed: _showGistConfigDialog,
            icon: _isFetchingApi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00D9FF),
                    ),
                  )
                : const Icon(Icons.cloud_sync_outlined),
          ),
          IconButton(
            tooltip: 'Messages',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Messages clicked')),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          IconButton(
            key: const Key('appbar_catalog_button'),
            tooltip: 'Data Catalog',
            onPressed: () => setState(() => _tab = 1),
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => setState(() => _tab = 3),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          Navigator.pop(context);
          setState(() => _tab = index);
        },
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            color: const Color(0xFF0F172A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF00D9FF),
                  child: Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: Color(0xFF070B18),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? 'Trader Guest',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Verified Hardware Trader',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAAB8CC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const NavigationDrawerDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: Text('Dashboard'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.inventory_2_rounded),
            label: Text('Data Catalog (HTTP API)'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: Text('Saved Gear'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: Text('Profile'),
          ),
          const Divider(indent: 16, endIndent: 16, height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.view_in_ar_rounded, color: Color(0xFF00D9FF)),
            title: const Text('Graphics Cards (GPU)'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _tab = 0;
                _category = 'Graphics Card (GPU)';
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.memory_rounded, color: Color(0xFF00D9FF)),
            title: const Text('Processors (CPU)'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _tab = 0;
                _category = 'Processor (CPU)';
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.keyboard_rounded, color: Color(0xFF00D9FF)),
            title: const Text('Peripherals'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _tab = 0;
                _category = 'PC Peripherals';
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.monitor_rounded, color: Color(0xFF00D9FF)),
            title: const Text('Displays'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _tab = 0;
                _category = 'Display';
              });
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 28),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              Navigator.pop(context);
              await _signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _dashboard(),
          const DataCatalogPage(isEmbedded: true),
          Center(
            child: Text(
              'Saved gear',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          _profile(user),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              key: const Key('list_item_fab'),
              onPressed: () => _showGearForm(),
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: const Color(0xFF070B18),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'LIST ITEM',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final categories = HomePage.categories;
    final visibleItems = _items.where((item) {
      final matchesCat = HomePage.matchesCategory(item, _category);
      if (!matchesCat) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.condition.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _loadProductsFromApi(showToast: true),
      color: const Color(0xFF00D9FF),
      backgroundColor: const Color(0xFF111A2E),
      child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
      children: [
        const Text(
          'Find your next\nupgrade.',
          style: TextStyle(
            fontSize: 36,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Color(0xFFE7EDF5),
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          key: const Key('dashboard_catalog_banner'),
          onTap: () => setState(() => _tab = 1),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F243A), Color(0xFF162238)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF00D9FF), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Live Data Catalog',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFF00D9FF), size: 13),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Browse products via HTTP GET REST API',
                        style: TextStyle(fontSize: 11, color: Color(0xFFAAB8CC)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Color(0xFF070B18)),
          decoration: InputDecoration(
            hintText: 'Search GPUs, builds, gear...',
            hintStyle: const TextStyle(color: Color(0xFF7A8B9E)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4B5D75)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF4B5D75)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded, color: Color(0xFF4B5D75)),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _CategoryFilterBar(
          categories: categories,
          selectedCategory: _category,
          onSelected: (category) => setState(() => _category = category),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fresh on the bench',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _category = 'All Gear';
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (visibleItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No gear matches "$_searchQuery"'
                        : 'No gear listed in this category.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...visibleItems.map(
            (item) => _GearCard(
              item: item,
              onEdit: () => _showGearForm(item: item),
              onDelete: () => _deleteGear(item),
              onToggleSold: () => _toggleSold(item),
              onTap: () => _showItemDetails(item),
            ),
          ),
      ],
    ),
  );
  }

  Future<void> _showGearForm({GearItem? item}) async {
    final formData = await showModalBottomSheet<_ListingFormData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111A2E),
      barrierColor: Colors.black.withValues(alpha: 0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _GearFormSheet(item: item),
      ),
    );

    if (formData == null || !mounted) return;

    setState(() {
      if (item == null) {
        final newItem = GearItem(
          name: formData.name,
          category: formData.category,
          price: formData.price,
          condition: formData.condition,
          description: formData.description,
          color: _colorForCategory(formData.category),
          icon: _iconForCategory(formData.category),
          images: formData.images,
          isSold: false,
        );
        _items.insert(0, newItem);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing "${newItem.name}" added to the bench!'),
            backgroundColor: const Color(0xFF00D9FF),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        item
          ..name = formData.name
          ..category = formData.category
          ..price = formData.price
          ..condition = formData.condition
          ..description = formData.description
          ..icon = _iconForCategory(formData.category)
          ..images = formData.images;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing "${item.name}" updated!'),
            backgroundColor: const Color(0xFF00D9FF),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _toggleSold(GearItem item) {
    setState(() {
      item.isSold = !item.isSold;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isSold
              ? '"${item.name}" marked as sold'
              : '"${item.name}" marked as available',
        ),
        backgroundColor: item.isSold
            ? const Color(0xFFD800FF)
            : const Color(0xFF00D9FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteGear(GearItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete listing?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${item.name}" from your listings? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFFAAB8CC), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final itemName = item.name;
      setState(() => _items.remove(item));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Listing "$itemName" deleted'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showItemDetails(GearItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111A2E),
      barrierColor: Colors.black.withValues(alpha: 0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (item.images.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: item.images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        item.images[index],
                        width: 260,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(item.icon, size: 52, color: const Color(0xFF17212B)),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(item.icon, size: 52, color: const Color(0xFF17212B)),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162238),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00D9FF),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (item.isSold) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD800FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SOLD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    item.price,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: item.isSold
                          ? const Color(0xFF8E9BAE)
                          : Colors.white,
                      decoration: item.isSold
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: Color(0xFFAAB8CC),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.condition,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFAAB8CC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (item.description.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7E96),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFDDE5F0),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00D9FF),
                        side: const BorderSide(color: Color(0xFF00D9FF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showGearForm(item: item);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'EDIT LISTING',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: item.isSold
                            ? const Color(0xFF00D9FF)
                            : const Color(0xFFD800FF),
                        foregroundColor: item.isSold
                            ? const Color(0xFF070B18)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _toggleSold(item);
                      },
                      icon: Icon(
                        item.isSold
                            ? Icons.replay_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        item.isSold ? 'MARK AVAILABLE' : 'MARK AS SOLD',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) => switch (category) {
    'GPU' || 'Graphics Card (GPU)' => Icons.view_in_ar_rounded,
    'CPU' || 'Processor (CPU)' => Icons.memory_rounded,
    'Peripherals' || 'PC Peripherals' => Icons.keyboard_rounded,
    'Motherboard' => Icons.developer_board_rounded,
    'RAM' || 'Memory (RAM)' => Icons.straighten_rounded,
    'Storage' => Icons.storage_rounded,
    'PSU' || 'Power Supply Unit (PSU)' => Icons.bolt_rounded,
    'CPU Cooler' => Icons.ac_unit_rounded,
    'PC Case' => Icons.computer_rounded,
    'Operating System' => Icons.terminal_rounded,
    'Display' || 'Displays' => Icons.monitor_rounded,
    _ => Icons.devices_other_rounded,
  };

  Color _colorForCategory(String category) => switch (category) {
    'GPU' || 'Graphics Card (GPU)' => const Color(0xFFE6E7DF),
    'Peripherals' || 'PC Peripherals' => const Color(0xFFDDE7EF),
    'CPU' || 'Processor (CPU)' => const Color(0xFFE8E1D7),
    'Motherboard' => const Color(0xFFE2DFEC),
    'RAM' || 'Memory (RAM)' => const Color(0xFFDFECE8),
    'Storage' => const Color(0xFFECE7DF),
    'PSU' || 'Power Supply Unit (PSU)' => const Color(0xFFECEADF),
    'CPU Cooler' => const Color(0xFFDFECED),
    'PC Case' => const Color(0xFFE3DFEC),
    'Operating System' => const Color(0xFFDFE8EC),
    'Display' || 'Displays' => const Color(0xFFDFE6E8),
    _ => const Color(0xFFE2E4EC),
  };

  Widget _profile(User? user) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.account_circle_rounded,
          size: 72,
          color: Color(0xFF17212B),
        ),
        const SizedBox(height: 14),
        Text(
          user?.email ?? 'Your profile',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('SIGN OUT'),
        ),
      ],
    ),
  );
}

class _CategoryFilterBar extends StatefulWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  State<_CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<_CategoryFilterBar> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final canLeft = currentScroll > 4;
    final canRight = currentScroll < (maxScroll - 4);
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          if (bounds.width <= 0) {
            return const LinearGradient(colors: [Colors.white, Colors.white])
                .createShader(bounds);
          }
          final leftStop = (18.0 / bounds.width).clamp(0.0, 0.2);
          final rightStop = ((bounds.width - 18.0) / bounds.width).clamp(0.8, 1.0);

          final colors = <Color>[
            _canScrollLeft ? Colors.transparent : Colors.white,
            Colors.white,
            Colors.white,
            _canScrollRight ? Colors.transparent : Colors.white,
          ];
          final stops = <double>[
            0.0,
            _canScrollLeft ? leftStop : 0.0,
            _canScrollRight ? rightStop : 1.0,
            1.0,
          ];
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: colors,
            stops: stops,
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          key: const Key('category_filter_list'),
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: 16),
          itemCount: widget.categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final category = widget.categories[index];
            final isSelected = widget.selectedCategory == category;
            return _CategoryChip(
              key: Key('category_chip_${category.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}'),
              category: category,
              isSelected: isSelected,
              onTap: () => widget.onSelected(category),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const unselectedBg = Color(0xFF1A2332);
    const unselectedBorder = Color(0xFF283548);
    const unselectedText = Color(0xFFCAD5E2);

    const selectedBg = Color(0xFF5A7D6E);
    const selectedBorder = Color(0xFF6E9483);
    const selectedText = Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? selectedBorder : unselectedBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedText : unselectedText,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GearFormSheet extends StatefulWidget {
  const _GearFormSheet({this.item});

  final GearItem? item;

  @override
  State<_GearFormSheet> createState() => _GearFormSheetState();
}

class _GearFormSheetState extends State<_GearFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _conditionController;
  late final TextEditingController _descriptionController;
  late String _category;
  late final List<Uint8List> _images;
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final List<String> _conditionSuggestions = const [
    'Mint condition',
    'Barely used',
    'Boxed + receipt',
    'Brand new / Sealed',
    'Good condition',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(
      text: widget.item != null
          ? widget.item!.price.replaceAll(r'$', '').trim()
          : '',
    );
    _conditionController = TextEditingController(
      text: widget.item?.condition ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.item?.description ?? '',
    );
    _category = widget.item?.category ?? 'Graphics Card (GPU)';
    _images = <Uint8List>[...?widget.item?.images];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _conditionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFAAB8CC), fontSize: 13),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF455870), fontSize: 13),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: Color(0xFF00D9FF),
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      filled: true,
      fillColor: const Color(0xFF0A1020),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E2B45)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E2B45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final rawPrice = _priceController.text.replaceAll(r'$', '').trim();
    final numPrice = double.tryParse(rawPrice);
    final formattedPrice = (numPrice != null && numPrice % 1 == 0)
        ? '\$${numPrice.toInt()}'
        : '\$$rawPrice';

    final result = _ListingFormData(
      name: _nameController.text.trim(),
      category: _category,
      price: formattedPrice,
      condition: _conditionController.text.trim(),
      description: _descriptionController.text.trim(),
      images: _images,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item == null ? 'Create Listing' : 'Edit Listing',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item == null
                          ? 'List your PC hardware on the bench'
                          : 'Update your hardware listing details',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAAB8CC),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E2B45)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _images.isEmpty
                              ? 'PHOTOS'
                              : 'PHOTOS (${_images.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFAAB8CC),
                            letterSpacing: 1.1,
                          ),
                        ),
                        if (_images.isNotEmpty)
                          Text(
                            'Tap "Upload" to add more',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == _images.length) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                try {
                                  final pickedImages = await _imagePicker
                                      .pickMultiImage(imageQuality: 85);
                                  if (pickedImages.isNotEmpty) {
                                    final bytes = await Future.wait(
                                      pickedImages.map(
                                        (img) => img.readAsBytes(),
                                      ),
                                    );
                                    setState(() => _images.addAll(bytes));
                                  }
                                } catch (e) {
                                  debugPrint('Photo picker error: $e');
                                }
                              },
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A1020),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF00D9FF)
                                        .withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 28,
                                      color: Color(0xFF00D9FF),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Upload',
                                      style: TextStyle(
                                        color: Color(0xFF00D9FF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _images[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D9FF),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'COVER',
                                      style: TextStyle(
                                        color: Color(0xFF070B18),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _images.removeAt(index),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.75),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Item Name Field
                    TextFormField(
                      key: const Key('name_field'),
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Item Name *',
                        hint: 'e.g. RTX 3080 FE, Ryzen 7 7800X3D',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an item name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      key: const Key('category_field'),
                      initialValue: _category,
                      dropdownColor: const Color(0xFF162238),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration(label: 'Category *'),
                      items: {
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
                        _category,
                      }
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Condition Field with quick chips
                    TextFormField(
                      key: const Key('condition_field'),
                      controller: _conditionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Condition *',
                        hint: 'e.g. Mint condition, Barely used',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter or select condition';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _conditionSuggestions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final chip = _conditionSuggestions[index];
                          final isSelected =
                              _conditionController.text.trim() == chip;
                          return ActionChip(
                            label: Text(
                              chip,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? const Color(0xFF070B18)
                                    : const Color(0xFFAAB8CC),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                            backgroundColor: isSelected
                                ? const Color(0xFF00D9FF)
                                : const Color(0xFF0A1020),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF00D9FF)
                                  : const Color(0xFF1E2B45),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            onPressed: () {
                              setState(() {
                                _conditionController.text = chip;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Field (Must be numeric)
                    TextFormField(
                      key: const Key('price_field'),
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Price (USD) *',
                        hint: '420 or 145.50',
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a price';
                        }
                        final clean = value.replaceAll(r'$', '').trim();
                        final parsed = double.tryParse(clean);
                        if (parsed == null) {
                          return 'Price must be numeric (e.g. 420 or 145.50)';
                        }
                        if (parsed <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field (Optional)
                    TextFormField(
                      key: const Key('description_field'),
                      controller: _descriptionController,
                      maxLines: 3,
                      minLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Description (optional)',
                        hint: 'Describe specs, warranty, reason for selling...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Color(0xFF1E2B45)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text('CANCEL'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            key: const Key('submit_listing_button'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00D9FF),
                              foregroundColor: const Color(0xFF070B18),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submit,
                            icon: Icon(
                              widget.item == null
                                  ? Icons.add_rounded
                                  : Icons.check_rounded,
                              size: 20,
                            ),
                            label: Text(
                              widget.item == null ? 'LIST ITEM' : 'SAVE CHANGES',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GearCard extends StatelessWidget {
  const _GearCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleSold,
    this.onTap,
  });

  final GearItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleSold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    elevation: 0,
    color: const Color(0xFF111A2E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: item.isSold
          ? BorderSide(
              color: const Color(0xFFD800FF).withValues(alpha: 0.4),
              width: 1,
            )
          : BorderSide.none,
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.images.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(item.images.first, fit: BoxFit.cover),
                          if (item.images.length > 1)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.images.length} photos',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : (item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              item.icon,
                              size: 42,
                              color: const Color(0xFF17212B),
                            ),
                          )
                        : Icon(
                            item.icon,
                            size: 42,
                            color: const Color(0xFF17212B),
                          )),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFAAB8CC),
                          letterSpacing: 1,
                        ),
                      ),
                      if (item.isSold) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD800FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOLD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.condition,
                    style: const TextStyle(
                      color: Color(0xFFAAB8CC),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: item.isSold
                        ? const Color(0xFF8E9BAE)
                        : Colors.white,
                    decoration: item.isSold
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                PopupMenuButton<String>(
                  tooltip: 'Manage listing',
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  color: const Color(0xFF162238),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'sold') onToggleSold();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF00D9FF)),
                          SizedBox(width: 10),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sold',
                      child: Row(
                        children: [
                          Icon(
                            item.isSold
                                ? Icons.replay_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                            color: const Color(0xFFD800FF),
                          ),
                          SizedBox(width: 10),
                          Text(
                            item.isSold ? 'Mark as available' : 'Mark as sold',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
