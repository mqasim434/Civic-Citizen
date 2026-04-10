import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/admin_service.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — verifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) {
                navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppConstants.routeLogin,
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: context.read<AdminService>().watchPendingVerifications(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading requests: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No pending verification requests',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final name = d['displayName'] as String? ?? 'User';
              final email = d['email'] as String? ?? '';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    navigatorKey.currentState?.pushNamed(
                      AppConstants.routeAdminUserVerification,
                      arguments: doc.id,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
