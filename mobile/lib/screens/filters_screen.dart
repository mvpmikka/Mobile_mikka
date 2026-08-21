import 'package:flutter/material.dart';

import '../models/place_filters.dart';
import '../theme/app_colors.dart';

const _categories = ['Cafe', 'Restaurant', 'Park', 'Museum', 'Sports', 'Nightlife'];

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, this.initialFilters = const PlaceFilters()});

  final PlaceFilters initialFilters;

  /// Presents the filters as a rounded bottom sheet over the current screen.
  static Future<PlaceFilters?> show(
    BuildContext context,
    PlaceFilters initialFilters,
  ) {
    return showModalBottomSheet<PlaceFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltersScreen(initialFilters: initialFilters),
    );
  }

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  static const _minDistanceKm = 1.0;
  static const _maxDistanceKm = 10.0;

  late Set<String> _selectedCategories;
  late double _distanceKm;
  late PlaceSortOrder _sort;

  @override
  void initState() {
    super.initState();
    _selectedCategories = {...widget.initialFilters.categories};
    _distanceKm = widget.initialFilters.maxDistanceKm ?? _maxDistanceKm;
    _sort = widget.initialFilters.sort;
  }

  void _reset() {
    setState(() {
      _selectedCategories = {};
      _distanceKm = _maxDistanceKm;
      _sort = PlaceSortOrder.nearest;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      PlaceFilters(
        categories: _selectedCategories,
        maxDistanceKm: _distanceKm >= _maxDistanceKm ? null : _distanceKm,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: AppColors.cream(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fieldBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'MASOFA', trailing: '${_distanceKm.toStringAsFixed(0)} km gacha'),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.orange,
                        inactiveTrackColor: AppColors.fieldBorder(context),
                        thumbColor: AppColors.orange,
                        overlayColor: AppColors.orange.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _distanceKm,
                        min: _minDistanceKm,
                        max: _maxDistanceKm,
                        divisions: (_maxDistanceKm - _minDistanceKm).toInt(),
                        onChanged: (value) => setState(() => _distanceKm = value),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_minDistanceKm.toStringAsFixed(0)} km',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                          ),
                          Text(
                            '${_maxDistanceKm.toStringAsFixed(0)} km',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'TOIFA'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories.map((category) {
                        final selected = _selectedCategories.contains(category);
                        return _FilterChip(
                          label: category,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedCategories.remove(category);
                              } else {
                                _selectedCategories.add(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'SARALASH'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterChip(
                          label: 'Yaqinlari',
                          selected: _sort == PlaceSortOrder.nearest,
                          onTap: () =>
                              setState(() => _sort = PlaceSortOrder.nearest),
                        ),
                        _FilterChip(
                          label: 'Nomi (A–Z)',
                          selected: _sort == PlaceSortOrder.nameAsc,
                          onTap: () =>
                              setState(() => _sort = PlaceSortOrder.nameAsc),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, Color(0xFFF2A25C)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: _apply,
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'FILTRLARNI QO\'LLASH',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.tune, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: AppColors.darkText(context)),
          ),
          Expanded(
            child: Text(
              'Filtrlar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText(context),
              ),
            ),
          ),
          TextButton(
            onPressed: _reset,
            child: const Text(
              'Tozalash',
              style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.mutedText(context),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.mutedText(context),
          ),
        ),
      ),
    );
  }
}
