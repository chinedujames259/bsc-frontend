import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<OrderProvider>().fetchOrderById(widget.orderId);
    });
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final orderProvider = context.read<OrderProvider>();

    try {
      await orderProvider.deleteOrder(widget.orderId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to delete order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleStatusUpdate(String newStatus) async {
    final orderProvider = context.read<OrderProvider>();
    final currentOrder = orderProvider.currentOrder;

    if (currentOrder == null || currentOrder.status == newStatus) return;

    try {
      await orderProvider.updateOrderStatus(widget.orderId, newStatus);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to update order status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusUpdateDialog() {
    final orderProvider = context.read<OrderProvider>();
    final currentOrder = orderProvider.currentOrder;
    if (currentOrder == null) return;

    final statuses = ['pending', 'shipped', 'completed', 'cancelled'];
    final currentStatus = currentOrder.status.toLowerCase();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isSelected = status == currentStatus;
            return RadioListTile<String>(
              title: Text(status.toUpperCase()),
              value: status,
              groupValue: currentStatus,
              onChanged: isSelected
                  ? null
                  : (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _handleStatusUpdate(value);
                      }
                    },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          if (order != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showStatusUpdateDialog,
              tooltip: 'Update Status',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _handleDelete,
              tooltip: 'Delete Order',
            ),
          ],
        ],
      ),
      body: _buildBody(context, orderProvider, order),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderProvider orderProvider,
    Order? order,
  ) {
    if (orderProvider.isLoading && order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.error != null && order == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading order',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              orderProvider.error!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                orderProvider.fetchOrderById(widget.orderId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (order == null) {
      return const Center(child: Text('Order not found'));
    }

    return RefreshIndicator(
      onRefresh: () => orderProvider.fetchOrderById(widget.orderId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(order),
              const SizedBox(height: 24),
              _buildStatusSection(order),
              const SizedBox(height: 24),
              _buildDetailsSection(order),
              const SizedBox(height: 24),
              _buildItemsSection(order),
              const SizedBox(height: 24),
              _buildTotalSection(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order #${order.id}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Created: ${_formatDateTime(order.createdAt)}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        if (order.updatedAt != order.createdAt) ...[
          const SizedBox(height: 4),
          Text(
            'Updated: ${_formatDateTime(order.updatedAt)}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusSection(Order order) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                order.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showStatusUpdateDialog,
            tooltip: 'Change Status',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Order ID', order.id.toString()),
          _buildDetailRow('User ID', order.userId.toString()),
          _buildDetailRow('Items Count', '${order.items.length}'),
          _buildDetailRow('Created', _formatDate(order.createdAt)),
          _buildDetailRow('Updated', _formatDate(order.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (order.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No items in this order',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ...order.items.map((item) => _buildOrderItemCard(item)),
      ],
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.product != null) ...[
              Text(
                item.product!.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${item.product!.sku}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ] else
              Text(
                'Product ID: ${item.productId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${item.price}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₦${(double.tryParse(item.price) ?? 0.0) * item.quantity}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '₦${order.total}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
