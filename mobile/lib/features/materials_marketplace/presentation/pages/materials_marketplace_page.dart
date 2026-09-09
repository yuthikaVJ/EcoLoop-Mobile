import 'package:flutter/material.dart';

class MaterialsMarketplacePage extends StatelessWidget {
  const MaterialsMarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials Marketplace'),
      ),
      body: const Center(
        child: Text('Materials Marketplace UI will go here.'),
      ),
    );
  }
}
