import 'package:flutter/material.dart';

import '../models/place_filters.dart';
import '../theme/app_colors.dart';

const _categories = ['Cafe', 'Restaurant', 'Park', 'Museum', 'Sports', 'Nightlife'];
const _distancePresetsKm = [1.0, 2.0, 5.0, 10.0];

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, this.initialFilters = const PlaceFilters()});

  final PlaceFilters initialFilters;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late Set<String> _selectedCategories;
  late double? _maxDistanceKm;
  late PlaceSortOrder _sort;

  @override
  void initState() {
    super.initState();
    _selectedCategories = {...widget.initialFilters.categories};
    _maxDistanceKm = widget.initialFilters.maxDistanceKm;
    _sort = widget.initialFilters.sort;
  }

  void _reset() {
    setState(() {
      _selectedCategories = {};
      _maxDistanceKm = null;
      _sort = PlaceSortOrder.nearest;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      PlaceFilters(
        categories: _selectedCategories,
        maxDistanceKm: _maxDistanceKm,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Distance'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _distancePresetsKm.map((km) {
                        final selected = _maxDistanceKm == km;
                        return _FilterChip(
                          label: km >= 1
                              ? '${km.toStringAsFixed(0)} km'
                              : '${(km * 1000).toStringAsFixed(0)} m',
                          selected: selected,
                          onTap: () => setState(
                            () => _maxDistanceKm = selected ? null : km,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    _sectionTitle(context, 'Category'),
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
                    const SizedBox(height: 28),
                    _sectionTitle(context, 'Sort'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterChip(
                          label: 'Nearest',
                          selected: _sort == PlaceSortOrder.nearest,
                          onTap: () =>
                              setState(() => _sort = PlaceSortOrder.nearest),
                        ),
                        _FilterChip(
                          label: 'Name (A–Z)',
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
                        child: Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
              'Filters',
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
              'Reset',
              style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText(context),
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
          border: selected ? null : Border.all(color: AppColors.fieldBorder(context)),
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
