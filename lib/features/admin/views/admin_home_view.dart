import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/user_avatar.dart';
import '../../ads/models/ad_model.dart';
import '../../ads/services/ad_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../events/models/civic_event.dart';
import '../../events/services/event_service.dart';
import '../../posts/models/post_model.dart';
import '../services/admin_service.dart';
import '../ui/admin_ui.dart';
import 'admin_more_view.dart';

/// Admin dashboard: totals, quick links and recent activity.
class AdminHomeView extends StatelessWidget {
  const AdminHomeView({
    super.key,
    required this.onOpenPosts,
    required this.onOpenUsers,
    required this.onOpenMorePage,
  });

  final VoidCallback onOpenPosts;
  final VoidCallback onOpenUsers;
  final ValueChanged<AdminMorePage> onOpenMorePage;

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: admin.watchAllUsers(),
      builder: (context, usersSnap) => StreamBuilder<List<PostModel>>(
        stream: admin.watchPosts(),
        builder: (context, postsSnap) => StreamBuilder<List<AdModel>>(
          stream: context.read<AdService>().watchAllAdsForAdmin(),
          builder: (context, adsSnap) => StreamBuilder<List<CivicEvent>>(
            stream: context.read<EventService>().watchAllEventsForAdmin(),
            builder: (context, eventsSnap) => _Dashboard(
              stats: _Stats.from(
                users: usersSnap.data?.docs,
                posts: postsSnap.data,
                ads: adsSnap.data,
                events: eventsSnap.data,
              ),
              onOpenPosts: onOpenPosts,
              onOpenUsers: onOpenUsers,
              onOpenMorePage: onOpenMorePage,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

enum _ActivityKind { userJoined, postAdded, verified, rejected, eventAdded, adStarted }

class _Activity {
  const _Activity({
    required this.kind,
    required this.time,
    required this.detail,
    this.userId,
    this.photoUrl,
  });

  final _ActivityKind kind;
  final DateTime time;
  final String detail;
  final String? userId;
  final String? photoUrl;

  String get title {
    switch (kind) {
      case _ActivityKind.userJoined:
        return 'New user registered';
      case _ActivityKind.postAdded:
        return 'New post added';
      case _ActivityKind.verified:
        return 'Verification approved';
      case _ActivityKind.rejected:
        return 'Verification rejected';
      case _ActivityKind.eventAdded:
        return 'Event published';
      case _ActivityKind.adStarted:
        return 'New ad started';
    }
  }
}

class _Stats {
  const _Stats({
    required this.loaded,
    required this.totalUsers,
    required this.userGrowth,
    required this.activePosts,
    required this.postGrowth,
    required this.pendingVerifications,
    required this.activeAds,
    required this.adGrowth,
    required this.upcomingEvents,
    required this.activities,
  });

  final bool loaded;
  final int totalUsers;
  final int? userGrowth;
  final int activePosts;
  final int? postGrowth;
  final int pendingVerifications;
  final int activeAds;
  final int? adGrowth;
  final int upcomingEvents;
  final List<_Activity> activities;

  static DateTime? _ts(Object? v) => v is Timestamp ? v.toDate() : null;

  factory _Stats.from({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>? users,
    required List<PostModel>? posts,
    required List<AdModel>? ads,
    required List<CivicEvent>? events,
  }) {
    final now = DateTime.now();
    final activities = <_Activity>[];

    var pending = 0;
    final joined = <DateTime?>[];
    for (final doc in users ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      final d = doc.data();
      final name = (d['displayName'] as String?)?.trim();
      final label = name == null || name.isEmpty ? 'User' : name;
      final photo = d['photoUrl'] as String?;
      // Users have no sign-up date, so the KYC submission (when the profile
      // document is created) stands in for it.
      final joinedAt = _ts(d['createdAt']) ?? _ts(d['kycSubmittedAt']);
      joined.add(joinedAt);
      if (d['verificationStatus'] == 'pending') pending++;
      if (joinedAt != null) {
        activities.add(_Activity(
          kind: _ActivityKind.userJoined,
          time: joinedAt,
          detail: label,
          userId: doc.id,
          photoUrl: photo,
        ));
      }
      final verifiedAt = _ts(d['verifiedAt']);
      if (verifiedAt != null && d['verificationStatus'] == 'verified') {
        activities.add(_Activity(
          kind: _ActivityKind.verified,
          time: verifiedAt,
          detail: label,
        ));
      }
      final rejectedAt = _ts(d['rejectedAt']);
      if (rejectedAt != null && d['verificationStatus'] == 'rejected') {
        activities.add(_Activity(
          kind: _ActivityKind.rejected,
          time: rejectedAt,
          detail: label,
        ));
      }
    }

    final postList = posts ?? const <PostModel>[];
    final active = postList
        .where((p) => p.isPubliclyListed && !p.isInappropriate)
        .toList();
    for (final p in postList) {
      if (p.createdAt != null) {
        activities.add(_Activity(
          kind: _ActivityKind.postAdded,
          time: p.createdAt!,
          detail: p.title,
        ));
      }
    }

    final adList = ads ?? const <AdModel>[];
    for (final a in adList) {
      if (a.createdAt != null) {
        activities.add(_Activity(
          kind: _ActivityKind.adStarted,
          time: a.createdAt!,
          detail: a.title,
        ));
      }
    }

    final eventList = events ?? const <CivicEvent>[];
    for (final e in eventList) {
      if (e.createdAt != null) {
        activities.add(_Activity(
          kind: _ActivityKind.eventAdded,
          time: e.createdAt!,
          detail: e.title,
        ));
      }
    }

    activities.sort((a, b) => b.time.compareTo(a.time));

    return _Stats(
      loaded: users != null && posts != null,
      totalUsers: users?.length ?? 0,
      userGrowth: adminGrowthPercent(joined),
      activePosts: active.length,
      postGrowth: adminGrowthPercent(active.map((p) => p.createdAt)),
      pendingVerifications: pending,
      activeAds: adList.where((a) => a.isLive).length,
      adGrowth: adminGrowthPercent(
        adList.where((a) => a.isLive).map((a) => a.createdAt),
      ),
      upcomingEvents: eventList
          .where(
            (e) => e.active && e.eventDate != null && e.eventDate!.isAfter(now),
          )
          .length,
      activities: activities.take(50).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.stats,
    required this.onOpenPosts,
    required this.onOpenUsers,
    required this.onOpenMorePage,
  });

  final _Stats stats;
  final VoidCallback onOpenPosts;
  final VoidCallback onOpenUsers;
  final ValueChanged<AdminMorePage> onOpenMorePage;

  String _count(int n) => stats.loaded ? adminNumber(n) : '–';

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: p.page,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              // Waves stay solid at the top and fade into the page towards
              // the bottom, so the Total Users card stands out.
              SizedBox(
                height: top + 150,
                width: double.infinity,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0, 0.45, 1],
                  ).createShader(rect),
                  child: CustomPaint(painter: AdminHeaderPainter(p)),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, top + 10, 16, 0),
                child: Column(
                  children: [
                    const _HeaderRow(),
                    const SizedBox(height: 16),
                    _TotalUsersCard(
                      value: _count(stats.totalUsers),
                      growth: stats.userGrowth,
                      onTap: onOpenUsers,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.28,
                  children: [
                    _StatTile(
                      icon: Icons.description_rounded,
                      iconColor: p.primary,
                      label: 'Active Posts',
                      value: _count(stats.activePosts),
                      growth: stats.postGrowth,
                      onTap: onOpenPosts,
                    ),
                    _StatTile(
                      icon: Icons.shield_rounded,
                      iconColor: p.amber,
                      label: 'Pending\nVerifications',
                      value: _count(stats.pendingVerifications),
                      background: p.tileWarm,
                      onTap: () => onOpenMorePage(AdminMorePage.verification),
                    ),
                    _StatTile(
                      icon: Icons.campaign_rounded,
                      iconColor: p.amber,
                      label: 'Active Ads',
                      value: _count(stats.activeAds),
                      growth: stats.adGrowth,
                      background: p.tileAmber,
                      onTap: () => onOpenMorePage(AdminMorePage.ads),
                    ),
                    _StatTile(
                      icon: Icons.event_note_rounded,
                      iconColor: p.primary,
                      label: 'Upcoming\nEvents',
                      value: _count(stats.upcomingEvents),
                      onTap: () => onOpenMorePage(AdminMorePage.events),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AdminSectionHeader(
                  title: 'Recent Activities',
                  actionLabel: 'View All',
                  onAction: () => Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute<void>(
                    builder: (_) => _ActivityListPage(items: stats.activities),
                  )),
                ),
                const SizedBox(height: 8),
                if (!stats.loaded)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (stats.activities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No activity yet', style: AdminText.body(p)),
                  )
                else
                  for (final a in stats.activities.take(3)) _ActivityRow(a),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? 'Admin');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: UserAvatar(
            userId: user?.uid ?? '',
            name: name,
            radius: 24,
            photoUrl: user?.photoUrl ?? '',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Panel', style: AdminText.header(size: 21)),
              const SizedBox(height: 2),
              Text(
                'Welcome back,\n$name',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AdminText.label(
                  Colors.white.withValues(alpha: 0.85),
                  size: 12.5,
                ).copyWith(fontWeight: FontWeight.w500, height: 1.25),
              ),
            ],
          ),
        ),
        const AdminBell(),
      ],
    );
  }
}

class _Growth extends StatelessWidget {
  const _Growth(this.percent, {required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_upward_rounded, size: 12, color: color),
        const SizedBox(width: 2),
        Text('$percent%', style: AdminText.label(color, size: 11)),
      ],
    );
  }
}

