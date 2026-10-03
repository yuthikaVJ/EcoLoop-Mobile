import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/seller_name.dart';
import '../../materials_marketplace/presentation/pages/chat_page.dart';
import '../../materials_marketplace/presentation/providers/material_listings_provider.dart';
import '../domain/match_suggestion.dart';
import 'matches_providers.dart';

/// AI-suggested matches between my posts and other users' opposite posts.
/// The AI only suggests: nothing happens until the user taps Connect.
class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(myMatchesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Matches', style: TextStyle(fontWeight: FontWeight.bold))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myMatchActivityProvider);
          ref.invalidate(myMatchesProvider);
          await ref.read(myMatchesProvider.future);
        },
        child: matches.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Message(
            icon: Icons.cloud_off,
            title: 'Could not load matches',
            body: error is ApiException && error.statusCode == 404
                ? 'The EcoLoop server does not have AI matching yet. Restart the backend with the latest code.'
                : error is ApiException
                    ? error.message
                    : 'Check your connection to the EcoLoop server.',
            action: TextButton(onPressed: () => ref.invalidate(myMatchesProvider), child: const Text('Retry')),
          ),
          data: (items) {
            // One group per post of mine, best match first (items arrive sorted by score).
            final groups = <String, List<MatchSuggestion>>{};
            for (final match in items) {
              groups.putIfAbsent(match.myListing.id, () => []).add(match);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (items.isEmpty)
                  const _EmptyMatches()
                else ...[
                  const _Disclaimer(),
                  for (final group in groups.values) ...[
                    _PostHeader(listing: group.first.myListing, count: group.length),
                    for (final match in group) _MatchCard(match: match),
                  ],
                ],
                // Posts that already have matches are shown above, not repeated here.
                _MyPostsActivity(shownListingIds: groups.keys.toSet()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.mintGreen, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.forestGreen, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Suggested by EcoLoop AI. Check the details - nothing happens until you choose Connect.',
                style: TextStyle(fontSize: 13, color: AppColors.darkCharcoal),
              ),
            ),
          ],
        ),
      );
}

class _MatchCard extends ConsumerStatefulWidget {
  final MatchSuggestion match;

  const _MatchCard({required this.match});

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard> {
  bool _busy = false;

  MatchSuggestion get m => widget.match;

  Future<void> _connect() async {
    final other = m.otherListing;
    if (!m.isConnected) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connect?'),
          content: Text(
            'EcoLoop will send ${other.seller ?? 'the other user'} a message introducing your post '
            '"${m.myListing.title}" and open the chat.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Connect')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      final chat = await ref.read(matchesRepositoryProvider).connect(m.id);
      final listing = await ref.read(materialListingRepositoryProvider).getListingById(chat.listingId);
      if (!mounted) return;
      ref.invalidate(myMatchesProvider);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(listing: listing, receiverId: chat.otherBusinessId, partnerName: other.seller),
        ),
      );
    } catch (error) {
      _snack('Could not connect: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _busy = true);
    try {
      await ref.read(matchesRepositoryProvider).dismiss(m.id);
      ref.invalidate(myMatchesProvider);
      _snack("Got it - we won't suggest this match again.");
    } catch (error) {
      _snack('Could not update the match: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final other = m.otherListing;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.mintGreen, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Pill(text: other.typeLabel, color: other.isIHave ? AppColors.forestGreen : const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                if (m.isConnected) const _Pill(text: 'Connected', color: verifiedBlue),
                const Spacer(),
                _ScoreBadge(percent: m.scorePercent),
              ],
            ),
            const SizedBox(height: 10),
            Text(other.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              [other.amount, other.location].where((s) => s.isNotEmpty).join(' · '),
              style: const TextStyle(color: AppColors.slateGray, fontSize: 13),
            ),
            const SizedBox(height: 6),
            SellerName(
              name: other.seller,
              verified: other.sellerIsVerified,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Divider(height: 22),
            const Text('Why', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final reason in m.reasons) _Line(icon: Icons.check_circle, color: AppColors.ecoGreen, text: reason),
            if (m.warnings.isNotEmpty) ...[
              const SizedBox(height: 6),
              for (final warning in m.warnings)
                _Line(icon: Icons.info_outline, color: const Color(0xFF856404), text: warning),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!m.isConnected)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _dismiss,
                      child: const Text('Not interested'),
                    ),
                  ),
                if (!m.isConnected) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _connect,
                    icon: _busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(m.isConnected ? Icons.chat_bubble_outline : Icons.handshake_outlined),
                    label: Text(m.isConnected ? 'Open chat' : 'Connect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int percent;

  const _ScoreBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80 ? AppColors.forestGreen : const Color(0xFF856404);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text('$percent% match', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      );
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Line({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3))),
          ],
        ),
      );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Message({required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) => ListView(
        // Scrollable so pull-to-refresh works on empty and error states too.
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(icon, size: 56, color: AppColors.ecoGreen),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slateGray, height: 1.4)),
          if (action != null) Center(child: action),
        ],
      );
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, size: 48, color: AppColors.ecoGreen),
            SizedBox(height: 10),
            Text('No matches yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(
              'EcoLoop AI compares your posts with posts from other users: your I HAVE posts with '
              'their I NEED posts, and the other way round. Your own posts are never matched '
              'with each other.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slateGray, height: 1.4),
            ),
          ],
        ),
      );
}

