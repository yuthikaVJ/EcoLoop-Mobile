import 'saved_locations_page.dart';
import 'package:flutter/material.dart';
import '../../data/services/component4_api_service.dart';
import '../../domain/entities/transaction_models.dart';
import '../widgets/activity_card.dart';
import 'transaction_detail_page.dart';

class TransactionsHubPage extends StatelessWidget {
  const TransactionsHubPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Transactions & Orders'),
        actions: [
          IconButton(
            tooltip: 'Saved locations',
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedLocationsPage()),
            ),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'My Transactions'),
            Tab(text: 'My Orders'),
            Tab(text: 'Received Transactions'),
            Tab(text: 'Received Orders'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _ActivityList(order: false, seller: false),
          _ActivityList(order: true, seller: false),
          _ActivityList(order: false, seller: true),
          _ActivityList(order: true, seller: true),
        ],
      ),
    ),
  );
}

class _ActivityList extends StatefulWidget {
  final bool order;
  final bool seller;
  const _ActivityList({required this.order, required this.seller});

  @override
  State<_ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<_ActivityList> {
  final _api = Component4ApiService();
  late Future<List<dynamic>> _items;
  int _page = 1;
  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _items = widget.order
      ? _api.getProductOrders(seller: widget.seller, page: _page)
      : _api.getMaterialTransactions(seller: widget.seller, page: _page);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: _items,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _MessageState(
          icon: Icons.cloud_off_outlined,
          message: snapshot.error.toString(),
          action: () => setState(_reload),
        );
      }
      final items = snapshot.data ?? [];
      if (items.isEmpty) {
        return _MessageState(
          icon: Icons.history,
          message: _page == 1 ? 'No records yet.' : 'No more records.',
          action: () => setState(() {
            _page = 1;
            _reload();
          }),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _items;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == items.length) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _page > 1
                        ? () => setState(() {
                            _page--;
                            _reload();
                          })
                        : null,
                    child: const Text('Previous'),
                  ),
                  Text('Page $_page'),
                  TextButton(
                    onPressed: items.length == 20
                        ? () => setState(() {
                            _page++;
                            _reload();
                          })
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              );
            }
            final item = items[index];
            final title = item is ProductOrderSummary
                ? 'Order • ${item.itemCount} item(s)'
                : (item as MaterialTransactionSummary).listingTitle;
            final subtitle = widget.seller
                ? 'Buyer: ${item.buyer}'
                : 'Seller: ${item.seller}';
            return ActivityCard(
              title: title,
              subtitle: subtitle,
              status: item.statusName,
              total: item.totalAmount,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TransactionDetailPage(id: item.id, order: widget.order),
                  ),
                );
                if (mounted) setState(_reload);
              },
            );
          },
        ),
      );
    },
  );
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? action;
  const _MessageState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