class _TotalUsersCard extends StatelessWidget {
  const _TotalUsersCard({
    required this.value,
    required this.growth,
    required this.onTap,
  });

  final String value;
  final int? growth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final light = Colors.white.withValues(alpha: 0.85);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [p.heroStart, p.heroEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: p.isDark
              ? Border.all(color: p.primary.withValues(alpha: 0.5))
              : null,
          boxShadow: [
            BoxShadow(
              color: p.heroEnd.withValues(alpha: p.isDark ? 0.35 : 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _CardWavesPainter()),
                ),
              ),
              Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    if (growth != null) _Growth(growth!, color: light),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Users',
                        style: AdminText.label(Colors.white, size: 14)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                              style: AdminText.header(size: 30),
                            ),
                          ),
                          if (growth != null) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _Growth(growth!, color: light),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.people_alt_rounded,
                  size: 54,
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft translucent wave layers behind the Total Users card content.
class _CardWavesPainter extends CustomPainter {
  const _CardWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
    );

    // Back layer: wide wave across the lower half.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.72)
        ..cubicTo(w * 0.3, h * 0.45, w * 0.6, h * 1.05, w, h * 0.55)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    // Front layer: lower, offset wave.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.9)
        ..cubicTo(w * 0.35, h * 0.68, w * 0.7, h * 1.1, w, h * 0.78)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Small arc in the top-right corner.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, 0)
        ..cubicTo(w * 0.75, h * 0.35, w * 0.9, h * 0.1, w, h * 0.32)
        ..lineTo(w, 0)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
    this.growth,
    this.background,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final int? growth;
  final Color? background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: p.cardDecoration(color: background),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 28),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  style: AdminText.title(p, size: 13).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: AdminText.title(p, size: 20)),
                if (growth != null) ...[
                  const SizedBox(height: 2),
                  _Growth(growth!, color: p.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.a);

  final _Activity a;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    Widget leading;
    switch (a.kind) {
      case _ActivityKind.userJoined:
        leading = UserAvatar(
          userId: a.userId ?? '',
          name: a.detail,
          radius: 18,
          photoUrl: a.photoUrl ?? '',
          backgroundColor: p.softGreen,
          foregroundColor: p.softGreenText,
        );
      case _ActivityKind.verified:
        leading = CircleAvatar(
          radius: 18,
          backgroundColor: p.primary,
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
        );
      case _ActivityKind.rejected:
        leading = CircleAvatar(
          radius: 18,
          backgroundColor: p.softRed,
          child: Icon(Icons.close_rounded, color: p.softRedText, size: 22),
        );
      case _ActivityKind.postAdded:
      case _ActivityKind.eventAdded:
      case _ActivityKind.adStarted:
        leading = Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: p.softGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            a.kind == _ActivityKind.postAdded
                ? Icons.post_add_rounded
                : a.kind == _ActivityKind.eventAdded
                    ? Icons.event_available_rounded
                    : Icons.campaign_rounded,
            color: p.primary,
            size: 20,
          ),
        );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: p.isDark
          ? BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(12),
            )
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: p.cardBorder)),
            ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: AdminText.title(p, size: 14).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${adminTimeAgo(a.time)} · ${a.detail}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.body(p, size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityListPage extends StatelessWidget {
  const _ActivityListPage({required this.items});

  final List<_Activity> items;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Recent Activities',
      leading: const AdminBackButton(),
      body: items.isEmpty
          ? const AdminEmpty(
              icon: Icons.history_rounded,
              message: 'No activity yet',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [for (final a in items) _ActivityRow(a)],
            ),
    );
  }
}
