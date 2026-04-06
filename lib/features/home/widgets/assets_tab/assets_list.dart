import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'asset_detail_card.dart';

class AssetsList extends StatelessWidget {
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> allAssets;

  const AssetsList({super.key, required this.assets, required this.allAssets});

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.gray300,
              ),
              const SizedBox(height: 16),
              const Text(
                'No assets found',
                style: TextStyle(fontSize: 16, color: AppColors.gray600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: assets.map((asset) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AssetDetailCard(asset: asset, allAssets: allAssets),
        );
      }).toList(),
    );
  }
}
