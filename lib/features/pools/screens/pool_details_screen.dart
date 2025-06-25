import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import 'pool_form_screen.dart';
import 'maintenance_form_screen.dart';

class PoolDetailsScreen extends StatefulWidget {
  final String poolId;

  const PoolDetailsScreen({
    Key? key,
    required this.poolId,
  }) : super(key: key);

  @override
  State<PoolDetailsScreen> createState() => _PoolDetailsScreenState();
}

class _PoolDetailsScreenState extends State<PoolDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('pools').doc(widget.poolId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Pool not found.')),
          );
        }

        final pool = snapshot.data!.data() as Map<String, dynamic>;
        // Add the document ID to the map for convenience
        pool['id'] = snapshot.data!.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(pool['name'] ?? 'Pool Details'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pool Information',
                        style: AppTextStyles.headline2,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Name', pool['name'] ?? 'N/A'),
                      _buildInfoRow('Address', pool['address'] ?? 'N/A'),
                      _buildInfoRow('Size', '${pool['size'] ?? 'N/A'} m²'),
                      _buildInfoRow('Status', pool['status'] ?? 'N/A'),
                      _buildInfoRow('Customer', pool['customerName'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Specifications',
                        style: AppTextStyles.headline2,
                      ),
                      const SizedBox(height: 16),
                      if (pool['specifications'] != null &&
                          (pool['specifications'] as Map).isNotEmpty) ...[
                        for (var entry in (pool['specifications'] as Map<String, dynamic>).entries)
                          _buildInfoRow(entry.key, entry.value.toString()),
                      ] else ...[
                        const Text('No specifications available'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance History',
                        style: AppTextStyles.headline2,
                      ),
                      const SizedBox(height: 16),
                      const Text('No maintenance records available'),
                      // TODO: Implement maintenance history list
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PoolFormScreen(pool: pool),
                            ),
                          );
                        },
                        label: 'Edit Pool',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        onPressed: () {
                           Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MaintenanceFormScreen(poolId: pool['id']),
                            ),
                          );
                        },
                        label: 'Add Maintenance',
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
