import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../lend_borrow/models/contract_status.dart';
import '../../lend_borrow/models/lend_borrow_contract.dart';
import '../../lend_borrow/services/lend_borrow_contract_service.dart';
import '../../lost_found/models/claim_status.dart';
import '../../lost_found/models/lost_found_claim.dart';
import '../../lost_found/services/lost_found_claim_service.dart';
import '../../posts/models/post_model.dart';
import '../ui/admin_ui.dart';

/// Everything an admin needs about a post: listing details, the author and
/// every contract / claim with both parties (1st and 2nd hand).
class AdminPostDetailView extends StatelessWidget {
  const AdminPostDetailView({super.key, required this.post});

  final PostModel post;

  bool get _isExchange =>
      post.module == PostModule.lend || post.module == PostModule.borrow;
  bool get _isRecovery =>
      post.module == PostModule.lost || post.module == PostModule.found;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final image = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final category = post.categoryCustom?.trim().isNotEmpty == true
        ? post.categoryCustom!
        : post.category;

    return AdminPage(
      title: 'Post details',
      leading: const AdminBackButton(),
      actions: [
        AdminHeaderIcon(
          tooltip: 'Open public view',
          icon: Icons.open_in_new_rounded,
          onPressed: () => navigatorKey.currentState?.pushNamed(
            AppConstants.routePostDetail,
            arguments: post,
          ),
        ),
        const SizedBox(width: 4),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: p.softGreen),
                ),
              ),
            ),
          if (image != null) const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AdminPill.green(context, post.module.label),
              post.isFulfilled
                  ? AdminPill.blue(context, 'Fulfilled')
                  : AdminPill.green(context, 'Active'),
              if (post.isInappropriate) AdminPill.red(context, 'Inappropriate'),
              if (post.isSponsored) AdminPill.amber(context, 'Sponsored'),
              if (post.isSponsorPaused) AdminPill.grey(context, 'Ad paused'),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.title, style: AdminText.title(p, size: 20)),
          const SizedBox(height: 6),
          Text(post.description, style: AdminText.body(p, size: 14)),
          const SizedBox(height: 18),

          _Section(
            title: 'Listing',
            rows: [
              if (category != null && category.isNotEmpty)
                ('Category', category),
              if (post.itemCondition?.isNotEmpty == true)
                ('Condition', post.itemCondition!),
              if (post.location?.isNotEmpty == true) ('Location', post.location!),
              if (post.latitude != null && post.longitude != null)
                (
                  'Coordinates',
                  '${post.latitude!.toStringAsFixed(5)}, '
                      '${post.longitude!.toStringAsFixed(5)}',
                ),
              if (post.contactNumber.trim().isNotEmpty)
                ('Contact number', post.contactNumber),
              if (post.createdAt != null)
                ('Posted', _dateTime(post.createdAt!)),
              if (post.updatedAt != null)
                ('Last updated', _dateTime(post.updatedAt!)),
              if (post.fulfilledAt != null)
                ('Fulfilled', _dateTime(post.fulfilledAt!)),
              ('Views', '${post.viewCount}'),
              ('Likes', '${post.likeCount}'),
              ('Comments', '${post.commentCount}'),
              if (post.hasAdHistory) ...[
                ('Ad points spent', '${post.sponsorPointsSpent}'),
                if (post.sponsoredUntil != null)
                  ('Sponsored until', _dateTime(post.sponsoredUntil!)),
              ],
              if (post.isInappropriate)
                (
                  'Flag reason',
                  post.inappropriateReason?.isNotEmpty == true
                      ? post.inappropriateReason!
                      : 'No reason given',
                ),
            ],
          ),
          const SizedBox(height: 14),
          _AuthorCard(post: post),
          if (_isExchange) ...[
            const SizedBox(height: 18),
            _ContractsSection(post: post),
          ],
          if (_isRecovery) ...[
            const SizedBox(height: 18),
            _ClaimsSection(post: post),
          ],
        ],
      ),
    );
  }
}

