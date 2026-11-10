import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/shell_tab.dart';
import '../../../core/navigation/tab_reselect.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../points/services/points_service.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

/// Daily Rewards screen from the client mock: points, weekly check-in, streak.
class RewardsView extends StatefulWidget {
  const RewardsView({super.key, this.embedded = false});

  /// True when this screen is a bottom-nav tab. Back returns to Home.
  final bool embedded;

  @override
  State<RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<RewardsView>
    with TabReselectListener {
  final _scroll = ScrollController();
  final _earnKey = GlobalKey();
  bool _claiming = false;
  int _weekOffset = 0;

  @override
  int get shellTabIndex => ShellTab.rewards;

  @override
  void onTabReselected() {
    if (widget.embedded) scrollToTop(_scroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _claim(int amount) async {
    if (_claiming) return;
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;
    setState(() => _claiming = true);
    try {
      await context.read<PointsService>().claimCheckIn(
            uid: uid,
            dateKey: PointsService.todayKey(),
            amount: amount,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You earned $amount Civic Points')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  void _scrollToEarn() {
    final ctx = _earnKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthController>().user?.uid;
    // Same wave header as every other screen. As a tab there is no back
    // arrow; opened as its own page the app bar adds one.
    return Scaffold(
      backgroundColor: AppTheme.colors(context).page,
      appBar: AppBar(
        flexibleSpace: const WaveHeaderBackground(),
        bottom: const WaveHeaderSpacer(),
        title: const Text('Daily Rewards'),
      ),
      body: uid == null
          ? const Center(child: Text('Please sign in'))
          : StreamBuilder<CivicRewardsState>(
              stream: context.read<PointsService>().watchRewards(uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _RewardsBody(
                  state: snap.data!,
                  scroll: _scroll,
                  earnKey: _earnKey,
                  claiming: _claiming,
                  weekOffset: _weekOffset,
                  onWeekSelected: (offset) =>
                      setState(() => _weekOffset = offset),
                  onRewards: _scrollToEarn,
                  onClaim: _claim,
                );
              },
            ),
    );
  }
}

class _RewardsBody extends StatelessWidget {
  const _RewardsBody({
    required this.state,
    required this.scroll,
    required this.earnKey,
    required this.claiming,
    required this.weekOffset,
    required this.onWeekSelected,
    required this.onRewards,
    required this.onClaim,
  });

  final CivicRewardsState state;
  final ScrollController scroll;
  final Key earnKey;
  final bool claiming;
  final int weekOffset;
  final ValueChanged<int> onWeekSelected;
  final VoidCallback onRewards;
  final ValueChanged<int> onClaim;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final monday = currentMonday.subtract(Duration(days: 7 * weekOffset));
    final week = List.generate(6, (i) => monday.add(Duration(days: i)));
    final sunday = monday.add(const Duration(days: 6));
    final streak = _streakCount(state.checkIns, today);
    final todayPoints = PointsService.pointsForWeekday(today.weekday);
    final claimedToday = state.checkIns.containsKey(PointsService.todayKey(today));
    final sundayClaimed =
        state.checkIns.containsKey(PointsService.todayKey(sunday));

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        4,
        AppTheme.pagePadding,
        28,
      ),
      children: [
        _PointsCard(
          balance: state.balance,
          onRewards: onRewards,
        ),
        const SizedBox(height: AppTheme.cardGap),
        _WeeklyCard(
          days: week,
          today: today,
          weekOffset: weekOffset,
          onWeekSelected: onWeekSelected,
          checkIns: state.checkIns,
          claiming: claiming,
          onClaim: onClaim,
          sunday: _SundayClaim(
            points: PointsService.pointsForWeekday(DateTime.sunday),
            claimed: sundayClaimed,
            canClaim: sunday == today,
            missed: sunday.isBefore(today) && !sundayClaimed,
            claiming: claiming,
            onClaim: () => onClaim(
              PointsService.pointsForWeekday(DateTime.sunday),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.cardGap),
        _StreakBanner(
          streak: streak,
          monday: currentMonday,
          today: today,
          checkIns: state.checkIns,
        ),
        const SizedBox(height: AppTheme.cardGap),
        _EarnCard(
          key: earnKey,
          checkInPoints: claimedToday ? todayPoints : todayPoints,
          claimedToday: claimedToday,
          onCheckIn: claimedToday || claiming ? null : () => onClaim(todayPoints),
        ),
        const SizedBox(height: AppTheme.cardGap),
        const _CommunityBanner(),
      ],
    );
  }
}

String _weekMenuLabel(DateTime today, int offset) {
  if (offset == 0) return 'This Week';
  if (offset == 1) return 'Last Week';
  final monday = today
      .subtract(Duration(days: today.weekday - 1 + 7 * offset));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Week of ${monday.day} ${months[monday.month - 1]}';
}

int _streakCount(Map<String, int> checkIns, DateTime today) {
  var cursor = today;
  if (!checkIns.containsKey(PointsService.todayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var count = 0;
  while (checkIns.containsKey(PointsService.todayKey(cursor)) && count < 366) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.balance, required this.onRewards});

  final int balance;
  final VoidCallback onRewards;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        color: c.burgundy,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: _RewardsColors.shadow(c),
      ),
      child: Row(
        children: [
          const _GoldCoin(),
          Container(
            width: 1,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white24,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Civic Points',
                  style: GoogleFonts.figtree(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$balance Points',
                  style: GoogleFonts.fraunces(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Keep helping your community!',
                  style: GoogleFonts.figtree(
                    color: c.onBurgundyMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFF8F1E6),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onRewards,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 16,
                      color: AppTheme.burgundy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rewards',
                      style: GoogleFonts.figtree(
                        color: AppTheme.burgundy,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppTheme.burgundy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({
    required this.days,
    required this.today,
    required this.weekOffset,
    required this.onWeekSelected,
    required this.checkIns,
    required this.claiming,
    required this.onClaim,
    this.sunday,
  });

  final List<DateTime> days;
  final DateTime today;
  final int weekOffset;
  final ValueChanged<int> onWeekSelected;
  final Map<String, int> checkIns;
  final bool claiming;
  final ValueChanged<int> onClaim;
  final Widget? sunday;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _RewardsColors.card(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.burgundySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: c.burgundyInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Rewards',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      'Check in daily and collect Civic Points.',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        color: c.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                initialValue: weekOffset,
                onSelected: onWeekSelected,
                itemBuilder: (context) => [
                  for (var i = 0; i < 8; i++)
                    PopupMenuItem(
                      value: i,
                      child: Text(_weekMenuLabel(today, i)),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.subtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.subtleBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _weekMenuLabel(today, weekOffset),
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: c.ink),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardGap),
          Row(
            children: [
              for (final day in days) ...[
                Expanded(
                  child: _DayTile(
                    day: day,
                    today: today,
                    points: checkIns[PointsService.todayKey(day)] ??
                        PointsService.pointsForWeekday(day.weekday),
                    claimed: checkIns.containsKey(PointsService.todayKey(day)),
                    claiming: claiming,
                    onClaim: onClaim,
                  ),
                ),
                if (day != days.last) const SizedBox(width: 6),
              ],
            ],
          ),
          if (sunday != null) ...[
            const SizedBox(height: 10),
            sunday!,
          ],
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.today,
    required this.points,
    required this.claimed,
    required this.claiming,
    required this.onClaim,
  });

  final DateTime day;
  final DateTime today;
  final int points;
  final bool claimed;
  final bool claiming;
  final ValueChanged<int> onClaim;

  static const _labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final isNow = isToday && !claimed;
    final bg = isNow
        ? c.burgundy
        : claimed
            ? c.sage
            : c.subtle;
    final fg = isNow ? Colors.white : c.ink;
    final muted = isNow ? c.onBurgundyMuted : c.inkMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              _labels[day.weekday - 1],
              style: GoogleFonts.figtree(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _DayIcon(claimed: claimed, isNow: isNow, isFuture: isFuture),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              isFuture || (!claimed && !isToday) ? '? Pts' : '+$points Pts',
              style: GoogleFonts.figtree(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (isNow)
            GestureDetector(
              onTap: claiming ? null : () => onClaim(points),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: claiming
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FittedBox(
                        child: Text(
                          'Claim Now',
                          style: GoogleFonts.figtree(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.burgundy,
                          ),
                        ),
                      ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: claimed ? c.page : c.raised,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FittedBox(
                child: Text(
                  claimed
                      ? 'Claimed'
                      : isFuture
                          ? 'Locked'
                          : 'Missed',
                  style: GoogleFonts.figtree(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: claimed ? c.olive : c.inkMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayIcon extends StatelessWidget {
  const _DayIcon({
    required this.claimed,
    required this.isNow,
    required this.isFuture,
  });

  final bool claimed;
  final bool isNow;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    if (claimed) {
      return Container(
        width: 26,
        height: 26,
          decoration: BoxDecoration(
            color: c.page,
            shape: BoxShape.circle,
          ),
        child: Icon(Icons.check_rounded, size: 16, color: c.olive),
      );
    }
    if (isNow) {
      return const Icon(Icons.card_giftcard_rounded, color: Color(0xFFF2C14E), size: 22);
    }
    return Icon(
      Icons.lock_outline_rounded,
      size: 18,
      color: isFuture ? c.inkMuted : c.inkFaint,
    );
  }
}

class _SundayClaim extends StatelessWidget {
  const _SundayClaim({
    required this.points,
    required this.claimed,
    required this.canClaim,
    required this.missed,
    required this.claiming,
    required this.onClaim,
  });

  final int points;
  final bool claimed;
  final bool canClaim;
  final bool missed;
  final bool claiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: claimed
            ? c.sage
            : canClaim
                ? c.burgundy
                : c.subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            claimed
                ? Icons.check_circle_rounded
                : canClaim
                    ? Icons.card_giftcard_rounded
                    : Icons.lock_outline_rounded,
            color: claimed
                ? c.olive
                : canClaim
                    ? const Color(0xFFF2C14E)
                    : c.inkMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              claimed
                  ? 'Sunday check-in claimed'
                  : missed
                      ? 'Sunday check-in missed'
                      : canClaim
                          ? 'Sunday check-in  +$points Pts'
                          : 'Sunday check-in',
              style: GoogleFonts.figtree(
                color: canClaim ? Colors.white : c.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (canClaim && !claimed)
            TextButton(
              onPressed: claiming ? null : onClaim,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.burgundy,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Claim Now'),
            ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({
    required this.streak,
    required this.monday,
    required this.today,
    required this.checkIns,
  });

  final int streak;
  final DateTime monday;
  final DateTime today;
  final Map<String, int> checkIns;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final title = streak == 0
        ? 'Start your streak'
        : streak == 1
            ? '1 Day in a Row!'
            : '$streak Days in a Row!';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: c.burgundy,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: _RewardsColors.shadow(c),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF2C14E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Helping Streak',
                  style: GoogleFonts.figtree(
                    color: c.onBurgundyMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Keep your daily activity going.',
                  style: GoogleFonts.figtree(
                    color: c.onBurgundyMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          _StreakDots(monday: monday, today: today, checkIns: checkIns),
        ],
      ),
    );
  }
}

class _StreakDots extends StatelessWidget {
  const _StreakDots({
    required this.monday,
    required this.today,
    required this.checkIns,
  });

  final DateTime monday;
  final DateTime today;
  final Map<String, int> checkIns;

  static const _letters = ['M', 'T', 'W', 'T', 'F'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          _dot(monday.add(Duration(days: i)), _letters[i]),
          if (i != 4)
            Container(
              width: 8,
              height: 2,
              color: Colors.white24,
            ),
        ],
      ],
    );
  }

  Widget _dot(DateTime day, String letter) {
    final claimed = checkIns.containsKey(PointsService.todayKey(day));
    final future = day.isAfter(today);
    final icon = claimed
        ? Icons.check_rounded
        : future
            ? Icons.lock_outline_rounded
            : Icons.remove_rounded;
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: claimed ? Colors.white : const Color(0xFF5C2432),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 11,
            color: claimed ? AppTheme.burgundy : const Color(0xFFE7C9D0),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          letter,
          style: GoogleFonts.figtree(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EarnCard extends StatelessWidget {
  const _EarnCard({
    super.key,
    required this.checkInPoints,
    required this.claimedToday,
    required this.onCheckIn,
  });

  final int checkInPoints;
  final bool claimedToday;
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: _RewardsColors.card(c),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFE2B15A)),
              const SizedBox(width: 8),
              Text(
                'Earn More Civic Points',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const Spacer(),
              const Icon(Icons.spa_rounded, color: Color(0xFFB7C9A4)),
            ],
          ),
          const SizedBox(height: 8),
          _EarnRow(
            icon: Icons.volunteer_activism_outlined,
            iconBg: c.isDark ? c.burgundySoft : const Color(0xFFF8E4E8),
            iconColor: c.isDark ? c.burgundyInk : const Color(0xFFB45B6C),
            title: 'Help someone',
            subtitle: 'Complete a successful charity exchange',
            points: 20,
          ),
          const Divider(height: 1),
          _EarnRow(
            icon: Icons.inventory_2_outlined,
            iconBg: c.isDark ? const Color(0xFF3A3226) : const Color(0xFFF3EBE0),
            iconColor: c.isDark ? const Color(0xFFD2B48C) : const Color(0xFF8A6A45),
            title: 'Recover an item',
            subtitle: 'Successfully return a lost item',
            points: 15,
          ),
          const Divider(height: 1),
          _EarnRow(
            icon: Icons.event_available_outlined,
            iconBg: c.sage,
            iconColor: c.olive,
            title: 'Daily check-in',
            subtitle: claimedToday ? 'Claimed for today' : 'Visit the app daily',
            points: checkInPoints,
            onTap: onCheckIn,
          ),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.points,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int points;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.figtree(
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.figtree(
                      fontSize: 12,
                      color: c.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.leaf,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '+$points Pts',
                style: GoogleFonts.figtree(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: SizedBox(
        height: 78,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Image(
              image: AssetImage('assets/rewards_banner.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 120, 0),
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded, color: AppTheme.olive, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Together we build\na more caring community ❤',
                      style: GoogleFonts.fraunces(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.olive,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldCoin extends StatelessWidget {
  const _GoldCoin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8E2A0), Color(0xFFE2B15A)],
        ),
      ),
      child: const Icon(Icons.star_rounded, color: Color(0xFF8A5A12)),
    );
  }
}

class _RewardsColors {
  static List<BoxShadow> shadow(CivicColors c) => [
        BoxShadow(
          color: c.shadow,
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Same look as the theme Card used by Home and Nearby posts:
  /// radius, 1px border, no shadow.
  static BoxDecoration card(CivicColors c) => BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          // Matches colorScheme.outlineVariant in each theme.
          color: c.isDark ? c.subtleBorder : AppTheme.sage,
        ),
      );
}
