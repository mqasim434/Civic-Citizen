import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/views/map_placeholder_view.dart';
import 'admin_posts_timeline_view.dart';
import 'admin_user_management_view.dart';
import '../services/admin_service.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _index = 0;

  static const _tabs = [
    _AdminTab(
      icon: Icons.verified_user_outlined,
      label: 'Verifications',
      title: 'Admin - verifications',
    ),
    _AdminTab(
      icon: Icons.dynamic_feed_outlined,
      label: 'Posts',
      title: 'Admin - posts timeline',
    ),
    _AdminTab(
      icon: Icons.map_rounded,
      label: 'Map',
      title: 'Admin - map',
    ),
    _AdminTab(
      icon: Icons.manage_accounts_outlined,
      label: 'Users',
      title: 'Admin - user management',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].title),
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
      body: IndexedStack(
        index: _index,
        children: const [
          _AdminVerificationTimeline(),
          AdminPostsTimelineView(),
          MapPostsView(),
          AdminUserManagementView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AdminTab {
  const _AdminTab({
    required this.icon,
    required this.label,
    required this.title,
  });

  final IconData icon;
  final String label;
  final String title;
}

class _AdminVerificationTimeline extends StatelessWidget {
  const _AdminVerificationTimeline();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
    );
  }
}
