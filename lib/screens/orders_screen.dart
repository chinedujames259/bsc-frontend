import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isCreatingInvoice = false;
  bool _isCreatingOrder = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<InvoiceItem> _invoiceItems = [];
  bool _showSearchResults = false;
  List<Product> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    Future.microtask(() {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _showSearchResults = query.isNotEmpty && _searchFocusNode.hasFocus;
    });

    if (query.isNotEmpty) {
      _performSearch(query);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _startCreatingInvoice() {
    setState(() {
      _isCreatingInvoice = true;
      _isCreatingOrder = false;
      _invoiceItems.clear();
      _searchController.clear();
      _showSearchResults = false;
      _searchResults = [];
    });
  }

  void _cancelInvoice() {
    setState(() {
      _isCreatingInvoice = false;
      _isCreatingOrder = false;
      _invoiceItems.clear();
      _searchController.clear();
      _showSearchResults = false;
      _searchResults = [];
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final productProvider = context.read<ProductProvider>();
      await productProvider.searchProducts(query: query.trim());
      if (mounted) {
        setState(() {
          _searchResults = productProvider.products;
        });
      }
    } catch (e) {
      // Handle error silently or show message
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  void _addProductToInvoice(Product product) {
    if (product.price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product does not have a price. Cannot add to invoice.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      final existingIndex = _invoiceItems.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex >= 0) {
        _invoiceItems[existingIndex] = InvoiceItem(
          productId: _invoiceItems[existingIndex].productId,
          productName: _invoiceItems[existingIndex].productName,
          productSku: _invoiceItems[existingIndex].productSku,
          price: _invoiceItems[existingIndex].price,
          quantity: _invoiceItems[existingIndex].quantity + 1,
        );
      } else {
        _invoiceItems.add(
          InvoiceItem(
            productId: product.id,
            productName: product.name,
            productSku: product.sku,
            price: product.price,
            quantity: 1,
          ),
        );
      }

      // Clear search and hide overlay
      _searchController.clear();
      _searchFocusNode.unfocus();
      _showSearchResults = false;
      _searchResults = [];
    });
  }

  void _removeItemFromInvoice(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeItemFromInvoice(index);
      return;
    }
    setState(() {
      _invoiceItems[index] = InvoiceItem(
        productId: _invoiceItems[index].productId,
        productName: _invoiceItems[index].productName,
        productSku: _invoiceItems[index].productSku,
        price: _invoiceItems[index].price,
        quantity: quantity,
      );
    });
  }

  double _calculateTotal() {
    return _invoiceItems.fold<double>(0.0, (sum, item) => sum + item.total);
  }

  Future<void> _submitOrder() async {
    if (_invoiceItems.isEmpty || _isCreatingOrder) {
      return;
    }

    setState(() {
      _isCreatingOrder = true;
    });

    final orderProvider = context.read<OrderProvider>();
    final items = _invoiceItems.map((item) => item.toJson()).toList();

    try {
      await orderProvider.createOrder(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _cancelInvoice();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isCreatingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreatingInvoice) {
      return _buildInvoiceCreationView();
    }
    return _buildOrdersListView();
  }

  Widget _buildOrdersListView() {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => orderProvider.fetchOrders(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: const Text(
                    'Orders',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (orderProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (orderProvider.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            orderProvider.error!,
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => orderProvider.fetchOrders(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (orderProvider.orders.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No orders yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _startCreatingInvoice,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Invoice'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final order = orderProvider.orders[index];
                      return _OrderCard(order: order);
                    }, childCount: orderProvider.orders.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startCreatingInvoice,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }

  Widget _buildInvoiceCreationView() {
    return Scaffold(
      body: Stack(
        children: [
          // Main Invoice Content
          Column(
            children: [
              // Custom Header Bar
              Container(
                padding: const EdgeInsets.only(top: 8.0),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _cancelInvoice,
                      ),
                      const Expanded(
                        child: Text(
                          'Create Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the close button
                    ],
                  ),
                ),
              ),
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onTap: () {
                    setState(() {
                      _showSearchResults = _searchController.text.isNotEmpty;
                    });
                  },
                  onSubmitted: (value) {
                    // Don't submit, just add product if selected
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products to add...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _showSearchResults = false;
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.teal,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              // Invoice Items List
              Expanded(child: _buildInvoiceItemsList()),
              // Total and Submit Button
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₦${_calculateTotal().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_invoiceItems.isEmpty || _isCreatingOrder)
                            ? null
                            : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCreatingOrder
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Creating Order...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Create Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Search Results Overlay
          if (_showSearchResults && _searchController.text.isNotEmpty)
            _buildSearchResultsOverlay(),
        ],
      ),
    );
  }

  Widget _buildSearchResultsOverlay() {
    final productProvider = context.watch<ProductProvider>();

    return GestureDetector(
      onTap: () {
        // Allow tapping outside to close
        _searchFocusNode.unfocus();
        setState(() {
          _showSearchResults = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on overlay content
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                constraints: const BoxConstraints(
                  maxHeight: 400,
                  maxWidth: 500,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Colors.teal,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search Results',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _searchFocusNode.unfocus();
                              setState(() {
                                _showSearchResults = false;
                              });
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                    // Results List
                    Flexible(child: _buildSearchResultsList(productProvider)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(ProductProvider productProvider) {
    if (productProvider.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (productProvider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 8),
              Text(
                productProvider.error!,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'No products found',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different search term',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        final hasPrice = product.price != null;

        return InkWell(
          onTap: hasPrice ? () => _addProductToInvoice(product) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.primaryImageUrl != null
                      ? Image.network(
                          product.primaryImageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.shopping_bag,
                                color: Colors.grey,
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.shopping_bag,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: hasPrice ? Colors.black : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${product.sku}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (hasPrice)
                        Text(
                          '₦${product.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.teal,
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'No price',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Add Icon
                if (hasPrice)
                  const Icon(Icons.add_circle, color: Colors.teal, size: 24)
                else
                  const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.grey,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyInvoiceState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No items added',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search and add products to create an invoice',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItemsList() {
    if (_invoiceItems.isEmpty) {
      return _buildEmptyInvoiceState();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Invoice Items (${_invoiceItems.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _invoiceItems.isEmpty
              ? _buildEmptyInvoiceState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: _invoiceItems.length,
                  itemBuilder: (context, index) {
                    final item = _invoiceItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product name and delete button
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _removeItemFromInvoice(index),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (item.productSku != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${item.productSku}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Quantity and price row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Quantity controls
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _updateItemQuantity(
                                          index,
                                          item.quantity - 1,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: const Icon(
                                            Icons.remove,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.symmetric(
                                            vertical: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _updateItemQuantity(
                                          index,
                                          item.quantity + 1,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Price
                                Flexible(
                                  child: Text(
                                    '₦${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.teal,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: order.id),
            ),
          ).then((deleted) {
            if (deleted == true && context.mounted) {
              context.read<OrderProvider>().fetchOrders();
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(order.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(order.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ₦${order.total}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
