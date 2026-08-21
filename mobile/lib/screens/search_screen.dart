import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';
import '../models/place_filters.dart';
import '../providers/place_provider.dart';
import '../theme/app_colors.dart';
import '../theme/place_category_icon.dart';
import 'filters_screen.dart';
import 'place_detail_screen.dart';

const _maxRecentQueries = 6;

/// A dedicated full-screen search page (opened from ExploreScreen's search
/// bar) — session-only "Recent" queries above an always-visible "Nearby"
/// grid that narrows down as the user types.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  PlaceFilters _filters = const PlaceFilters();
  final List<String> _recentQueries = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentQueries.remove(trimmed);
      _recentQueries.insert(0, trimmed);
      if (_recentQueries.length > _maxRecentQueries) {
        _recentQueries.removeLast();
      }
    });
  }

  void _selectRecent(String query) {
    _controller.text = query;
    setState(() => _query = query.toLowerCase());
  }

  Future<void> _openFilters() async {
    final result = await FiltersScreen.show(context, _filters);
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(nearbyPlacesProvider);
    final allPlaces = placesAsync.value ?? const <Place>[];
    final matched = _query.isEmpty
        ? allPlaces
        : allPlaces
              .where(
                (place) =>
                    place.name.toLowerCase().contains(_query) ||
                    place.category.name.toLowerCase().contains(_query),
              )
              .toList();
    final places = _filters.apply(matched);

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_query.isEmpty && _recentQueries.isNotEmpty) ...[
                      _buildRecentHeader(context),
                      const SizedBox(height: 12),
                      for (final query in _recentQueries)
                        _RecentQueryRow(
                          query: query,
                          onTap: () => _selectRecent(query),
                        ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      _query.isEmpty ? 'Nearby' : 'Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (placesAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.orange),
                        ),
                      )
                    else if (places.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Nothing found',
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: places.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                        itemBuilder: (context, index) {
                          final place = places[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlaceDetailScreen(place: place),
                                ),
                              );
                            },
                            child: _SearchPlaceCard(place: place),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Recent',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText(context),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(_recentQueries.clear),
          child: const Text(
            'Clear',
            style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: AppColors.darkText(context)),
          ),
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.mutedText(context), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                      onSubmitted: _submit,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: AppColors.darkText(context), fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search places, people...',
                        hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 14),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      child: Icon(Icons.close, color: AppColors.mutedText(context), size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openFilters,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder(context)),
              ),
              child: Icon(Icons.tune, color: AppColors.darkText(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentQueryRow extends StatelessWidget {
  const _RecentQueryRow({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.history, color: AppColors.mutedText(context), size: 18),
            const SizedBox(width: 12),
            Text(
              query,
              style: TextStyle(fontSize: 14, color: AppColors.darkText(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPlaceCard extends StatelessWidget {
  const _SearchPlaceCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = place.distanceLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              placeCategoryIcon(place.category.name),
              color: AppColors.orange,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          place.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText(context),
          ),
        ),
        Text(
          place.category.name,
          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
        ),
        if (distanceLabel != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.mutedText(context), size: 12),
              const SizedBox(width: 2),
              Text(
                distanceLabel,
                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
