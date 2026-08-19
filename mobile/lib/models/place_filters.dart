import 'place.dart';

enum PlaceSortOrder { nearest, nameAsc }

/// Filter + sort criteria produced by [FiltersScreen] and consumed by
/// ExploreScreen/NearbyPlacesScreen/SearchScreen — kept in one place so all
/// three apply the same rules to a [Place] list.
class PlaceFilters {
  const PlaceFilters({
    this.categories = const {},
    this.maxDistanceKm,
    this.sort = PlaceSortOrder.nearest,
  });

  /// Empty means every category passes.
  final Set<String> categories;

  /// Null means no distance cutoff.
  final double? maxDistanceKm;

  final PlaceSortOrder sort;

  bool get isDefault =>
      categories.isEmpty && maxDistanceKm == null && sort == PlaceSortOrder.nearest;

  List<Place> apply(List<Place> places) {
    var result = places.where((place) {
      if (categories.isNotEmpty && !categories.contains(place.category.name)) {
        return false;
      }
      final maxKm = maxDistanceKm;
      if (maxKm != null && place.distanceMeters != null) {
        if (place.distanceMeters! > maxKm * 1000) return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case PlaceSortOrder.nearest:
        result.sort(
          (a, b) => (a.distanceMeters ?? double.infinity).compareTo(
            b.distanceMeters ?? double.infinity,
          ),
        );
      case PlaceSortOrder.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  PlaceFilters copyWith({
    Set<String>? categories,
    double? Function()? maxDistanceKm,
    PlaceSortOrder? sort,
  }) {
    return PlaceFilters(
      categories: categories ?? this.categories,
      maxDistanceKm: maxDistanceKm != null ? maxDistanceKm() : this.maxDistanceKm,
      sort: sort ?? this.sort,
    );
  }
}
