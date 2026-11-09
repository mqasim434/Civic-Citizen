import 'package:flutter/material.dart';

import '../../home/views/map_placeholder_view.dart';
import '../ui/admin_ui.dart';

/// All posts on the map, inside the admin header.
class AdminMapView extends StatelessWidget {
  const AdminMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Map',
      leading: const AdminBackButton(),
      // The header already covers the status bar.
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: const MapPostsView(showAppBar: false),
      ),
    );
  }
}
