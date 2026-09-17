import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;

  const PaymentPage({super.key, required this.totalAmount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'card';
  bool _isProcessing = false;

  void _processPayment() async {
    setState(() => _isProcessing = true);
    // Simulate network delay for payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isProcessing = false);
    
    // Return true to indicate successful payment
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Amount Summary
            Center(
              child: Column(
                children: [
                  const Text('Total to Pay', style: TextStyle(color: AppColors.slateGray, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    'LKR ${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.darkCharcoal,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),

            // Credit Card
            _buildPaymentMethod(
              id: 'card',
              title: 'Credit / Debit Card',
              subtitle: 'Visa, MasterCard, Amex',
              icon: Icons.credit_card,
            ),
            
            // Google Pay
            _buildPaymentMethod(
              id: 'gpay',
              title: 'Google Pay',
              subtitle: 'Pay easily with your Google account',
              icon: Icons.g_mobiledata_rounded,
            ),
            
            // Cash on Delivery
            _buildPaymentMethod(
              id: 'cod',
              title: 'Cash on Delivery',
              subtitle: 'Pay when your order arrives',
              icon: Icons.local_shipping,
            ),

            const SizedBox(height: 40),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 3),
                      )
                    : Text('Pay LKR ${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintGreen.withValues(alpha: 0.3) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.forestGreen : AppColors.mintGreen,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: AppColors.slateGray.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.forestGreen : AppColors.mintGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? AppColors.white : AppColors.forestGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.slateGray, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.forestGreen),
          ],
        ),
      ),
    );
  }
}
