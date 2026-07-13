import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../posts/services/post_service.dart';
import '../models/meetup_suggestion.dart';
import '../services/meetup_suggestion_service.dart';
import 'meetup_suggestions_widget.dart';

/// Read-only meetup tips for contract/claim handoff screens.
class PostMeetupTipsSection extends StatelessWidget {
  const PostMeetupTipsSection({
    super.key,
    required this.postId,
    this.locationFallback,
  });

  final String postId;
  final String? locationFallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(context),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const MeetupSuggestionsWidget(
            suggestions: [],
            loading: true,
          );
        }
        return MeetupSuggestionsWidget(
          suggestions: snap.data ?? const [],
        );
      },
    );
  }

  Future<List<MeetupSuggestion>> _load(BuildContext context) async {
    final post = await context.read<PostService>().getPost(postId);
    if (post != null) {
      return MeetupSuggestionService.suggestionsForPost(post);
    }
    return MeetupSuggestionService.suggestionsFromCoordinates(
      locationLabel: locationFallback,
    );
  }
}
