import 'package:flutter/material.dart';

/// Places have no real photo data in the backend, so screens show a
/// category icon instead of a fake image/color placeholder.
IconData placeCategoryIcon(String categoryName) {
  final name = categoryName.toLowerCase();
  if (name.contains('cafe') || name.contains('coffee')) {
    return Icons.local_cafe_outlined;
  }
  if (name.contains('restaurant') || name.contains('food')) {
    return Icons.restaurant_outlined;
  }
  if (name.contains('park') || name.contains('nature')) {
    return Icons.park_outlined;
  }
  if (name.contains('museum') || name.contains('gallery') || name.contains('art')) {
    return Icons.museum_outlined;
  }
  if (name.contains('sport') || name.contains('gym')) {
    return Icons.sports_soccer_outlined;
  }
  if (name.contains('shop') || name.contains('mall') || name.contains('market')) {
    return Icons.storefront_outlined;
  }
  return Icons.place_outlined;
}
