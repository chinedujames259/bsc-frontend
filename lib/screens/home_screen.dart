import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/stats_provider.dart';
import '../models/stats.dart';
import 'add_category_screen.dart';
import 'add_product_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';
import 'products_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CategoryProvider>().fetchCategories();
      context.read<ProductProvider>().fetchProducts();
      context.read<StatsProvider>().fetchStats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Clear search query when switching away from search tab
      if (index != 1) {
        _searchQuery = null;
      }
      // Clear search when switching to orders tab
      if (index == 2) {
        _searchQuery = null;
      }
    });
  }

  void _navigateToSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _selectedIndex = 1;
    });
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage(
          searchController: _searchController,
          onSearchSubmitted: _navigateToSearch,
        );
      case 1:
        return SearchPage(initialQuery: _searchQuery);
      case 2:
        return const OrdersScreen();
      case 3:
        return const ProfilePage();
      default:
        return HomePage(
          searchController: _searchController,
          onSearchSubmitted: _navigateToSearch,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 || _selectedIndex == 2
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(_selectedIndex == 1 ? 'Search' : 'Profile'),
            ),
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.teal),
              title: const Text('Add Product'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
                if (result == true && mounted) {
                  context.read<ProductProvider>().fetchProducts();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.teal),
              title: const Text('Add Category'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCategoryScreen(),
                  ),
                );
                if (result == true && mounted) {
                  context.read<CategoryProvider>().fetchCategories();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String)? onSearchSubmitted;

  const HomePage({
    super.key,
    required this.searchController,
    this.onSearchSubmitted,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final user = authProvider.user;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          categoryProvider.fetchCategories(),
          productProvider.fetchProducts(),
          context.read<StatsProvider>().fetchStats(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Hello, ${user?.name.split(' ').first ?? "User"}!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.teal, Colors.teal.shade300],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: widget.searchController,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty &&
                      widget.onSearchSubmitted != null) {
                    widget.onSearchSubmitted!(value.trim());
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            widget.searchController.clear();
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildStatsSection(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (categoryProvider.categories.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CategoriesScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'See All',
                        style: TextStyle(fontSize: 14, color: Colors.teal),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (categoryProvider.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (categoryProvider.categories.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.category,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No categories yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddCategoryScreen(),
                            ),
                          );
                          if (result == true && context.mounted) {
                            context.read<CategoryProvider>().fetchCategories();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categoryProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = categoryProvider.categories[index];
                    final colors = [
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.green,
                      Colors.brown,
                      Colors.purple,
                    ];
                    final color = colors[index % colors.length];

                    return CategoryCard(label: category.name, color: color);
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (productProvider.products.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'See All',
                        style: TextStyle(fontSize: 14, color: Colors.teal),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (productProvider.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (productProvider.products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No products yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddProductScreen(),
                            ),
                          );
                          if (result == true && context.mounted) {
                            context.read<ProductProvider>().fetchProducts();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = productProvider.products[index];
                  return ProductCard(product: product);
                }, childCount: productProvider.products.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final statsProvider = context.watch<StatsProvider>();
    final stats = statsProvider.stats;

    if (statsProvider.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.shopping_bag,
                label: 'Products',
                value: stats.totalProducts.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.category,
                label: 'Categories',
                value: stats.totalCategories.toString(),
                color: Colors.green,
              ),
            ),
            if (stats.ordersByStatus.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long,
                  label: 'Orders',
                  value: stats.ordersByStatus
                      .fold<int>(0, (sum, item) => sum + item.count)
                      .toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.teal.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₦',
                  style: TextStyle(fontSize: 20, color: Colors.teal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₦${stats.revenue.overallTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total Revenue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (stats.ordersByStatus.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: stats.ordersByStatus.map((orderStatus) {
              final revenue = _getRevenueForStatus(
                stats.revenue,
                orderStatus.status,
              );
              return _CompactStatusChip(
                status: orderStatus.status,
                count: orderStatus.count,
                color: _getStatusColor(orderStatus.status),
                revenue: revenue,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _getRevenueForStatus(RevenueStats revenue, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return revenue.pendingTotal;
      case 'shipped':
        return revenue.shippedTotal;
      case 'completed':
        return revenue.completedTotal;
      case 'cancelled':
        return revenue.cancelledTotal;
      default:
        return 0.0;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CompactStatusChip extends StatelessWidget {
  final String status;
  final int count;
  final Color color;
  final double revenue;

  const _CompactStatusChip({
    required this.status,
    required this.count,
    required this.color,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (revenue > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₦${revenue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String label;
  final Color color;

  const CategoryCard({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.darken(15),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final dynamic product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          ).then((deleted) {
            if (deleted == true && context.mounted) {
              context.read<ProductProvider>().fetchProducts();
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: product.primaryImageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          product.primaryImageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.shopping_bag,
                                size: 48,
                                color: Colors.teal.shade200,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.shopping_bag,
                          size: 48,
                          color: Colors.teal.shade200,
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stock: ${product.stockCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.price != null
                                    ? '₦${product.price}'
                                    : 'No price',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: product.price != null
                                      ? Colors.teal
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _currentQuery = widget.initialQuery!;
      _hasSearched = true;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _currentQuery = query.trim();
      _hasSearched = true;
    });

    context.read<ProductProvider>().searchProducts(query: query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: widget.initialQuery == null,
                onSubmitted: _performSearch,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search for products...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _hasSearched = false;
                              _currentQuery = '';
                            });
                            productProvider.searchProducts(query: '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.transparent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildSearchResults(context, productProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a product name, SKU, or description',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (productProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error searching products',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              productProvider.error!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _performSearch(_currentQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (productProvider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => productProvider.searchProducts(query: _currentQuery),
      child: CustomScrollView(
        slivers: [
          if (_currentQuery.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Found ${productProvider.products.length} result${productProvider.products.length == 1 ? '' : 's'} for "$_currentQuery"',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = productProvider.products[index];
                return ProductCard(product: product);
              }, childCount: productProvider.products.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.deepPurple,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user?.name ?? 'Unknown',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          _buildProfileOption(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildProfileOption(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'My Products',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductsScreen()),
              );
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.category_outlined,
            title: 'My Categories',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await authProvider.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * value).round(),
      (green * value).round(),
      (blue * value).round(),
    );
  }
}
