import 'package:flutter/material.dart';

class PlaceSummary {
  const PlaceSummary({
    required this.name,
    required this.category,
    required this.distance,
    required this.rating,
    required this.color,
    this.reviewCount = 0,
    this.openHours = '',
    this.description = '',
  });

  final String name;
  final String category;
  final String distance;
  final double rating;
  final Color color;
  final int reviewCount;
  final String openHours;
  final String description;
}

const kNearbyPlaces = [
  PlaceSummary(
    name: 'Central Park',
    category: 'Park',
    distance: '250 m',
    rating: 4.8,
    color: Color(0xFF3E6B5C),
  ),
  PlaceSummary(
    name: 'Coffee 21',
    category: 'Cafe',
    distance: '300 m',
    rating: 4.6,
    color: Color(0xFF6B4A38),
    reviewCount: 128,
    openHours: '8:00 – 22:00',
    description: 'Cozy place with great coffee and nice atmosphere.',
  ),
  PlaceSummary(
    name: 'Art Gallery',
    category: 'Museum',
    distance: '450 m',
    rating: 4.7,
    color: Color(0xFF4A5A8A),
  ),
  PlaceSummary(
    name: 'Play Ground',
    category: 'Sports',
    distance: '600 m',
    rating: 4.5,
    color: Color(0xFF4F8A5C),
  ),
  PlaceSummary(
    name: 'Sakura Sushi',
    category: 'Restaurant',
    distance: '700 m',
    rating: 4.6,
    color: Color(0xFFCB4B4B),
  ),
];
