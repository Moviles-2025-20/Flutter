class EventFilters {
  final String? searchQuery;
  final List<String>? eventTypes; // ["Conference", "Seminar", "Workshop"]
  final String? category;
  final double? minRating;
  final bool? weatherDependent;
  final String? city;

  EventFilters({
    this.searchQuery,
    this.eventTypes,
    this.category,
    this.minRating,
    this.weatherDependent,
    this.city,
  });

  EventFilters copyWith({
    String? searchQuery,
    List<String>? eventTypes,
    String? category,
    double? minRating,
    bool? weatherDependent,
    String? city,
  }) {
    print(category);
    return EventFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      eventTypes: eventTypes ?? this.eventTypes,
      category: category ?? this.category,
      minRating: minRating ?? this.minRating,
      weatherDependent: weatherDependent ?? this.weatherDependent,
      city: city ?? this.city,
    );
  }

  bool get hasActiveFilters =>
      (searchQuery?.isNotEmpty ?? false) ||
      (eventTypes?.isNotEmpty ?? false) ||
      category != null ||
      minRating != null ||
      weatherDependent != null ||
      city != null;
}