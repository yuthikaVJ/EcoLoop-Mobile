import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/component4_api_service.dart';
import '../../domain/entities/transaction_models.dart';
import '../widgets/status_badge.dart';
import 'delivery_run_page.dart';

/// Seller Delivery jobs for the signed-in seller. EcoLoop has no rider fleet:
/// when a buyer picks Seller Delivery, the seller delivers it themselves.
class MyDeliveriesPage extends StatefulWidget {
  const MyDeliveriesPage({super.key});

  @override
  State<MyDeliveriesPage> createState() => _MyDeliveriesPageState();
}

class _MyDeliveriesPageState extends State<MyDeliveriesPage> {
  final _api = Component4ApiService();
  List<SellerDeliveryJob> _jobs = [];
  bool _loading = true;
  bool _showFinished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    setState(() {
      _loading = showSpinner;
      _error = null;
    });
    try {
      final jobs = await _api.getMyDeliveries(includeFinished: _showFinished);
      if (mounted) setState(() => _jobs = jobs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(SellerDeliveryJob job) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeliveryRunPage(job: job)),
    );
    if (mounted) _load(showSpinner: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Deliveries'),
      actions: [
        IconButton(
          tooltip: _showFinished ? 'Hide delivered' : 'Show delivered',
          icon: Icon(_showFinished ? Icons.history_toggle_off : Icons.history),
          onPressed: () {
            setState(() => _showFinished = !_showFinished);
            _load();
          },
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            color: AppColors.forestGreen,
            onRefresh: () => _load(showSpinner: false),
            child: _jobs.isEmpty
                ? const CustomScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 64,
                                color: AppColors.slateGray,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No deliveries to make.\nWhen a buyer chooses Seller Delivery, the order shows up here. Mark it Ready in Orders, then start the delivery.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.slateGray),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _jobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _DeliveryCard(
                      job: _jobs[i],
                      onTap: () => _open(_jobs[i]),
                    ),
                  ),
          ),
  );
}

class _DeliveryCard extends StatelessWidget {
  final SellerDeliveryJob job;
  final VoidCallback onTap;
  const _DeliveryCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  job.isProductOrder
                      ? Icons.shopping_bag_outlined
                      : Icons.recycling,
                  color: AppColors.ecoGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusBadge(status: progressLabel(job.progress)),
              ],
            ),
            const SizedBox(height: 8),
            Text('To: ${job.buyer}'),
            const SizedBox(height: 4),
            Text(
              job.destination ?? 'No delivery address yet',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.slateGray),
            ),
            const SizedBox(height: 8),
            Text(
              job.progress == DeliveryProgress.notStarted && !job.canStart
                  ? 'Order is ${job.parentStatus} — mark it Ready to start'
                  : 'Order status: ${job.parentStatus}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

String progressLabel(DeliveryProgress progress) => switch (progress) {
  DeliveryProgress.notStarted => 'Not started',
  DeliveryProgress.onTheWay => 'On the way',
  DeliveryProgress.delivered => 'Delivered',
};