/// Why each of my posts has (no) matches, with a way to check again. Refreshes
/// itself while a check is running.
class _MyPostsActivity extends ConsumerStatefulWidget {
  /// My posts whose matches are already listed above.
  final Set<String> shownListingIds;

  const _MyPostsActivity({required this.shownListingIds});

  @override
  ConsumerState<_MyPostsActivity> createState() => _MyPostsActivityState();
}

class _MyPostsActivityState extends ConsumerState<_MyPostsActivity> {
  Timer? _poll;
  final Set<String> _starting = {};

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _pollWhileChecking(List<MatchActivity> items) {
    final checking = items.any((a) => a.isChecking);
    if (checking && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => ref.invalidate(myMatchActivityProvider));
    } else if (!checking && _poll != null) {
      _poll!.cancel();
      _poll = null;
      ref.invalidate(myMatchesProvider); // a finished check may have found matches
    }
  }

  Future<void> _checkAgain(MatchActivity post) async {
    setState(() => _starting.add(post.listingId));
    try {
      await ref.read(matchesRepositoryProvider).findMatches(post.listingId);
      ref.invalidate(myMatchActivityProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start a check: $error')));
      }
    } finally {
      if (mounted) setState(() => _starting.remove(post.listingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(myMatchActivityProvider);
    final items = activity.value;
    if (items != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pollWhileChecking(items);
      });
    }
    final others = items?.where((a) => !widget.shownListingIds.contains(a.listingId)).toList() ?? const [];
    if (others.isEmpty) return const SizedBox.shrink();
    final hasMatches = widget.shownListingIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          hasMatches ? 'Your other posts' : 'Your posts',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          hasMatches ? 'No matches for these yet.' : 'What EcoLoop AI found for each of your active posts.',
          style: const TextStyle(color: AppColors.slateGray, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final post in others)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${post.isIHave ? 'I HAVE' : 'I NEED'} · ${post.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(post: post),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      _describe(post),
                      style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.darkCharcoal),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: post.isChecking || _starting.contains(post.listingId)
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : TextButton.icon(
                            onPressed: () => _checkAgain(post),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: Text(post.state == null ? 'Find matches' : 'Check again'),
                          ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _describe(MatchActivity post) {
    if (post.state == null) return 'This post has not been checked yet.';
    if (post.isChecking) return "EcoLoop AI is comparing this post with other users' posts. This takes about a minute.";
    if (post.outcome == 'MATCHES') {
      return '${post.suggestionCount} potential match${post.suggestionCount == 1 ? '' : 'es'} - see above.';
    }
    if (post.outcome == 'FAILED') {
      return post.reason ?? 'The AI service could not finish this check. Try again later.';
    }
    return post.reason ?? 'No reliable match found right now.';
  }
}

/// The result of the latest check, in words (no ambiguous icons).
class _StatusChip extends StatelessWidget {
  final MatchActivity post;

  const _StatusChip({required this.post});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (post) {
      MatchActivity(state: null) => ('Not checked yet', AppColors.slateGray),
      MatchActivity(isChecking: true) => ('Checking...', const Color(0xFF1565C0)),
      MatchActivity(outcome: 'MATCHES') => ('Match found', AppColors.forestGreen),
      MatchActivity(outcome: 'NEEDS_INFO') => ('Needs more info', const Color(0xFF856404)),
      MatchActivity(outcome: 'FAILED') => ('Check failed', AppColors.errorRed),
      _ => ('No match yet', AppColors.slateGray),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}

/// "For your I NEED post: Old Gpu" above that post's match cards.
class _PostHeader extends StatelessWidget {
  final MatchListing listing;
  final int count;

  const _PostHeader({required this.listing, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
        child: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right, size: 18, color: AppColors.slateGray),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'For your ${listing.typeLabel} post: ',
                  style: const TextStyle(color: AppColors.slateGray, fontSize: 13),
                  children: [
                    TextSpan(
                      text: listing.title,
                      style: const TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count match${count == 1 ? '' : 'es'}',
              style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      );
}
