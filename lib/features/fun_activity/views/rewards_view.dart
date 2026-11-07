import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/shell_tab.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../points/services/points_service.dart';

/// Daily Rewards screen from the client mock: points, weekly check-in, streak.
class RewardsView extends StatefulWidget {
  const RewardsView({super.key, this.embedded = false});

  /// True when this screen is a bottom-nav tab. Back returns to Home.
  final bool embedded;

  @override
  State<RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<RewardsView> {
  final _scroll = ScrollController();
  final _earnKey = GlobalKey();
  bool _claiming = false;

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

  void _back() {
    if (widget.embedded) {
      ShellTab.go(0);
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthController>().user?.uid;
    final page = ColoredBox(
      color: _RewardsColors.page,
      child: SafeArea(
        bottom: false,
        child: uid == null
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
                    onBack: _back,
                    onRewards: _scrollToEarn,
                    onClaim: _claim,
                  );
                },
              ),
      ),
    );
    if (widget.embedded) return page;
    return Scaffold(body: page);
  }
}

class _RewardsBody extends StatelessWidget {
  const _RewardsBody({
    required this.state,
    required this.scroll,
    required this.earnKey,
    required this.claiming,
    required this.onBack,
    required this.onRewards,
    required this.onClaim,
  });

  final CivicRewardsState state;
  final ScrollController scroll;
  final Key earnKey;
  final bool claiming;
  final VoidCallback onBack;
  final VoidCallback onRewards;
  final ValueChanged<int> onClaim;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final week = List.generate(6, (i) => monday.add(Duration(days: i)));
    final streak = _streakCount(state.checkIns, today);
    final todayPoints = PointsService.pointsForWeekday(today.weekday);
    final claimedToday = state.checkIns.containsKey(PointsService.todayKey(today));

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _Header(onBack: onBack),
        const SizedBox(height: 8),
        _PointsCard(
          balance: state.balance,
          onRewards: onRewards,
        ),
        const SizedBox(height: 14),
        _WeeklyCard(
          days: week,
          today: today,
          checkIns: state.checkIns,
          claiming: claiming,
          onClaim: onClaim,
          sunday: today.weekday == DateTime.sunday
              ? _SundayClaim(
                  points: todayPoints,
                  claimed: claimedToday,
                  claiming: claiming,
                  onClaim: () => onClaim(todayPoints),
                )
              : null,
        ),
        const SizedBox(height: 14),
        _StreakBanner(streak: streak, monday: monday, today: today, checkIns: state.checkIns),
        const SizedBox(height: 14),
        _EarnCard(
          key: earnKey,
          checkInPoints: claimedToday ? todayPoints : todayPoints,
          claimedToday: claimedToday,
          onCheckIn: claimedToday || claiming ? null : () => onClaim(todayPoints),
        ),
        const SizedBox(height: 14),
        const _CommunityBanner(),
      ],
    );
  }
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              shadowColor: const Color(0x22000000),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Daily Rewards',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: _RewardsColors.burgundy,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Small actions, meaningful rewards!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: _GiftMark(),
          ),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.balance, required this.onRewards});

  final int balance;
  final VoidCallback onRewards;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        color: _RewardsColors.burgundy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _RewardsColors.shadow,
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
                    color: const Color(0xFFF3D5DC),
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
                      color: _RewardsColors.burgundy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rewards',
                      style: GoogleFonts.figtree(
                        color: _RewardsColors.burgundy,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: _RewardsColors.burgundy,
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
    required this.checkIns,
    required this.claiming,
    required this.onClaim,
    this.sunday,
  });

  final List<DateTime> days;
  final DateTime today;
  final Map<String, int> checkIns;
  final bool claiming;
  final ValueChanged<int> onClaim;
  final Widget? sunday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _RewardsColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E6EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _RewardsColors.burgundy,
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
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      'Check in daily and collect Civic Points.',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F1E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4DDD2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This Week',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final isNow = isToday && !claimed;
    final bg = isNow
        ? _RewardsColors.burgundy
        : claimed
            ? AppTheme.sage
            : const Color(0xFFF7F2EA);
    final fg = isNow ? Colors.white : AppTheme.ink;
    final muted = isNow ? const Color(0xFFF3D5DC) : AppTheme.inkMuted;

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
                            color: _RewardsColors.burgundy,
                          ),
                        ),
                      ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: claimed
                    ? AppTheme.ivory
                    : AppTheme.warmCream,
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
                    color: claimed ? AppTheme.leaf : AppTheme.inkMuted,
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
    if (claimed) {
      return Container(
        width: 26,
        height: 26,
          decoration: const BoxDecoration(
            color: AppTheme.ivory,
            shape: BoxShape.circle,
          ),
        child: const Icon(Icons.check_rounded, size: 16, color: AppTheme.leaf),
      );
    }
    if (isNow) {
      return const Icon(Icons.card_giftcard_rounded, color: Color(0xFFF2C14E), size: 22);
    }
    return Icon(
      Icons.lock_outline_rounded,
      size: 18,
      color: isFuture ? AppTheme.inkMuted : const Color(0xFFB7AFA4),
    );
  }
}

