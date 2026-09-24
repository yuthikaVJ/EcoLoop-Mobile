import 'edit_transaction_page.dart';
import 'location_picker_page.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/component4_api_service.dart';
import '../../domain/entities/transaction_models.dart';
import '../widgets/status_badge.dart';
import '../widgets/status_timeline.dart';

class TransactionDetailPage extends StatefulWidget {
  final String id;
  final bool order;
  const TransactionDetailPage({
    super.key,
    required this.id,
    required this.order,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final _api = Component4ApiService();
  late Future<dynamic> _details;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _reload() => _details = widget.order
      ? _api.getProductOrder(widget.id)
      : _api.getMaterialTransaction(widget.id);

  Future<void> _action(String action) async {
    setState(() => _acting = true);
    try {
      await _api.performAction(
        order: widget.order,
        id: widget.id,
        action: action,
      );
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.order ? 'Order Details' : 'Transaction Details'),
    ),
    body: FutureBuilder<dynamic>(
      future: _details,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(snapshot.error.toString()),
                TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final details = snapshot.data;
        return _buildDetails(context, details);
      },
    ),
  );

  Widget _buildDetails(BuildContext context, dynamic details) {
    final isOrder = details is ProductOrderDetails;
    final DeliveryInfo? delivery = details.delivery;
    final List<StatusHistoryEntry> history = details.statusHistory;
    final sellerId = details.sellerBusinessId as String;
    final isSeller = sellerId == Component4Config.currentBusinessId;
    final status = details.statusName as String;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isOrder ? 'Product Order' : details.listingTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 16),
                _row('Buyer', details.buyer),
                _row('Seller', details.seller),
                if (!isOrder)
                  _row('Quantity', '${details.quantity} ${details.unit}'),
                if (!isOrder)
                  _row('Unit price', details.unitPrice.toStringAsFixed(2)),
                _row('Total', '\$${details.totalAmount.toStringAsFixed(2)}'),
                _row(
                  'Method',
                  delivery?.method == DeliveryMethod.sellerDelivery
                      ? 'Seller Delivery'
                      : 'Self Pickup',
                ),
                if (delivery?.location?.isNotEmpty == true)
                  _row('Location', delivery!.location!),
              ],
            ),
          ),
        ),
        if (isOrder) ...[
          const SizedBox(height: 16),
          Text('Items', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...details.items.map<Widget>(
            (ProductOrderItem item) => Card(
              child: ListTile(
                title: Text(item.productName),
                subtitle: Text(
                  '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                ),
                trailing: Text('\$${item.lineTotal.toStringAsFixed(2)}'),
              ),
            ),
          ),
        ],
        if (!isOrder &&
            status == 'Pending' &&
            details.buyerBusinessId == Component4Config.currentBusinessId)
          OutlinedButton(
            onPressed: _acting
                ? null
                : () async {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditTransactionPage(
                          transaction: details as MaterialTransactionDetails,
                        ),
                      ),
                    );
                    if (saved == true && mounted) setState(_reload);
                  },
            child: const Text('Edit Request'),
          ),
        if (const {
              'Pending',
              'Accepted',
              'Processing',
              'Placed',
              'Confirmed',
            }.contains(status) &&
            (delivery?.method == DeliveryMethod.selfPickup
                ? isSeller
                : details.buyerBusinessId ==
                      Component4Config.currentBusinessId))
          OutlinedButton(
            onPressed: _acting
                ? null
                : () async {
                    final location = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationPickerPage(
                          initialLocation: delivery?.location,
                        ),
                      ),
                    );
                    if (location == null || !mounted) return;
                    setState(() => _acting = true);
                    try {
                      await _api.updateLocation(
                        order: widget.order,
                        id: widget.id,
                        location: location,
                        updatedAt: details.updatedAt as String?,
                      );
                      if (mounted) setState(_reload);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    } finally {
                      if (mounted) setState(() => _acting = false);
                    }
                  },
            child: Text(
              delivery?.method == DeliveryMethod.selfPickup
                  ? 'Edit Pickup Address'
                  : 'Edit Delivery Destination',
            ),
          ),
        if (delivery?.location?.isNotEmpty == true)
          TextButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: const Text('View location / route'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationPickerPage(
                  initialLocation: delivery!.location,
                  readOnly: true,
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text('Status Timeline', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        StatusTimeline(entries: history),
        if (!_isTerminal(status)) ...[
          const SizedBox(height: 12),
          ..._actions(
            status,
            isSeller,
            delivery?.method ?? DeliveryMethod.selfPickup,
          ).map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: action.destructive
                  ? OutlinedButton(
                      onPressed: _acting ? null : () => _action(action.route),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                      ),
                      child: Text(action.label),
                    )
                  : ElevatedButton(
                      onPressed: _acting ? null : () => _action(action.route),
                      child: Text(action.label),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.slateGray),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  List<_DetailAction> _actions(
    String status,
    bool isSeller,
    DeliveryMethod method,
  ) {
    final actions = <_DetailAction>[];
    if (widget.order) {
      if (isSeller && status == 'Placed') {
        actions.add(const _DetailAction('Confirm Order', 'confirm'));
      }
      if (isSeller && status == 'Confirmed') {
        actions.add(const _DetailAction('Start Processing', 'processing'));
      }
      if (isSeller && status == 'Processing') {
        actions.add(const _DetailAction('Mark Ready', 'ready'));
      }
      if (isSeller && status == 'Ready') {
        actions.add(
          _DetailAction(
            method == DeliveryMethod.sellerDelivery
                ? 'Mark Delivered'
                : 'Complete Pickup',
            method == DeliveryMethod.sellerDelivery ? 'deliver' : 'complete',
          ),
        );
      }
    } else {
      if (isSeller && status == 'Pending') {
        actions.add(const _DetailAction('Accept Request', 'accept'));
        actions.add(
          const _DetailAction('Reject Request', 'reject', destructive: true),
        );
      }
      if (isSeller && status == 'Accepted') {
        actions.add(const _DetailAction('Start Processing', 'processing'));
      }
      if (isSeller && status == 'Processing') {
        actions.add(const _DetailAction('Mark Ready', 'ready'));
      }
      if (status == 'Ready') {
        actions.add(const _DetailAction('Complete Transaction', 'complete'));
      }
    }
    actions.add(const _DetailAction('Cancel', 'cancel', destructive: true));
    return actions;
  }

  bool _isTerminal(String status) => const {
    'Completed',
    'Delivered',
    'Cancelled',
    'Rejected',
  }.contains(status);
}

class _DetailAction {
  final String label;
  final String route;
  final bool destructive;
  const _DetailAction(this.label, this.route, {this.destructive = false});
}
