/// One choice in an admin broadcast poll.
class AnnouncementPollOption {
  const AnnouncementPollOption({
    required this.id,
    required this.text,
  });

  factory AnnouncementPollOption.fromMap(Map<String, dynamic> map) {
    return AnnouncementPollOption(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
    );
  }

  final String id;
  final String text;

  Map<String, dynamic> toMap() => {'id': id, 'text': text};
}

/// Aggregated helpful feedback and poll votes for one broadcast.
class AnnouncementAudienceStats {
  const AnnouncementAudienceStats({
    this.totalResponses = 0,
    this.helpfulYes = 0,
    this.helpfulNo = 0,
    this.pollVotesByOptionId = const {},
  });

  final int totalResponses;
  final int helpfulYes;
  final int helpfulNo;
  final Map<String, int> pollVotesByOptionId;

  int get totalPollVotes =>
      pollVotesByOptionId.values.fold(0, (sum, n) => sum + n);
}
