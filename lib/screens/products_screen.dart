import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('All Products')),
      body: RefreshIndicator(
        onRefresh: () => productProvider.fetchProducts(),
        child: _buildBody(context, productProvider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProductProvider productProvider) {
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
              'Error loading products',
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
              onPressed: () => productProvider.fetchProducts(),
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
            Icon(Icons.shopping_bag, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: _FiltersPanel(productProvider: productProvider),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = productProvider.products[index];
              return _ProductCard(product: product);
            }, childCount: productProvider.products.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;

  const _ProductCard({required this.product});

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
                          color: Colors.tealAccent.shade200,
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

class _FiltersPanel extends StatelessWidget {
  final ProductProvider productProvider;

  const _FiltersPanel({required this.productProvider});

  @override
  Widget build(BuildContext context) {
    final stockStatusValue = productProvider.stockStatus ?? 'all';
    final orderByValue = productProvider.orderBy;
    final orderDirectionValue = productProvider.orderDirection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: stockStatusValue,
                decoration: const InputDecoration(
                  labelText: 'Stock filter',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('All stock levels'),
                  ),
                  DropdownMenuItem(value: 'in_stock', child: Text('In stock')),
                  DropdownMenuItem(
                    value: 'low_stock',
                    child: Text('Low stock'),
                  ),
                  DropdownMenuItem(
                    value: 'out_of_stock',
                    child: Text('Out of stock'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  productProvider.fetchProducts(stockStatus: value);
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: orderByValue,
                decoration: const InputDecoration(
                  labelText: 'Order by',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'createdAt',
                    child: Text('Created date'),
                  ),
                  DropdownMenuItem(
                    value: 'stockCount',
                    child: Text('Stock count'),
                  ),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  productProvider.fetchProducts(orderBy: value);
                },
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                value: orderDirectionValue,
                decoration: const InputDecoration(
                  labelText: 'Order direction',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  productProvider.fetchProducts(orderDirection: value);
                },
              ),
            ),
          ],
        ),
        if (stockStatusValue == 'low_stock')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showThresholdDialog(context),
                icon: const Icon(Icons.tune, size: 18),
                label: Text(
                  'Threshold: ${productProvider.lowStockThreshold}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showThresholdDialog(BuildContext context) {
    final controller = TextEditingController(
      text: productProvider.lowStockThreshold.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low stock threshold'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter minimum stock count',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed == null || parsed <= 0) {
                Navigator.pop(context);
                return;
              }
              productProvider.fetchProducts(lowStockThreshold: parsed);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