class _SundayClaim extends StatelessWidget {
  const _SundayClaim({
    required this.points,
    required this.claimed,
    required this.claiming,
    required this.onClaim,
  });

  final int points;
  final bool claimed;
  final bool claiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: claimed ? AppTheme.sage : _RewardsColors.burgundy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            claimed ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
            color: claimed ? AppTheme.leaf : const Color(0xFFF2C14E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              claimed ? 'Sunday check-in claimed' : 'Sunday check-in  +$points Pts',
              style: GoogleFonts.figtree(
                color: claimed ? AppTheme.ink : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!claimed)
            TextButton(
              onPressed: claiming ? null : onClaim,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _RewardsColors.burgundy,
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
    final title = streak == 0
        ? 'Start your streak'
        : streak == 1
            ? '1 Day in a Row!'
            : '$streak Days in a Row!';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _RewardsColors.burgundy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _RewardsColors.shadow,
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
                    color: const Color(0xFFF3D5DC),
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
                    color: const Color(0xFFF3D5DC),
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
            color: claimed ? _RewardsColors.burgundy : const Color(0xFFE7C9D0),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: _RewardsColors.card,
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
                  color: AppTheme.ink,
                ),
              ),
              const Spacer(),
              const Icon(Icons.spa_rounded, color: Color(0xFFB7C9A4)),
            ],
          ),
          const SizedBox(height: 8),
          const _EarnRow(
            icon: Icons.volunteer_activism_outlined,
            iconBg: Color(0xFFF8E4E8),
            iconColor: Color(0xFFB45B6C),
            title: 'Help someone',
            subtitle: 'Complete a successful charity exchange',
            points: 20,
          ),
          const Divider(height: 1),
          const _EarnRow(
            icon: Icons.inventory_2_outlined,
            iconBg: Color(0xFFF3EBE0),
            iconColor: Color(0xFF8A6A45),
            title: 'Recover an item',
            subtitle: 'Successfully return a lost item',
            points: 15,
          ),
          const Divider(height: 1),
          _EarnRow(
            icon: Icons.event_available_outlined,
            iconBg: AppTheme.sage,
            iconColor: AppTheme.leaf,
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
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.figtree(
                      fontSize: 12,
                      color: AppTheme.inkMuted,
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
      borderRadius: BorderRadius.circular(18),
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

class _GiftMark extends StatelessWidget {
  const _GiftMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(painter: _GiftPainter()),
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

class _GiftPainter extends CustomPainter {
  const _GiftPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final box = Paint()..color = const Color(0xFF8A5558);
    final lid = Paint()..color = AppTheme.burgundy;
    final ribbon = Paint()..color = const Color(0xFFE2B15A);
    final leaf = Paint()..color = const Color(0xFF8EAF78);
    final spark = Paint()
      ..color = const Color(0xFFE2B15A)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.46, w * 0.58, h * 0.40),
        const Radius.circular(5),
      ),
      box,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.36, w * 0.66, h * 0.14),
        const Radius.circular(3),
      ),
      lid,
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.36, w * 0.1, h * 0.50), ribbon);
    canvas.drawCircle(Offset(w * 0.38, h * 0.28), w * 0.09, ribbon);
    canvas.drawCircle(Offset(w * 0.56, h * 0.28), w * 0.09, ribbon);
    canvas.drawCircle(Offset(w * 0.47, h * 0.34), w * 0.045, ribbon);

    final leafPath = Path()
      ..moveTo(w * 0.78, h * 0.72)
      ..quadraticBezierTo(w * 0.98, h * 0.4, w * 0.7, h * 0.22)
      ..quadraticBezierTo(w * 0.86, h * 0.5, w * 0.78, h * 0.72)
      ..close();
    canvas.drawPath(leafPath, leaf);

    void sparkle(Offset c, double r) {
      canvas.drawLine(c.translate(0, -r), c.translate(0, r), spark);
      canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), spark);
    }

    sparkle(Offset(w * 0.2, h * 0.16), 4);
    sparkle(Offset(w * 0.78, h * 0.12), 3);
    sparkle(Offset(w * 0.12, h * 0.4), 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RewardsColors {
  static const page = AppTheme.ivory;
  static const burgundy = AppTheme.burgundy;
  static const shadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
  static final card = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: shadow,
  );
}