String _dateTime(DateTime t) => '${adminDate(t)}, ${adminTime(t)}';

// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows, this.trailing});

  final String title;
  final List<(String, String)> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: p.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AdminText.title(p, size: 15))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          for (final r in rows) _InfoRow(label: r.$1, value: r.$2),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AdminText.body(p, size: 13)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AdminText.title(p, size: 13).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One side of a contract or claim.
class _PartyTile extends StatelessWidget {
  const _PartyTile({
    required this.hand,
    required this.role,
    required this.userId,
    required this.name,
    required this.isAuthor,
    this.signedAt,
  });

  /// "1st hand" / "2nd hand".
  final String hand;

  /// "Lender", "Borrower", "Owner", "Finder".
  final String role;
  final String userId;
  final String name;
  final bool isAuthor;
  final DateTime? signedAt;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.isDark ? p.page : p.page.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.cardBorder),
      ),
      child: Row(
        children: [
          UserAvatar(
            userId: userId,
            name: name,
            radius: 18,
            backgroundColor: p.softGreen,
            foregroundColor: p.softGreenText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$hand · $role',
                  style: AdminText.label(p.primary, size: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty ? 'Unknown' : name,
                  style: AdminText.title(p, size: 14),
                ),
                if (signedAt != null)
                  Text(
                    'Signed ${_dateTime(signedAt!)}',
                    style: AdminText.body(p, size: 11.5),
                  ),
              ],
            ),
          ),
          if (isAuthor) AdminPill.blue(context, 'Post author'),
        ],
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(post.authorId)
          .snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data() ?? const <String, dynamic>{};
        final status = d['verificationStatus'] as String?;
        final email = d['email'] as String?;
        final banned = d['isBanned'] == true;
        return _Section(
          title: 'Posted by',
          trailing: banned
              ? AdminPill.red(context, 'Banned')
              : status == 'verified'
                  ? AdminPill.green(context, 'Verified')
                  : AdminPill.grey(context, 'Not verified'),
          rows: [
            ('Name', post.authorName.isEmpty ? 'Unknown' : post.authorName),
            if (email != null && email.isNotEmpty) ('Email', email),
            ('User ID', post.authorId),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Lend / borrow contracts
// ---------------------------------------------------------------------------

class _ContractsSection extends StatelessWidget {
  const _ContractsSection({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return StreamBuilder<List<LendBorrowContract>>(
      stream: context
          .read<LendBorrowContractService>()
          .watchContractsForPostAdmin(post.id),
      builder: (context, snap) {
        final items = snap.data ?? const <LendBorrowContract>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Contracts', style: AdminText.title(p, size: 17)),
            const SizedBox(height: 4),
            Text(
              '1st hand is the lender (gives the item), 2nd hand is the '
              'borrower (receives it).',
              style: AdminText.body(p, size: 12),
            ),
            const SizedBox(height: 10),
            if (snap.hasError)
              Text('Could not load contracts: ${snap.error}',
                  style: AdminText.body(p))
            else if (!snap.hasData)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              Text('No contracts on this post yet.', style: AdminText.body(p))
            else
              for (final c in items) _ContractCard(contract: c, post: post),
          ],
        );
      },
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract, required this.post});

  final LendBorrowContract contract;
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final c = contract;
    final pill = switch (c.status) {
      ContractStatus.completed => AdminPill.green(context, c.status.label),
      ContractStatus.cancelled => AdminPill.red(context, c.status.label),
      _ => AdminPill.amber(context, c.status.label),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: p.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.createdAt == null
                      ? 'Contract'
                      : 'Contract · ${adminDate(c.createdAt!)}',
                  style: AdminText.title(p, size: 14),
                ),
              ),
              Flexible(child: pill),
            ],
          ),
          const SizedBox(height: 10),
          _PartyTile(
            hand: '1st hand',
            role: 'Lender',
            userId: c.lenderId,
            name: c.lenderName,
            isAuthor: c.lenderId == post.authorId,
            signedAt: c.lenderSignedAt,
          ),
          _PartyTile(
            hand: '2nd hand',
            role: 'Borrower',
            userId: c.borrowerId,
            name: c.borrowerName,
            isAuthor: c.borrowerId == post.authorId,
            signedAt: c.borrowerSignedAt,
          ),
          const SizedBox(height: 4),
          if (c.itemCondition?.isNotEmpty == true)
            _InfoRow(label: 'Item condition', value: c.itemCondition!),
          if (c.handshakeAt != null)
            _InfoRow(label: 'Handshake', value: _dateTime(c.handshakeAt!)),
          if (c.handshakeAddress?.isNotEmpty == true)
            _InfoRow(label: 'Handshake place', value: c.handshakeAddress!),
          if (c.completedAt != null)
            _InfoRow(label: 'Completed', value: _dateTime(c.completedAt!)),
          _InfoRow(label: 'Contract ID', value: c.id),
          if (c.termsText.trim().isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 10),
                title: Text('Agreement terms', style: AdminText.title(p, size: 13)),
                children: [
                  SelectableText(
                    c.termsText,
                    style: AdminText.body(p, size: 12.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lost / found claims
// ---------------------------------------------------------------------------

class _ClaimsSection extends StatelessWidget {
  const _ClaimsSection({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return StreamBuilder<List<LostFoundClaim>>(
      stream: context.read<LostFoundClaimService>().watchClaimsForPostAdmin(post.id),
      builder: (context, snap) {
        final items = snap.data ?? const <LostFoundClaim>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Claims', style: AdminText.title(p, size: 17)),
            const SizedBox(height: 4),
            Text(
              '1st hand is the finder (has the item), 2nd hand is the owner '
              '(gets it back).',
              style: AdminText.body(p, size: 12),
            ),
            const SizedBox(height: 10),
            if (snap.hasError)
              Text('Could not load claims: ${snap.error}',
                  style: AdminText.body(p))
            else if (!snap.hasData)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              Text('No claims on this post yet.', style: AdminText.body(p))
            else
              for (final c in items) _ClaimCard(claim: c, post: post),
          ],
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, required this.post});

  final LostFoundClaim claim;
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final c = claim;
    final pill = switch (c.status) {
      ClaimStatus.completed => AdminPill.green(context, c.status.label),
      ClaimStatus.cancelled => AdminPill.red(context, c.status.label),
      _ => AdminPill.amber(context, c.status.label),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: p.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.createdAt == null
                      ? 'Claim'
                      : 'Claim · ${adminDate(c.createdAt!)}',
                  style: AdminText.title(p, size: 14),
                ),
              ),
              Flexible(child: pill),
            ],
          ),
          const SizedBox(height: 10),
          _PartyTile(
            hand: '1st hand',
            role: 'Finder',
            userId: c.finderId,
            name: c.finderName,
            isAuthor: c.finderId == post.authorId,
          ),
          _PartyTile(
            hand: '2nd hand',
            role: 'Owner',
            userId: c.ownerId,
            name: c.ownerName,
            isAuthor: c.ownerId == post.authorId,
          ),
          const SizedBox(height: 4),
          if (c.summaryText?.trim().isNotEmpty == true)
            _InfoRow(label: 'Claim details', value: c.summaryText!.trim()),
          if (c.handshakeAt != null)
            _InfoRow(label: 'Handover', value: _dateTime(c.handshakeAt!)),
          if (c.handshakeAddress?.isNotEmpty == true)
            _InfoRow(label: 'Handover place', value: c.handshakeAddress!),
          if (c.completedAt != null)
            _InfoRow(label: 'Completed', value: _dateTime(c.completedAt!)),
          _InfoRow(label: 'Claim ID', value: c.id),
        ],
      ),
    );
  }
}
