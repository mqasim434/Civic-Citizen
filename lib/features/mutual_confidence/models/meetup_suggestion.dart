/// A suggested safe meetup point for in-person handoffs.
class MeetupSuggestion {
  const MeetupSuggestion({
    required this.label,
    required this.description,
    this.latitude,
    this.longitude,
  });

  final String label;
  final String description;
  final double? latitude;
  final double? longitude;
}
